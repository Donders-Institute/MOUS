function [varargout] = mous_neuralspeechcoherence_sourcedata_freqhigh(subjectname,gamfoi,foi,sourcerange,cdtn,varargin)
% mous_neuralspeechcoherence_sourcedata_high computes coherence at the
% source-level between the gamma enveloep and the speech signal
% Definition of preprocessed data includes all processing steps that are
% common across frequencies chosen for the speech signal to use in
% cross-frequency coupling
  % filtering
  % dividing data into 3 conditions (sent, wl, all)
  % computing spatial filter
  % combining channels (megdata and speech)
  % cutting data into segments 
  
% bandpass filtered data is project into source-space,
% calculate fourier (cross-spectra) on virtual channel data 
% calculate coherence (Ft_connectivity) on virtual channel data

% gamfoi = gamma frequencies of interest. set to [30 50]
% gamma bandpass properties
  % cfg.bpfiltdir  = % onepass-zerophase is set in ft_preproc_bandpassfilter.m
  % cfg.bpfiltord  = % determined in ft_preproc_bandpassfilter.m
  % cfg.bpfiltwintype = % default is hamming 
  % cfg.bpfiltdf   = % default width heuristic used fir_df.m
  % cfg.hilbert    = 'abs';  % DO NOT calculate envelope at sensor-level 
  
% foi = frequencies at which to calculate coherence between gamma envelope and speech envelope

% Only a subset of sources I calculate each time this functions is called
% mous_neuralspeechcoherence_gammacombinesource.m handles combining data across sources
% NL 02-04-2015

if nargin < 6
  source = [];
elseif nargin == 6
  source = varargin{1};
end

if isempty(source)
  %% PREPROCESS DATA
  % Here, all steps are the same, independent of which source is
  % being calculated
    % load raw data
  dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

  % define trials, remove artifacts, preprocess data
  if numel(dataset) == 1
    mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
    artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [datpp, speech] = computedata(dataset{1}, artfctcfg);

  elseif numel(dataset) > 1
    for k = 1:numel(dataset)
      tmpdataset = dataset{k};
      mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
      tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
      [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg);

      if k==1,
        tmpsens1(k) = tmpdata.grad;
        weights1(k) = numel(tmpdata.trial);
        datpp       = tmpdata;

        tmpsens2(k) = tmpdata.grad;
        weights2(k) = numel(tmpdata.trial);
        speech     = tmpspeech;
      else
        % update the sentence counter
        tmpdata.trialinfo(:,1)  = tmpdata.trialinfo(:,1)   + datpp.trialinfo(end,1);
        tmpsens1(k)             = tmpdata.grad;
        weights1(k)             = numel(tmpdata.trial);
        datpp                   = ft_appenddata([], datpp, tmpdata);

        tmpspeech.trialinfo(:,1) = tmpspeech.trialinfo(:,1) + speech.trialinfo(end,1);
        tmpsens2(k)             = tmpdata.grad;
        weights2(k)             = numel(tmpdata.trial);
        speech                 = ft_appenddata([], speech, tmpspeech);
      end

    end
    datpp.grad   = ft_average_sens(tmpsens1, 'weights', weights1);   
    speech.grad  = ft_average_sens(tmpsens2, 'weights', weights2);   
  end
  
  %% bandpass gamma band activity

  cfg = [];
  cfg.bpfilter   = 'yes';    
  cfg.bpfreq     = [gamfoi(1) gamfoi(2)];  % coupling btw 35-45; lateralization 40 - 70 from Gross et al., 2014
  cfg.bpfilttype = 'firws';
  datpp          = ft_preprocessing(cfg,datpp);  % Axial, preprocessed(pp) data

  %% divide conditions
  cfg = [];
  cfg.trials = find(ismember(datpp.trialinfo(:,2),[1 5])); % sent
  data1      = ft_selectdata(cfg,datpp); 
  speech1    = ft_selectdata(cfg,speech);

  %% compute spatial filter
  % covariance matrix 
    % for LCMV: preprocessing should have cfg.demean = 'yes';
    % data covariance matrix compared to transfer matrix (forward solution)
    % use common-filter approach
  cfg = [];
  cfg.covariance   = 'yes';
  cfg.channel      = 'MEG';
  cfg.vartrllength     = 2;    % all trial lengths
  cfg.covariancewindow = 'all';
  tlck                 = ft_timelockanalysis(cfg,data1);

  % load forward model (headmodel)
  headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

  % load sourcemodel   (grid); stick with 5798
  sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');

  % source reconstruct bandpass filtered gamma (lcmv; keep spatial filter)
  cfg = [];
  cfg.method           = 'lcmv';  % time domain, no need cfg.foi
  cfg.vol              = headmodel;
  cfg.grid             = sourcemodel;
  cfg.lcmv.keepfilter  = 'yes';
  cfg.lcmv.fixedori    = 'yes'; % project on axis with most variance using SVD
  source               = ft_sourceanalysis(cfg, tlck);

  % pass data1 across frequencies, otherwise have to pass 2 arguments
  source.data1   = data1; 
  source.speech1 = speech1;
end  

%% project bandpass filtered data through spatial filter - sourcedata1 (output) is dependent on current sources 
  % turn sensor-data into source-data
  % multiply sensor-level data by source.avg.filter of each voxel (inside)
  % aka. extract virtual-channel time-series

  data1   = source.data1;
  speech1 = source.speech1;
  
  filt = cat(1,source.avg.filter{source.inside}); % 8196*273
  filt = filt(sourcerange(1):sourcerange(2),:);   % e.g., 1000*273
  
  % Create sourcedata structure to mimic raw data structure (need time,trial,label fields)
  % all subjects have 8196 sources, if not, labels would be wrong and be
  % avging across non-identical sources across subjects
  sourcedata1      = [];
  sourcedata1.time = data1.time;
  for k = sourcerange(1):sourcerange(2)
    sourcedata1.label{k,1} = ['chan',num2str(k,'%04d')];
  end
  idx = cellfun(@isempty,sourcedata1.label); 
  sourcedata1.label(idx) = [];
  
  for trialloop = 1:length(data1.trial)  
    sourcedata1.trial{trialloop} = abs(hilbert((filt*data1.trial{trialloop})'))';  % e.g., 1000*273 x 273*sample points 
  end

  % hilbert function is applied columnwise, flip filt*data
  % data1.trial{X} = 273 * 750
  % filt           = 100 * 273

  %% combine channels 
  sourcedata1  = ft_appenddata([],sourcedata1,speech1); % concatenate into one dataset; axial gradiometers for subj-specific frequency search

  %% cut the data into fragments with overlap (increase data - like welch method)
  cfg = [];
  cfg.length      = 2;  
  cfg.overlap     = 0.5; % 0 to 1 (exclusive)
  sourcedata1 = ft_redefinetrial(cfg, sourcedata1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% fourier and source-localization (frequency band specific) %%%
%% ft_freqanalysis on virtual channel data

% get peakfrequency for specified frequency band
% subj x freq range matrix
[subj,~] = mous_db_getfilename('allA','subjectname');
root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
load([root,'/coherencePeakdetect_stage2_thres001_smoothing_',cdtn]);
idx      = find(ismember(subj,subjectname));

% get foi
switch foi
  case 'delta'
    freqcol = 1;
  case 'theta'
    freqcol = 2;
  case 'alpha'
    freqcol = 3;
  case 'beta'
    freqcol = 4;
end
foi         = peakfreqfirst(idx,freqcol);

% calculate fourier data
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'fourier'; % not 'powandcsd; compute csd online'
cfg.foi        = foi;       % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 2;         % 2 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channel    = {'all','-UADC003'};
fourier1        = ft_freqanalysis(cfg, sourcedata1);

% normalize fourier output of speech with speech amplitude
selchan = match_str(fourier1.label, {'audio_avg'});
fourier1.fourierspctrm(:,selchan,:) = fourier1.fourierspctrm(:,selchan,:)./abs(fourier1.fourierspctrm(:,selchan,:));

%% ft_connectivity analysis on spectral virtual channel data
cfg = [];
cfg.method = 'coh';
coherence1  = ft_connectivityanalysis(cfg,fourier1);

%% return results
varargout{1} = coherence1; % sen
if nargout > 1
  varargout{2} = source;
end

%%%%%%%%%%%%%%%
%% subfunction%
%%%%%%%%%%%%%%%
function [data, speech] = computedata(dataset, artfctcfg)

%% define trial
cfg                   = [];
cfg.dataset           = dataset;
cfg.trialfun          = 'trialfun_auditory_sentence';
cfg.trialdef.prestim  = 'audioonset';
cfg.trialdef.poststim = 0.2;
cfg = ft_definetrial(cfg);

%% define audio onset to be time point 0, and remove artifacts
trl = cfg.trl;
trl(:,3) = 0;
trl = mous_artifact_remove(trl, dataset, artfctcfg, 'partial', 1); 

%% preprocess neural data and speech audio file
cfg.trl        = trl(1:5,:);
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
cfg.bsfreq     = [49 51];
cfg.bsfilttype = 'firws';
cfg.usefftfilt = 'yes';  % if remove bsfilter, can I also remove usefftfilt?
data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
speech         = ft_preprocessing(cfg);

% load in the audioenvelopes as constructed from the wav files.
previous_sentid = 0;
for k = 1:numel(data.trial)
  sentid = num2str(data.trialinfo(k,5),'%03d');
  if ~strcmp(previous_sentid,sentid)
    load(fullfile('/project/3011020.09/MEG/misc/audiostimuli',['audiodata_envelope',sentid]));
  end 
  i1 = nearest(audio.time{1},data.time{k}(1));
  i2 = nearest(audio.time{1},data.time{k}(end));
  i3 = nearest(data.time{k},audio.time{1}(1));
  i4 = nearest(data.time{k},audio.time{1}(end));
  speech.trial{k}(2,:) = 0;
  speech.trial{k}(2,i3:i4) = audio.trial{1}(end,i1:i2);
  previous_sentid = sentid;
end
speech.label = [speech.label;{'audio_avg'}];

%% downsample
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);

