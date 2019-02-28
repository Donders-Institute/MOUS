function [coherence1, coherence2, coherence3, coherence4, fd1, fd2, fd3, fd4] = mous_neuralspeechcoherence(subjectname, foi, varargin)

% This function calculates the coherence between the neural signal to the
% speech envelope at the sensor level, use this function instead of
% mous_neuralspeechcoherence_sensor

if nargin < 2 || isempty(foi)
  foi = [0 30];
end

doplanar    = istrue(ft_getopt(varargin, 'doplanar', 1));
cfgredefine = ft_getopt(varargin, 'cfgredefine', []);
cfgfreq     = ft_getopt(varargin, 'cfgfreq',     []);
cfgpreproc  = ft_getopt(varargin, 'cfgpreproc',  []);

%% get the filename of the dataset
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts,mxUnshareArray(const_cast<mxarray *>(prhs[0]), true); preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
  artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  [data, speech] = computedata(dataset{1}, artfctcfg, cfgpreproc);
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg, cfgpreproc);
    
    if k==1,
      tmpsens1(k) = tmpdata.grad;
      weights1(k) = numel(tmpdata.trial);
      data       = tmpdata;
      
      tmpsens2(k) = tmpdata.grad;
      weights2(k) = numel(tmpdata.trial);
      speech     = tmpspeech;
    else
      % update the sentence counter
      tmpdata.trialinfo(:,1)   = tmpdata.trialinfo(:,1)   + data.trialinfo(end,1);
      tmpsens1(k)             = tmpdata.grad;
      weights1(k)             = numel(tmpdata.trial);
      data                   = ft_appenddata([], data, tmpdata);
      
      tmpspeech.trialinfo(:,1) = tmpspeech.trialinfo(:,1) + speech.trialinfo(end,1);
      tmpsens2(k)             = tmpdata.grad;
      weights2(k)             = numel(tmpdata.trial);
      speech                 = ft_appenddata([], speech, tmpspeech);
    end
    
  end
  data.grad   = ft_average_sens(tmpsens1, 'weights', weights1);   
  speech.grad = ft_average_sens(tmpsens2, 'weights', weights2);   
end


%% concatenate into one dataset
data = ft_appenddata([],data,speech);  % axial gradiometers, for subj-specific frequency search

%% cut the data into fragments with overlap (increase data - like welch method)
cfg         = cfgredefine;
cfg.length  = ft_getopt(cfgredefine, 'length',  2);  
cfg.overlap = ft_getopt(cfgredefine, 'overlap', 0.5); % 0 to 1 (exclusive)
data        = ft_redefinetrial(cfg, data);

%% do a quick and dirty trial rejection based on the threshold z-transformed log10(var)
for k = 1:numel(data.trial)
  M(:,k) = var(ft_preproc_polyremoval(data.trial{k},1),[],2);
end
Mz     = ft_preproc_standardize(log10(M));

thresh = 3;
rej    = sum(Mz(1:end-2,:)>thresh,1)>0;

cfg        = [];
cfg.trials = find(~rej);
data       = ft_selectdata(cfg, data);
  
%% divide data according to the conditions word list / sentence
cfg        = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 5])); % sent
data1      = ft_selectdata(cfg,data);

cfg.trials = find(ismember(data.trialinfo(:,2),[3 7])); % WL
data2      = ft_selectdata(cfg,data);
clear data;

%% calculate spectral representation
%  mtmfft:   fourier spectra; contains amplitude and phase
%            Cross-spectral density matrix inferred from fourier matrix
%            (infer CSD from fourier coefficients)
%  powandcsd:  cross-spectra, power-spectra; 

cfgf            = cfgfreq;
cfgf.method     = 'mtmfft'; 
cfgf.output     = 'powandcsd'; 
cfgf.foilim     = foi;
cfgf.tapsmofrq  = ft_getopt(cfgf, 'tapsmofrq', 2);      
cfgf.taper      = ft_getopt(cfgf, 'taper',     'dpss');
cfgf.pad        = ft_getopt(cfgf, 'pad',       4);
cfgf.channel    = {'MEG';'audio_avg'};
cfgf.channelcmb = {'MEG' 'audio_avg'};
cfgf.polyremoval = 1;
freq1           = ft_freqanalysis(cfgf, data1);
freq2           = ft_freqanalysis(cfgf, data2); 

%% calculate coherence 
cfgc            = [];
cfgc.method     = 'coh';
coherence1      = ft_connectivityanalysis(cfgc,freq1); % axial
coherence2      = ft_connectivityanalysis(cfgc,freq2);
 
%% calculate power spectra
fd1 = ft_freqdescriptives([], freq1);
fd2 = ft_freqdescriptives([], freq2);

if doplanar,
  %% convert to planar gradient if specified
  tmplabel = data1.label;  % use later when combining planar gradient components

  cfg              = [];
  cfg.method       = 'template';
  cfg.neighbours   = ft_prepare_neighbours(cfg,data1);
  cfg.planarmethod = 'sincos';
  data3            = ft_megplanar(cfg, data1);
  freq3            = ft_freqanalysis(cfgf, data3);
  coherence3       = ft_connectivityanalysis(cfgc, freq3);
  fd3              = ft_combineplanar([], ft_freqdescriptives([], freq3));
  
  data4            = ft_megplanar(cfg, data2);
  freq4            = ft_freqanalysis(cfgf, data4);
  coherence4       = ft_connectivityanalysis(cfgc, freq4);
  fd4              = ft_combineplanar([], ft_freqdescriptives([], freq4));


  %% combine planar gradient's vertical (dV) and horizontal (dH) components
  %  - Freq and Coherence calculation are non-linear (power = take abs)
  %  - If combine components prior to freq/coherence calculation we lose
  %  coherence estimate
  %  - Combining sensor_dV and sensor_dH using pythagoras leads to coherencePeakdetect_stage2_thres001_smoothing_wl.mata loss
  %  (canceling out) of the coherence estimate.
  %  - Use of pythagoras works for ERFs/TFRs signal; For ERF (because it's
  %  caluclate is a linear step, one can actually convert and combine prior
  %  to ERF calculation, but not for TFR and coherence calculations).
  %  - Combine dV and dH components by doing an average.
  %    An alternative is to use max(dV, dH)
  
  %%% SENT %%%
  % select sensors of interest
  
  sensize = size(coherence3.labelcmb,1)/2; % 273; dv and dH for each audio signal
  tmp1 = coherence3.cohspctrm(1:sensize,:);
  tmp2 = coherence3.cohspctrm((sensize+1):end,:);

  % compute average between dV and dH for combined planar gradient components
  coherence3.cohspctrm = (tmp1+tmp2)./2;
  coherence3.labelcmb  = coherence3.labelcmb(1:sensize,:);
  coherence3.labelcmb(1:sensize,1) = tmplabel;

  %%% WORD LIST %%%
  % select sensors of interest
  sensize = size(coherence4.labelcmb,1)/2; % 273; dv and dH for each audio signal
  tmp1 = coherence4.cohspctrm(1:sensize,:);
  tmp2 = coherence4.cohspctrm((sensize+1):end,:);

  % compute average between dV and dH for combined planar gradient components
  coherence4.cohspctrm = (tmp1+tmp2)./2;
  coherence4.labelcmb  = coherence4.labelcmb(1:sensize,:);
  coherence4.labelcmb(1:sensize,1) = tmplabel;
else
  coherence3 = [];
  coherence4 = [];
  fd3 = [];
  fd4 = [];
end

function [data, speech] = computedata(dataset, artfctcfg, cfgpreproc)

%% define trial
cfg                   = cfgpreproc;
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
% cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
% cfg.bsfreq     = [49 51];
% cfg.bsfilttype = 'firws';
% cfg.usefftfilt = 'yes';
cfg.hpfilter = ft_getopt(cfg, 'hpfilter', 'yes');
cfg.hpfreq   = ft_getopt(cfg, 'hpfreq',   1);
cfg.hpfilttype = ft_getopt(cfg, 'hpfilttype', 'firws');
cfg.usefftfilt = ft_getopt(cfg, 'usefftfilt', 'yes');

data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.hpfilter   = 'no';%'yes'; % does not need to be applied, data of this channel are not used anyway
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
cfg.hpfilttype = 'firws';
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
speech         = ft_preprocessing(cfg);

% load in the audioenvelopes as constructed from the wav files.
previous_sentid = 0;
for k = 1:numel(data.trial)
  sentid = num2str(data.trialinfo(k,5),'%03d');
  if previous_sentid ~= sentid
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
cfg             = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);
