% mous_corrmnebf_pipeline
% trial == a single word (not averaged across word position)
% 
% Perform source level analysis for a certain time window of interest in
% ERFs and TFRs, which are then (partially-)correlated together 

% (1) ERFs done using Minimum Norm Estimate 
% (2) TFRs done using Beamforming.
%     *****If Xmm is not specified, then beamformer was 10mm between voxels (points)*
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

%% Things to define 
% doselxxx, domatch, dobf/mne need to be done in one go because intermediate outputs are NOT saved
% suff:  '' = 20Hz, anything else needs to be specified 

% Always exclude V1014 V1018 V1041 V1043 V1047 V1051 V1056 V1060 V1082 V1091

mous_db_makesubjdir(subjectname)

toie        = [0.05 0.25];  % toi for ERFs
toi         = 0.4;          % toi for frequency analysis

dofreq      = false;  % uses with altered version of JM's script
doselfreq   = true;

doselerf    = true;
domatch     = true;
dotlck      = true;

doleadmne   = true;
doleadbf    = true;

domneavg    = false;
domnesingle = false;
dobeam      = true;   % 
docor_cross = false;
docor_bf    = false;
docor_mne   = false;
dogrpavg    = false;

%docov       = false;

if dofreq
    rootdir = '/home/language/jansch/public/mous/';
    suff = '';
    options = [];
    options.taper = 'hanning';
    options.t_ftimwin = 0.250;
    options.resamplefs = 300;
    frequency = 20;
    [freq,dataStats] = mous_bfica_freq(subjectname, frequency, rootdir, options); % data from mous_corrmnebf_comp is called inside mous_bfica_freq
    mous_db_putdata(subjectname, ['meg_corrmnebf_freq',suff], 'freq','dataStats');
end

if doselfreq
    %% select only sentences and toi
    freq   = ft_struct2double(freq);
    sidx   = find(ismember(freq.trialinfo(:,2),sencdtn));
    freq   = ft_selectdata(freq,'rpt',sidx);
    
    cfg = [];
    cfg.latency = [-0.12 -0.08];  % equivalent of specifying -0.1, but using wider range to circumvent matlab's rounding issue
    freq        = ft_selectdata(cfg,freq); 
    %Go from 4D to 2D: rpttap_chan
    idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
    freq        = ft_selectdata(freq,'rpt',idxful);  
end

if doselerf
    %% select only the sentences and baseline normalise
    mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); % 360 samples for full trials
    sencdtn = [1 2 5 6];
    sentidx     = find(ismember(data.trialinfo(:,2),sencdtn));
    data2       = ft_selectdata(data,'rpt',sentidx);

    % calc baseline
    all = size(data.trial,2);
    bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
    bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)
    
    % normalise
    rows = 1; columns = size(data.trial{1},2);  % matrix dim for each trial
    bslrep = repmat(bslavgVec, [rows columns]); % replicate bslvector to fit size of toi trials

    for k = 1:size(data.trial,2)
        data.trial{k} = data.trial{k}-bslrep;     
    end
end

if domatch
%% match trials between ERFs and TFRs
    % find matching trials
    erf = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
    tfr = freq.trialinfo(:,1)*1000+freq.trialinfo(:,5);  
    [comm, ierf, itfr] = intersect(erf, tfr);    % comm = same trials in both

    % exclude non-matching trials from both datasets
    freq = ft_selectdata(freq,'rpt',itfr);
    data = ft_selectdata(data,'rpt',ierf);  
end

if dotlck
    %% Timelock data and calc covariance matrix
    cfg              = [];
    cfg.vartrllength = 2;
    cfg.feedback     = 'textbar';
    cfg.covariance   = 'yes';
    cfg.covariancewindow = [-inf 1]; % calculate the covariance matrix for timepoints before the zero-time point (onset of word) 
    cfg.preproc.demean = 'yes';
    cfg.channel        = {'MEG', '-EEG057', '-EEG058'};
    cfg.preproc.baselinewindow = [-inf 0];
    tlck = ft_timelockanalysis(cfg, data);  % 
end

if doleadmne  
    %% leadfields for MNE
    % Get  sourcemodel and headmodel
    sourcemodel = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  
    if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
        sourcemodel.pos  = sourcemodel.pnt;
        sourcemodel      = rmfield(sourcemodel, 'pnt');
    end
    sourcemodel.inside = 1:8196; % hard code because coreg not perfect so some subj have sources hovering on border
    sourcemodel.outside = [];
    mous_db_getdata(subjectname,  'meg_anatomy_headmodel'); 
    
    % forward solution   
    % sourcemodel.leadfield is {1 x 8196 vertices}, each vertex holds [273 channel x 3 orientation]
    mous_db_getdata(subjectname,'meg_corrmnebf_gradinfo_02-1');
    cfg             = [];
    cfg.grad        = gradinfo;  % sensor positions
    cfg.vol         = vol;
    cfg.grid        = sourcemodel;
    cfg.channel     = {'MEG', '-EEG057', '-EEG058'};
    cfg.feedback    = 'textbar';
    sourcemodelmne  = ft_prepare_leadfield(cfg);
    mous_db_putdata(subjectname, 'meg_corrmnebf_mnesourcemodel_sent_-02-1s','sourcemodelmne');
end 

if doleadbf   
    %% leadfields for beamformer (not specific to toi/cdtn of interest)
    % Get  sourcemodel and headmodel
    headmodel = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
    sourcemodel = mous_db_getdata(subjectname, ['meg_anatomy_sourcemodel3D_nonlin','8mm']);

    % forward solution
    suff = '';
    mous_db_getdata(subjectname,['meg_corrmnebf_freq',suff]);
    cfg = [];
    cfg.grid = sourcemodel;
    cfg.vol = headmodel;
    cfg.channel = 'MEG';
    cfg.grad = ft_struct2double(freq.grad);
    cfg.normalize = 'yes';
    sourcemodelbf = ft_prepare_leadfield(cfg);
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcemodel_-02-1s','sourcemodelbf');
end  

if domneavg  
    % calculate sources
    cfg                     = [];
    cfg.channel             = {'MEG', '-EEG057', '-EEG058'};
    cfg.method              = 'mne';
    cfg.vol                 = vol;             % vol and grid from "doleadmne"
    cfg.grid                = sourcemodelmne;
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
end 

if domnesingle
    % get source data on averaged trials from AH
    % if want to do a contrast btw cdtns, recalculate covariance to cover both conditions
    mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent_20130410}');
    
    % create the vertex x channel spatial filter matrix
    mnefilter = zeros(size(sd_Sent.pos,1), size(sourcemodelmne.leadfield{1},1));  % 8196 x 273
    % calc filter for each vertex 
    % one filter for each channel: project sensor lvl data to source lvl (each vertex)
    for k = 1:size(mnefilter,1)
        mnefilter(k,:) = sd_Sent.avg.ori{k}*sd_Sent.avg.filter{k}; 
    end
    
    % apply filter to data; output is amplitude of trial
    %% make sure that 273 filters do not include eogs!
    vertM = nan(size(mnefilter,1), numel(data.trial));  
    for k = 1:numel(data.trial)   
        tmp = mnefilter*data.trial{k}(1:273,toie(1):toie(2));  % [8196*273] * [273 * xx timepoints] 
        vertM(:,k) = tmp;  % Vertices(8196) by Trials (words: number varies depending on artifact rejection and MEG condition)
    end

    % vertex*trial data, trialinfo, MNE filter; source (+noise covariance matrix in source.avg); sd;
    mous_db_putdata(subjectname,'meg_corrmnebf_mnesingletrial_02-06','vertM','mnefilter','source','sd','tlck');

end

if dobeam
    %% sourcemodel and headmodel need to be arguements given to mous_bfica_source
    %  --> previously, these 2 models were called *inside* this function
    % Beamformer calculation - turned off balancing cdtns (sent/seq)
    % source analysis
    
    mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcemodel_-02-1s');    
    
    % toi = ?
    mous_db_getdata(subjectname, 'meg_corrmnebf_tfrsingletrial_02-06');
    [source, trialinfo] = mous_bfica_source(subjectname, freq, toi, 8, sourcemodelbf);
    % mous_db_putdata(subjectname,'meg_corrmnebf_bfsourcesingletrial_02-06','source','trialinfo');   % 10mm grid
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06','source','trialinfo');

    % sourcedata analysis
    sourcedata = mous_bfica_sourcedata(source, freq, toi);
    % mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcedatasingletrial_02-06','sourcedata');  % 10mm grid
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcedatasingletrial8mm_02-06','sourcedata');  % 8mm

end

if docor_cross
    %% cross correlation between TFRs (Vox) and ERFs (Vert)
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
    
    covVoxvert = voxM*vertM';  
    cor = covVoxvert./sqrt(varVox*varVert'); % remove variance from each element
    
    % save
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8','cor');  % 10mm grid - less precise
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8mm','cor');    
end

if docor_bf
%% within correlations

    % get data for beamformer only
    
    voxM  = sourcedata.trial{1}; 
    
    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)
    idxNan = find(isnan(voxM(1,:))); % check first row of each column for NaN (assume that it's entire column with NaN)
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
      %  vertM(:,idxNan) = [];
    end
    
    % mean subtraction (centre data)
    voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]);
    varVox = sum(voxM.^2,2);  
    
    covVoxvox   = voxM*voxM';
    corvox      = covVoxvox./sqrt(varVox*varVox');
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvoxt8mm_-0.1N1','corvert'); % tfrtoi = -0.1 and ERF = N1 response
end

if docor_mne
    % get data for MNE only
    
    varVert = sum(vertM.^2,2); 
    covVertvert = vertM*vertM';
    corvert     = covVertvert./sqrt(varVert*varVert');
    
    % save
    mous_db_putdata(subjectname,'meg_corrmnebf_corVertvert8mm','corvox'); 
end

if dogrpavg
%% group average
    subjectnames =  {ENTER SUBJs};
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


% if docov   % noise covariance matrix based on entire interval (-0.2 to 1s) to get accurate estimate of noise
%     %% only using data from sentences!  
%     mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}');
%     cfg                 = [];
%     cfg.vartrllength    = 2;
%     cfg.feedback        = 'textbar';
%     cfg.channel         = {'MEG', '-EEG057', '-EEG058'};
%     cfg.covariance      = 'yes';
%     cfg.covariancewindow = [-inf 1];
%     cfg.preproc.baselinewindow = [-inf 0];
%     sencdtn = [1 2 5 6];                                    % sentence triggers
%     cfg.trials = find(ismember(data.trialinfo(:,2),cdtn));  % choose only sentences from data
%     covtlck = ft_timelockanalysis(cfg,data);
%     fullcov = covtlck.cov;
%     mous_db_putdata(subjectname,'meg_corrmnebf_noisecov_sent_02-1','fullcov');
%     gradinfo = covtlck.grad;
%     mous_db_putdata(subjectname,'meg_corrmnebf_gradinfo_sent_02-1','gradinfo');
%     
% end 
    

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


  


