% function mous_corrmnebf_pipeline(subjectname)
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
% selfq  boundaries need to be wider than the ultimate ones being achieved:
  % -0.15 -0.05  with toi -0.1  will give [-0.12 -0.08], centered at toi.

% Always exclude V1014 V1018 V1041 V1043 V1047 V1051 V1056 V1060 V1082 V1091

mous_db_makesubjdir(subjectname)

% step 1
    % run and saved once so they can be used repeatedly in the future
    % this step is currently not necessary cuz AH has all the data.
        dofreq      = false;
        %suff        = '';
        doleadbf    = false;
        %toie        = [-0.2 1.0];  % take entire second
        %doselerf    = false;       % selerf and tlck needed to get covariance matrix for MNE leadfield
        dotlck      = false;
        doleadmne   = false;
        domneavg    = false;       % true: to use noise cov mat from sentences only
% % step 2: 
%     % analyses on specific toi's
        suff        = '';
        toie        = [0.3 0.6];  % toi for ERFs
        toi         = [];         % toi for TFR % uncomment if bfica_sourcefixed
        selfq       = [0.08 0.12];% toi boundaries to circumvent matlab issue
        doselfreq   = false;
        doselerf    = false; 
        domatch     = false;
        domnesingle = false;
        dobeam      = false;
        doregwordorder = false; 
% % step 3:
%     % correlation of MNEs and BF's or just within a measure
        %docorcross = false;
        docorcross  = false;
        docorbf    = false;
        docormne   = false;
        dogrpavg   = true;
        
if dofreq
    %% TFRs 
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
    mous_db_getdata(subjectname,'meg_corrmnebf_freq');
    warning off;
    freq   = ft_struct2double(freq);
    warning on;
    sencdtn = [1 2 5 6]; 
    sidx   = find(ismember(freq.trialinfo(:,2),sencdtn));
    freq   = ft_selectdata(freq,'rpt',sidx);
    
    cfg = [];
    cfg.latency = [selfq(1) selfq(2)];  
    freq        = ft_selectdata(cfg,freq); 
    idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
    freq        = ft_selectdata(freq,'rpt',idxful);  
end

if doselerf
    %% select only the sentences and baseline normalise
    mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); 
    sencdtn     = [1 2 5 6];
    sentidx     = find(ismember(data.trialinfo(:,2),sencdtn));
    data        = ft_selectdata(data,'rpt',sentidx);
    
    cfg         = [];
    cfg.latency = [toie(1) toie(2)];
    data        = ft_selectdata(cfg,data);
       
    % calc baseline
    all = size(data.trial,2);
    bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
    bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)
    
    % normalise each trial (adjust baseline to fit each trial's dimensions)
    for k = 1:size(data.trial,2)
        rows = 1; columns = size(data.trial{k},2);  % matrix dim for each trial
        bslrep = repmat(bslavgVec, [rows columns]); % replicate bslvector to fit size of toi trials
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
    tlck = ft_timelockanalysis(cfg, data);  
    % save full seconds data for covariance matrix (and incase need to reproduce tlck)
    if toie(2) == 1 
        mous_db_putdata(subjectname,'meg_corrmnebf_tlck_-02-1s','tlck');
    end 
    
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

if doleadmne
    %% leadfields for MNE (specific to cdtn of interest, because covariance matrix is used, and that is cdtn dependent)
    % Get  sourcemodel and headmodel
    sourcemodel = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  
    if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
        sourcemodel.pos  = sourcemodel.pnt;
        sourcemodel      = rmfield(sourcemodel, 'pnt');
    end
    sourcemodel.inside = 1:8196; % hard code because coreg not perfect so some subj have sources hovering on border
    sourcemodel.outside = [];
    mous_db_getdata(subjectname,  'meg_anatomy_headmodel'); 
    
    cfg             = [];
    cfg.grad        = tlck.grad;  % sensor positions
    cfg.vol         = vol;
    cfg.grid        = sourcemodel;
    cfg.channel     = {'MEG', '-EEG057', '-EEG058'};
    cfg.feedback    = 'textbar';
    sourcemodelmne  = ft_prepare_leadfield(cfg);
    mous_db_putdata(subjectname, 'meg_corrmnebf_mnesourcemodel_sent_-02-1s','sourcemodelmne');
end 

if dobeam
    %% beamformer
    % sourcemodel is now an inarg; 
    % freq is coming from doselfreq   
    freq.calc = 1;
    freq = rmfield(freq,'time');
    freq.dimord = 'rpttap_chan_freq'; 
    [source, trialinfo] = mous_bfica_source(subjectname, freq, toi, 8);
    
    sourcedata = mous_bfica_sourcedata(source, freq);
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_-01','source','sourcedata','trialinfo','freq');
    % need trialinfo and freq for regression, sourcedata for correlation
end

if domneavg  
    %% calculate sources for averaged data
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
    % need to save this data for it to be used by corrmnebf_interpolate

    cfg            = [];
    cfg.demean     = 'yes';
    cfg.projectmom = 'yes';
    cfg.zscore     = 'no';
    sd             = ft_sourcedescriptives(cfg, source);
end 

if domnesingle
    %% calculate sources for each trial
    % get source data on averaged trials from AH
    % if want to do a contrast btw cdtns, recalculate covariance to cover both conditions
    mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent_20130410}');
    
    % mous_db_getdata(subjectname,'meg_corrmnebf_mneavgdata_-02-1s');         % get sd info
    % mous_db_getdata(subjectname,'meg_corrmnebf_mnesourcemodel_sent_-02-1s');% get sourcemodel
    % data  = the single trials needed for computation are from doselerf

    % create the vertex x channel spatial filter matrix
    mnefilter = zeros(size(sd_Sent.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
    for k = 1:size(mnefilter,1)
        mnefilter(k,:) = sd_Sent.avg.ori{k}*sd_Sent.avg.filter{k}; 
    end
    
    % project single trials to source space
    % foolproof: remove eog channels, so they will never be project to source space instead of a MEG channel
    channel  = {'MEG', '-EEG057', '-EEG058'};
    data     = ft_selectdata(data,'channel',channel);
    
    % tlck avg of all toi sentences
    cfg = [];
    if strcmp(subjectname, 'V1011')
        cfg.vartrllength = 2;
    end
    tlck = ft_timelockanalysis(cfg, data);
    mnetlck = mnefilter*tlck.avg;
    nword   = numel(data.trial);

    % MNE filter for jack knife
    vertM = nan(size(mnefilter,1), numel(data.trial));  
    for k = 1:numel(data.trial)   
        tmp = (mnetlck.*nword-mnefilter*data.trial{k})./(nword-1); % (:,toie(1):toie(2));  % [8196*273] * [273 * xx timepoints] 
        %tmp = mnefilter*data.trial{k};
        tmp = nanmean(abs(tmp),2); 
        vertM(:,k) = tmp;  % Vertices(8196) by Trials (words: number varies depending on artifact rejection and MEG condition)
    end
    % save output for mous_corrmnebf_interpolate!!!
    source = source_sent;
    sd = sd_Sent;
    mous_db_putdata(subjectname,'meg_corrmnebf_mnesingletrial_jack_0306_bf01','vertM','mnefilter','source','sd');
end

if doregwordorder
    %% regress out word order
    
    mous_db_getdata(subjectname,'meg_corrmnebf_mnesingletrial_jack_0306_bf01');  % get vertM
    mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_01') % get voxM
    voxM  = sourcedata.trial{1}; 
    
    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)    
    idxNan = find(isnan(voxM(1,:))); 
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
        vertM(:,idxNan) = [];
    end
    
    % compute the leave-one-out for the oscillations, the mne has been done
    % already
    voxMsum = sum(voxM,2);
    voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);
    
    % regression    
    [cor, corvox, corvert] = mous_corrmnebf_regression(subjectname, voxM, vertM, trialinfo);
    
    % saving
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf01mne0306','cor');   
    mous_db_putdata(subjectname,'meg_corrmnebf_corVertvert8mm_sdregwordord_jack_bf01mne0306','corvert');    
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvox8mm_sdregwordord_jack_bf01mne0306','corvox');        
end 

if docorcross
    %% cross correlation between TFRs (Vox) and ERFs (Vert)
    % Covariance & Correlation Calculation
    voxM  = sourcedata.trial{1}; 
    
    
    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)
    idxNan = find(isnan(voxM(1,:))); 
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
        vertM(:,idxNan) = [];
    end

    % compute the leave-one-out for the oscillations, the mne has been done
    % already
    voxMsum = nansum(voxM,2);
    voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);
    
    % mean subtraction (centre data)
    voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]);
    vertM = vertM - repmat(mean(vertM,2),[1 size(vertM,2)]);
    
    % remove variance 
    varVox = sum(voxM.^2,2);  % variance 
    varVert = sum(vertM.^2,2); 
    covVoxvert = voxM*vertM'; % covariance matrix
    cor = covVoxvert./sqrt(varVox*varVert'); % corr matrix = remove variance from each element
    
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert8mm_bf02mne0306','cor');    
end

if docorbf
%% within correlations
    % get data for beamformer only
    % mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcedatasingletrial8mm_-01');
    
    voxM  = sourcedata.trial{1}; 
    
    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)
    idxNan = find(isnan(voxM(1,:))); % check first row of each column for NaN (assume that it's entire column with NaN)
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
    end
            
    % compute the leave-one-out for the oscillations, the mne has been done
    % already
    voxMsum = nansum(voxM,2);
    voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);
    
    
    voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]); % mean subtraction (centre data)
    varVox = sum(voxM.^2,2);                             % calc variance for each measure
    %%% start here if cor_cross has just been executed
    covVoxvox   = voxM*voxM';                            % calc covariance matrix
    corvox      = covVoxvox./sqrt(varVox*varVox');       % corr matrix = remove variance from each element
    mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvoxt8mm_bf02mne0306','corvox'); % tfrtoi = -0.1 and ERF = N1 response
end

if docormne
    
    varVert = sum(vertM.^2,2);
    %%% start here if cor_cross has just been executed
    covVertvert = vertM*vertM';
    corvert     = covVertvert./sqrt(varVert*varVert');
    % save
    mous_db_putdata(subjectname,'meg_corrmnebf_corVertvert8mm_bf02mne0306','corvert'); 
end

if dogrpavg
%% group average
% interpolate 2dto3d for each participant prior to averaging (same
% coordinate across subject ~= same brain location)
    % subjectnames as of April 25, 2013.
    subjectnames = {'V1004' 'V1005' 'V1007' 'V1008'...
                 'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1019'...
                 'V1020' 'V1023' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028'...
                 'V1031' 'V1032' 'V1033' 'V1036' 'V1037' 'V1039'...
                 'V1044' 'V1045'...
                 'V1050' 'V1052' 'V1055' 'V1057' 'V1059'...
                 'V1061' 'V1062' 'V1063' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                 'V1070' 'V1071' 'V1074' 'V1075' 'V1076' 'V1077'...
                 'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1086' 'V1087'...
                 'V1090' 'V1094' 'V1095' 'V1098'...
                 'V1100' 'V1102' 'V1104'};    

   
    for q = 1:numel(subjectnames)
        % interpolate the correlation matrix to 3d space
        % source   grid
        [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectnames{q});
        
        if q == 1
            data = source3d;
        else
            data.corrmat = data.corrmat + source3d.corrmat;
        end 
    end
    dataAvg = source3d;
    dataAvg.corrmat = dataAvg.corrmat./numel(subjectnames);
 
    mous_db_putdata('groupresults','meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf01mne0306.mat','dataAvg');
end    

%% visualise
    mous_db_getdata('groupresults','meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf01mne0306.mat');
     
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    grid = load(fname);
    grid = sourcemodel;  grid = grid.sourcemodel;
    grid.inside = grid.inside(:,dataAvg.inside);
    sourcemodel.pos    = sourcemodel.pos(dataAvg.pos,:);
  
    mous_connectivitybrowser(grid,dataAvg,'parameter','corrmat','method',{'slice','slice'},'anasc',[-0.007 0.007],'cohsc',[-0.007 0.007]);





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

