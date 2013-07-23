% function mous_corrmnebf_cormat(subjectname)
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

%% for original correlation matrix
% comment out the 'leave-one-out' estimates
% calculate correlation matrix using docorcross (or docorbf/docormne)
% instead of doregwordorder

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
        dofreq       = false;
        doleadbf     = false;
        dotlck       = false;
        doleadmne    = false;
        domneavg     = false;       % true: to use noise cov mat from sentences only
% % step 2: 
%     % analyses on specific toi's
%         suff        = '16';      
%         foi         = 16;        
%         toie        = [0.35 0.45];  % toi for ERFs
%         toi         = [];           % toi for TFR % not neded because selfq defines  toi
%         cdtn        = 'sen';        % options 'seq','svs_sen','svs_seq'
%         if strcmp(cdtn,'sen')
%            sencdtn = [1 2 5 6];
%         else
%            sencdtn = [3 4 7 8];
%         end
%         selfq       = [-0.12 -0.08];
%         savebf      = '-01';     % central frequency:  0.1, for 0.08 to 0.12 for TFR toi
%         savemne     = regexprep([num2str(toie(1)) num2str(toie(2))],'[.]',''); 
       
        doselfreq   = true;
        doselerf    = true; 
        domatch     = true;   
        domnesingle = true;
        dobeam      = true;
        doregwordorder = true; 
% % step 3:
%     % correlation of MNEs and BF's or just within a measure
        dogrpavg   = false;
        dostats    = false;
        
if dotrialcnt  
    load '/home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_logtrials.mat' 
    
    izero = find(log(:,2) == 0);
    log2 = log;
    log2(izero,:) = [];    
    
    desc = zeros(4,4);
    desc(1,:) = floor(mean(log2,1));
    desc(2,:) = floor(min(log2));
    desc(3,:) = floor(max(log2));
    save('/home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_logtrials.mat','log','desc'); 
end 
               
if dofreq
    %% TFRs 
    rootdir = '/home/language/jansch/public/mous/';
    options = [];
    options.taper = 'hanning';
    options.t_ftimwin = 0.250;
    options.resamplefs = 300;
    frequency = 20;
    [freq, dataStats] = mous_bfica_freq(subjectname, frequency, rootdir, options); % data from mous_corrmnebf_comp is called inside mous_bfica_freq
    mous_db_putdata(subjectname, ['meg_corrmnebf_freq',suff], 'freq','dataStats');
end

if doselfreq
    %% select only sentences and toi
    
    rootdir = '/home/language/jansch/public/mous/';      % all the low frequencies, where freq.freq = [2.5 5 7.5 10 12]
                                                         % *FIXME* add functionality for intermediate/high frequencies
    mous_db_getdata(subjectname,'meg_bfica_freq_medium',rootdir);
    freq = ft_selectdata(freq,'foilim',foi*[1 1]);       % following doesn't work: cfg = [];  cfg.foilim  = [5 5];
     
    warning off;
    freq   = ft_struct2double(freq);
    warning on;
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
    sentidx     = find(ismember(data.trialinfo(:,2),sencdtn));
    data        = ft_selectdata(data,'rpt',sentidx);

    % calc baseline
    all = size(data.trial,2);
    bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
    bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)
    
    % apply baseline (normalize); adjust baseline to fit each trial's dimensions)
    for k = 1:size(data.trial,2)
        rows = 1; columns = size(data.trial{k},2);  % matrix dim for each trial
        bslrep = repmat(bslavgVec, [rows columns]); % replicate bslvector to fit size of toi trials
        data.trial{k} = data.trial{k}-bslrep;     
    end
    
    % select toi 
    cfg = [];
    cfg.toilim = [toie(1) toie(2)];
    data       = ft_selectdata(cfg,data);     
      
    % take only trials with full number of samples (no artifacts removed)
    erftime = toie(2) - toie(1);
    tmp = floor(erftime*300); % make integer instead of with decimals i.e. XX.000)
    corrsmp = [tmp tmp+1];    % because of matlab rounding/nearest function/precision issues, will take trials that have 300 or 301 samples
    nsmp = cellfun('size',data.trial,2);

    fulltrial = find(ismember(nsmp,corrsmp));   
    data = ft_selectdata(data,'rpt',fulltrial);
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
    % not toi/cdtn specific because the only data required from freq is
    % freq.grad (which is sensor channels)
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
    % freq is coming from doselfreq   
    freq.calc = 1;
    freq = rmfield(freq,'time');
    freq.dimord = 'rpttap_chan_freq'; 
    [source, trialinfo] = mous_bfica_source(subjectname, freq, toi, 8);
    
    if ~isempty(foi)
        freq.cumtapcnt = ones(size(freq.fourierspctrm,1),1);
    end 
    sourcedata = mous_bfica_sourcedata(source, freq);
 
    mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn],'source','sourcedata','trialinfo','freq');
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
  
    % mous_db_getdata(subjectname,'meg_corrmnebf_mneavgdata_-02-1s');         % get sd info
    % mous_db_getdata(subjectname,'meg_corrmnebf_mnesourcemodel_sent_-02-1s');% get sourcemodel
    % data  = the single trials needed for computation are from doselerf

    % Noise covariance matrix is calculate using stim for all conditions,
    % so it doesnt matter if I load it from Sent or Seq.
    % what does matter is that I get the correct MNE estimate averaged
    % across all trials of interest
    if strcmp(cdtn,'sen')
        mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent_20130502}');
        % create the vertex x channel spatial filter matrix
        mnefilter = zeros(size(sd_Sent.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
        for k = 1:size(mnefilter,1)
            mnefilter(k,:) = sd_Sent.avg.ori{k}*sd_Sent.avg.filter{k}; 
        end  
    elseif strcmp(cdtn,'seq')
        mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq_20130502}');
        % create the vertex x channel spatial filter matrix
        mnefilter = zeros(size(sd_Seq.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
        for k = 1:size(mnefilter,1)
            mnefilter(k,:) = sd_Seq.avg.ori{k}*sd_Seq.avg.filter{k}; 
        end  
    end 

    % project single trials to source space
    % foolproof: remove eog channels, so they will never be project to source space instead of a MEG channel
    channel  = {'MEG', '-EEG057', '-EEG058'};
    data     = ft_selectdata(data,'channel',channel);
    
    % tlck avg of all toi sentences
    cfg = [];
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
    
    % save output for mous_corrmnebf_interpolate
    if sencdtn(1) == 1
        source = source_sent;
        sd = sd_Sent;
    elseif sencdtn(1) == 3
        source = source_seq;
        sd = sd_Seq;
    end 
        
    mous_db_putdata(subjectname,['meg_corrmnebf_mnesingletrial_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn],'vertM','mnefilter','source','sd');
 
end

if doregwordorder
    %% regress out word order  
%     mous_db_getdata(subjectname,'meg_corrmnebf_mnesingletrial_jack_0306_bf01');  % get vertM
%     mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_01') % get voxM
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
    
    mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_', cdtn],'cor'); 
   
end 

if dogrpavg
%% group average
% interpolate 2dto3d for each participant prior to averaging (same
% coordinate across subject ~= same brain location) 

% interp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
% interp.erf = ['meg_corrmnebf_mnesingletrial_jack_',savemne,'_bf',savebf,'_',suff,'Hz_',cdtn];
% interp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];

mous_corrmnebf_grpavg(subjectnames,interp);
    
end    

if dostats
    % roi variable can hold >1 ROI  .. **still developing **
    mous_corrmnebf_grpstat_roi2whole(subjectnames,cfg,roi);
    % mous_corrmnebf_grpstat_roi2roi(subjectnames,cfg,roi);
end 

