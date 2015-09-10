function [coherence1, coherence2, coherence3, coherence4] = mous_neuralspeechcoherence_sensor(subjectname, cohfoi, varargin)

% Calculate the coherence between the neural signal and speech envelope.
% The neural signal can be the raw frequencies (used for theta and delta),
% or the envelope of a defined band of frequencies (used for gamma)
% If sentences and word lists can be combined (to be determined), then this
% code can be adjusted. Currently, depending if calculating for gamma or
% lower frequencies, certain parts need to be commented out

%% load raw data
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts, preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
  artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  [data, speech] = computedata(dataset{1}, artfctcfg);
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg);
    
    if k==1,
      tmpsens1(k) = tmpdata.grad;
      weights1(k) = numel(tmpdata.trial);
      data       = tmpdata;
      
      tmpsens2(k) = tmpdata.grad;
      weights2(k) = numel(tmpdata.trial);
      speech     = tmpspeech;
    else
      % update the sentence counter
      tmpdata.trialinfo(:,1)  = tmpdata.trialinfo(:,1)   + data.trialinfo(end,1);
      tmpsens1(k)             = tmpdata.grad;
      weights1(k)             = numel(tmpdata.trial);
      data                    = ft_appenddata([], data, tmpdata);
      
      tmpspeech.trialinfo(:,1) = tmpspeech.trialinfo(:,1) + speech.trialinfo(end,1);
      tmpsens2(k)              = tmpdata.grad;
      weights2(k)              = numel(tmpdata.trial);
      speech                   = ft_appenddata([], speech, tmpspeech);
    end
    
  end
  data.grad   = ft_average_sens(tmpsens1, 'weights', weights1);   
  speech.grad = ft_average_sens(tmpsens2, 'weights', weights2);   
end


%% convert to planar gradient
tmplabel = data.label;  % use later when combining planar gradient components

cfg = [];
cfg.method       = 'template';
cfg.neighbours   = ft_prepare_neighbours(cfg,data);
cfg.planarmethod = 'sincos';
%dataPL           = ft_megplanar(cfg,data);


%% apply hilbert transform to MEG signal to extract gamma envelope
%  bandpass and then hilbert transform 
%   - the reverse can lead to dominance of low frequencies in signal
%   - ft_preproc_hilbert checks that BP is done when specifying cfg.hilbert
% cfg.bpfiltdir  = % onepass-zerophase is set in ft_preproc_bandpassfilter.m
% cfg.bpfiltord  = % determined in ft_preproc_bandpassfilter.m
% cfg.bpfiltwintype = % default is hamming 
% cfg.bpfiltdf   = % default width heuristic used fir_df.m

if nargin == 3   % if specification of gamma frequencies 
  cfg = [];
  cfg.bpfilter   = 'yes';    
  cfg.bpfreq     = varargin{1};  % coupling btw 35-45; lateralization 40 - 70
  cfg.bpfilttype = 'firws';
  cfg.hilbert    = 'abs';
  dataPL         = ft_preprocessing(cfg,dataPL);
  data           = ft_preprocessing(cfg,data);  % Axial data, keep as 'data' to minimize lines of code
end 

%% concatenate into one dataset 
dataAX = ft_appenddata([],data,speech);    % axial gradiometers, for subj-specific frequency search
dataPL = ft_appenddata([],dataPL,speech);  % planar gradiometers, for grp-level averaging

%% cut the data into fragments with overlap (increase data - like welch method)
cfg = [];
cfg.length  = 2;  
cfg.overlap = 0.5; % 0 to 1 (exclusive)
dataAX = ft_redefinetrial(cfg, dataAX);
dataPL = ft_redefinetrial(cfg, dataPL);

%% split conditions
cfg = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 5])); % sent
data1  = ft_selectdata(cfg,dataAX); % axial
data3  = ft_selectdata(cfg,dataPL); % planar

cfg.trials = find(ismember(data.trialinfo(:,2),[3 7])); % WL
data2  = ft_selectdata(cfg,dataAX); % axial
data4  = ft_selectdata(cfg,dataPL); % planar

%% calculate power- and cross-spectra
%  mtmfft:   fourier spectra; contains amplitude and phase
%            Cross-spectral density matrix inferred from fourier matrix
%            (infer CSD from fourier coefficients)
%  powandcsd:  cross-spectra, power-spectra; 

cfg = [];
cfg.method     = 'mtmfft';  %  get power change in gamma; deal with filtering-artifacts
cfg.output     = 'powandcsd'; 
if numel(cohfoi) == 2
  cfg.foilim   = cohfoi; % vector
elseif numel(cohfoi) == 1
  cfg.foi      = cohfoi; % singular
end
cfg.tapsmofrq  = 2;           
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';     
cfg.channel    = {'MEG' 'audio_avg'}; % exclude UADC003 channel
cfg.channelcmb = {'MEG' 'audio_avg'};

freq1          = ft_freqanalysis(cfg,data1); % axial  sentence 
freq3          = ft_freqanalysis(cfg,data3); % planar sentence
freq2          = ft_freqanalysis(cfg,data2); % axial  word list
freq4          = ft_freqanalysis(cfg,data4); % planar word list


%% calculate coherence 
cfg = [];
cfg.method     = 'coh';
cfg.channelcmb = {'MEG' 'audio_avg'}; % Specify channel and channelref

coherence1     = ft_connectivityanalysis(cfg,freq1); % axial  sentence
coherence3     = ft_connectivityanalysis(cfg,freq3); % planar 
coherence2     = ft_connectivityanalysis(cfg,freq2); % axial  word list
coherence4     = ft_connectivityanalysis(cfg,freq4); % planar


%% combine planar gradient's vertical (dV) and horizontal (dH) components
%  - Freq and Coherence calculation are non-linear (power = take abs)
%  - If combine components prior to freq/coherence calculation we lose
%  coherence estimate 
%  - Combining sensor_dV and sensor_dH using pythagoras leads to a loss
%  (canceling out) of the coherence estimate.  
%  - Use of pythagoras works for ERFs (because steps are linear: can  convert and combine prior
%  to ERF calculation) But not power/coherence.
%  - Combine dV and dH components by doing an average. 
%    An alternative is to use max(dV, dH)

%%% SENT %%%
% select sensors of interest
sensize = size(coherence3.labelcmb,1)/2; % 273; dv and dH for each audio signal
tmp1 = coherence3.cohspctrm(1:sensize,:);
tmp2 = coherence3.cohspctrm(sensize+1:end,:);

% compute average between dV and dH for combined planar gradient components
coherence3.cohspctrm = (tmp1+tmp2)./2;
coherence3.labelcmb  = coherence3.labelcmb(1:sensize,:);
coherence3.labelcmb(1:sensize,1) = tmplabel;

% %%% WORD LIST %%%
% select sensors of interest
sensize = size(coherence4.labelcmb,1)/2; % 273; dv and dH for each audio signal
tmp1 = coherence4.cohspctrm(1:sensize,:);
tmp2 = coherence4.cohspctrm(sensize+1:end,:);

% compute average between dV and dH for combined planar gradient components
coherence4.cohspctrm = (tmp1+tmp2)./2;
coherence4.labelcmb  = coherence4.labelcmb(1:sensize,:);
coherence4.labelcmb(1:sensize,1) = tmplabel;

% varargout{1} = coherence1;
% varargout{2} = coherence2;
% varargout{3} = coherence3;
% varargout{4} = coherence4;

%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION %%%%
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
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
cfg.bsfreq     = [49 51];
cfg.bsfilttype = 'firws'; % windowed sinc FIR filter
cfg.usefftfilt = 'yes';   % this replaces firws?
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

