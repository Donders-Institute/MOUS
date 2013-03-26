% mous_corrmnebf_pipeline
% trial == a single word (not averaged across word position)
% 
% This function source level analysis for ERFs and TFRs and then correlates
% their activity together.
% 
% (1) ERFs done using Minimum Norm Estimate 
% (2) TFRs done using Beamforming.
% the trials are matched between ERFs sand TFRs
% currently (11-2-2013) the trials used for baselining ERFs are only chosen from trials which 
% contain the time window of interest. Theoretically,however, we could
% profit from using all available trials because much of the baseline is
% removed in artifact detection as many participant blink during fixation
% cross (before first word onset).
% 
% The source level outcomes:
% ERF: vertices by trials (cov;  TFR: voxels by trials (3D grid)
% A covariance matrix is created by correlation 
% It creates a matrix:  N-vertices by M-number of trial for each subject 
% - Although averaged across subjects, the MNE is calculate for each subject
%   in order to account for differences in noise matrix covariance and variance in the head model.
% - Here each trial represents a word, and a particular time interval of
%   interested can be selected for that word e.g., 250 - 500ms
% the next step: to average the vertices*trial matrix across subjects

%   
% list ={'V1004'  'V1005'    'V1007'    'V1010'   'V1011'    'V1012' ...
%        'V1013'  'V1015'    'V1016'    'V1017'   'V1019'    'V1020'    'V1021'    ...
%        'V1024'  'V1025'    'V1026'    'V1027'   'V1028'    'V1029'    'V1030'    'V1031'    'V1032' ...
%        'V1033'  'V1034'    'V1036'   'V1037'    'V1039'     ...
%        'V1044'  'V1045'    'V1046'    'V1049'   'V1050'    'V1052'    'V1066'    'V1067'    'V1068' ...
%        'V1079'};

% Always exclude V1014 V1018 V1041 V1043 V1047 V1051 V1056 V1060 V1082 V1091

mous_db_makesubjdir(subjectname)

doerf   = false;
domatch = false;
dotlck  = false;
domne   = false;
dobeam  = false;
docor   = true;
dogrpavg = false;

if doerf
% select toi, include baseline 

    mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); % 360 samples for full trials

    cfg = [];
    cfg.latency = [-0.2 0.6];  % select trials such that those used for baseline == those used for analyses
    data = ft_selectdata(cfg,data);       % altho, we could probably use as many as possible trials for baseline.
    nsmp  = cellfun('size',data.trial,2); % 0.7*300 = 240; data.trial{k}(end) = 0.5967
    smpfull = find(nsmp == 240);          % V1004: data.time{k}(1) == -0.1967 (not -0.2 like others) 
    data = ft_selectdata(data,'rpt',smpfull); % only complete trials (i.e. no shortening due to artifact removal)


% baseline ERFs manually
    all = size(data.trial,2);
    bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
    bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)

    % redefine toi for erf analyses to exclude baseline section 
    cfg = [];
    cfg.latency = [0.2 0.6]; % now 120 samples
    data = ft_selectdata(cfg,data); 

    % compute baseline normalization for each trial
    rows = 1; columns = size(data.trial{1},2);  % matrix dim for each trial
    bslrep = repmat(bslavgVec, [rows columns]);               % replicate bslvector to fit size of toi trials

    for k = 1:size(data.trial,2)
        data.trial{k} = data.trial{k}-bslrep;     
    end

    mous_db_putdata(subjectname, 'meg_corrmnebf_erfsingletrialbsld_02-06','data');
end

if domatch
% match trials between ERFs and TFRs

    rootdir = '/home/language/jansch/public/mous/';
    suff = '';
    mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);

    erf = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
    tfr = freq.trialinfo(:,1)*1000+freq.trialinfo(:,5);  
    [comm, ierf, itfr] = intersect(erf, tfr);            % common words w/ loi 

    % if TFRs trials == ERFs, then the following 2 lines are redundant, but that is okay.
    freq = ft_selectdata(freq,'rpt',itfr);
    data = ft_selectdata(data,'rpt',ierf);  

    mous_db_putdata(subjectname, 'meg_corrmnebf_erfsingletrialbsld_02-06', 'data');
    mous_db_putdata(subjectname, 'meg_corrmnebf_tfrsingletrial_02-06', 'freq');
end


if dotlck
    % Time Locking & Covariance matrix
    % compute covariance matrix of the noise
    mous_db_getdata(subjectname, 'meg_corrmnebf_erfsingletrialbsld_02-06');
    mous_db_getdata(subjectname, 'meg_corrmnebf_tfrsingletrial_02-06');
    
    cfg              = [];
    cfg.vartrllength = 2;
    cfg.feedback     = 'textbar';
    cfg.covariance   = 'yes';
    cfg.covariancewindow = [-inf 1]; % calculate the covariance matrix for timepoints before the zero-time point (onset of word) 
    cfg.preproc.demean = 'yes';
    cfg.channel        = {'MEG', '-EEG057', '-EEG058'};
    cfg.preproc.baselinewindow = [-inf 0];
    tlck = ft_timelockanalysis(cfg, data);  % actual timelocked data is not used, we only need sensor positions and the noise cov. matrix
end

if domne
% models
    sourcemodel = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  
    if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
        sourcemodel.pos  = sourcemodel.pnt;
        sourcemodel      = rmfield(sourcemodel, 'pnt');
    end
    sourcemodel.inside = (1:8196);
    sourcemodel.outside = [];

    mous_db_getdata(subjectname,  'meg_anatomy_headmodel'); 

% Compute the leadfields
    % Forward solution  
    cfg             = [];
    cfg.grad        = tlck.grad;  % sensor positions
    cfg.vol         = vol;
    cfg.grid        = sourcemodel;
    cfg.channel     = {'MEG', '-EEG057', '-EEG058'};
    cfg.feedback    = 'textbar';
    sourcemodel     = ft_prepare_leadfield(cfg);  
    % sourcemodel.leadfield is {1 x 8196 vertices}, each vertex holds [273 channel x 3 orientation]

    % calculate sources
    cfg                     = [];
    cfg.channel             = {'MEG', '-EEG057', '-EEG058'};
    cfg.method              = 'mne';
    cfg.vol                 = vol;
    cfg.grid                = sourcemodel;
    cfg.mne.prewhiten       = 'yes';
    cfg.mne.lambda          = 3; % used to be 2
    cfg.mne.scalesourcecov  = 'yes';
    cfg.mne.keepfilter      = 'yes';
    source                  = ft_sourceanalysis(cfg, tlck);  % noise covariance matrix used here

    cfg            = [];
    cfg.demean     = 'yes';
    cfg.projectmom = 'yes';
    cfg.zscore     = 'no';
    sd             = ft_sourcedescriptives(cfg, source);

    % sd gives description of sources:
    % sd.avg.ori == 3 vectors (x,y,z) describing location of vector (that moves over time)
    % sd.avg.filter == how to weigh sensor level data (all channels) to project to source level
    % sd.pos == [8196 x 3], what does "3" stand for?

% create the vertex x channel spatial filter matrix
    mnefilter = zeros(size(sd.pos,1), size(sourcemodel.leadfield{1},1));  % 8196 x 273
    % calc filter for each vertex 
    % one filter for each channel: project sensor lvl data to source lvl (each vertex)
    for k = 1:size(mnefilter,1)
        mnefilter(k,:) = sd.avg.ori{k}*sd.avg.filter{k}; 
    end
    
    % apply filter to data; output is amplitude of trial
    vertM = nan(size(mnefilter,1), numel(data.trial));  
    for k = 1:numel(data.trial)   
        tmp = mnefilter*data.trial{k}(1:273,:);  % [8196*273] * [273 * 120 - timepoints] 
        vertM(:,k) = tmp; 
    end

    % vertex*trial data, trialinfo, MNE filter; source (+noise covariance matrix in source.avg); sd;
    mous_db_putdata(subjectname,'meg_corrmnebf_mnesingletrial_02-06','vertM','mnefilter','source','sd','tlck');

end

if dobeam
    % Beamformer calculation
    % source analysis
    toi = 0.4;
    mous_db_getdata(subjectname, 'meg_corrmnebf_tfrsingletrial_02-06');
    [source, trialinfo] = mous_bfica_source(subjectname, freq, toi, 8);
    % mous_db_putdata(subjectname,'meg_corrmnebf_bfsourcesingletrial_02-06','source','trialinfo');   % 10mm grid
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06','source','trialinfo');

    % sourcedata analysis
    sourcedata = mous_bfica_sourcedata(source, freq, toi);
    % mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcedatasingletrial_02-06','sourcedata');  % 10mm grid
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcedatasingletrial8mm_02-06','sourcedata');  % 8mm

end

if docor
    % Covariance & Correlation Calculation
    mous_db_getdata(subjectname,'meg_corrmnebf_bfsourcedatasingletrial8mm_02-06');
    mous_db_getdata(subjectname,'meg_corrmnebf_mnesingletrial_02-06');
    voxM  = sourcedata.trial{1}; 

    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)
    idxNan = find(isnan(voxM(1,:))); % check first row of each column for NaN (assume that it's entire column with NaN)
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
        vertM(:,idxNan) = [];
    end

    % mean subtraction (centre data)
    voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]);
    vertM = vertM - repmat(mean(vertM,2),[1 size(voxM,2)]);
    
    % variance calculation
    %   Variance of A is defined as the diagonal elements of covariance matrix (A*A'); 
    %   It is inefficient to compute A*A' and then subsequently select only the diagonal elements values
    varVox = sum(voxM.^2,2);  
    varVert = sum(vertM.^2,2); 
    %% cross correlation between TFRs (Vox) and ERFs (Vert)
%     covVoxvert = voxM*vertM';  
%     cor = covVoxvert./sqrt(varVox*varVert'); % remove variance from each element
    
    %% within correlations
    covVoxvox   = voxM*voxM';
    corvox      = covVoxvox./sqrt(varVox*varVox');
    
    covVertvert = vertM*vertM';
    corvert     = covVertvert./sqrt(varVert*varVert');
    
    %% save
    % mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8','cor');  10mm grid - less precise
    % mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8mm','cor');
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvox8mm','corvox');
    mous_db_putdata(subjectname,'meg_corrmnebf_corVertvert8mm','corvert');
end

if dogrpavg
%% group average
    subjectnames =  {'V1004' 'V1005' 'V1007'  ...
                     'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                     'V1020' 'V1021' 'V1022' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029' ...
                     'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1035' 'V1036' 'V1037' 'V1039'...
                     'V1042' 'V1044' 'V1045' 'V1046' 'V1049' ...
                     'V1050' 'V1052' ...
                     'V1066' 'V1067' 'V1068'...
                     'V1072' 'V1078' 'V1079'};
    for q = 1:numel(subjectnames)
        mous_db_getdata(subjectnames{q},'meg_corrmnebf_corrmnebf_corVoxvert8mm')
        if q == 1
            data = cor;
        else 
            data = data + corr;
        end
    end
    dataAvg = data./numel(subjectnames);
end    
        
    

%% Surfaces & saving 

% bndinflated = mous_inflatedmesh(subjectname);
% bnd     = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');
% sd.tri = bnd.tri;
% sd.pos = bnd.pos; % surface
% sd.pos_infl = bndinflated.pos; % inflated 
% 
% % do the normalisation to get a 'dSPM'
% npnt = size(sd.pos,1);
% sd.avg.dspm = spdiags(1./sd.avg.noise,0,npnt,npnt)*sd.avg.pow;

%% Movie visualization
% sd.pos = sd.pos_infl;
% 
% figure
% cfg = [];
% cfg.funparameter = 'avg.dspm'; %avg.pow
% ft_sourcemovie(cfg,sd);


  


