<<<<<<< HEAD
function [coherence1, coherence2, coherence3, coherence4] = mous_neuralspeechcoherence(subjectname, foi)
% This function calculates the coherence between the neural signal to the
% speech envelope

%% load raw data
=======
function [coherence1, coherence2, coherence3, coherence4, fd1, fd2, fd3, fd4] = mous_neuralspeechcoherence(subjectname, foi, varargin)

% This function calculates the coherence between the neural signal to the
% speech envelope at the sensor level, use this function instead of
% mous_neuralspeechcoherence_sensor

if nargin < 2 || isempty(foi)
  foi = [0 30];
end

doplanar = istrue(ft_getopt(varargin, 'doplanar', 1));
cfgredefine = ft_getopt(varargin, 'cfgredefine', []);
cfgfreq     = ft_getopt(varargin, 'cfgfreq',     []);
cfgpreproc  = ft_getopt(varargin, 'cfgpreproc',  []);

%% get the filename of the dataset
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts, preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
  artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
<<<<<<< HEAD
  [data, speech] = computedata(dataset{1}, artfctcfg);
=======
  [data, speech] = computedata(dataset{1}, artfctcfg, cfgpreproc);
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
<<<<<<< HEAD
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg);
=======
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg, cfgpreproc);
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
    
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

<<<<<<< HEAD
%% convert to planar gradient
tmplabel = data.label;  % use later when combining planar gradient components

cfg = [];
cfg.method       = 'template';
cfg.neighbours   = ft_prepare_neighbours(cfg,data);
cfg.planarmethod = 'sincos';
dataPL           = ft_megplanar(cfg,data);

%% concatenate into one dataset
dataAX = ft_appenddata([],data,speech);  % axial gradiometers, for subj-specific frequency search
dataPL = ft_appenddata([],dataPL,speech);  % planar gradiometers, for grp-level averaging

%% cut the data into fragments with overlap (increase data - like welch method)
cfg = [];
cfg.length  = 2;  
cfg.overlap = 0.5; % 0 to 1 (exclusive)
dataAX = ft_redefinetrial(cfg, dataAX);
dataPL = ft_redefinetrial(cfg, dataPL);

%% divide data
cfg = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 5])); % sent
data1  = ft_selectdata(cfg,dataAX); % axial
data3  = ft_selectdata(cfg,dataPL); % planar

cfg.trials = find(ismember(data.trialinfo(:,2),[3 7])); % WL
data2  = ft_selectdata(cfg,dataAX); % axial
data4  = ft_selectdata(cfg,dataPL); % planar


%% calculate power- and cross-spectra
=======
%% convert to planar gradient if specified
tmplabel = data.label;  % use later when combining planar gradient components

if doplanar,
  cfg              = [];
  cfg.method       = 'template';
  cfg.neighbours   = ft_prepare_neighbours(cfg,data);
  cfg.planarmethod = 'sincos';
  dataPL           = ft_megplanar(cfg,data);
end

%% concatenate into one dataset
dataAX = ft_appenddata([],data,speech);  % axial gradiometers, for subj-specific frequency search
if doplanar, dataPL = ft_appenddata([],dataPL,speech);  end % planar gradiometers, for grp-level averaging

%% cut the data into fragments with overlap (increase data - like welch method)
cfg         = cfgredefine;
cfg.length  = ft_getopt(cfgredefine, 'length',  2);  
cfg.overlap = ft_getopt(cfgredefine, 'overlap', 0.5); % 0 to 1 (exclusive)
dataAX      = ft_redefinetrial(cfg, dataAX);
if doplanar, dataPL = ft_redefinetrial(cfg, dataPL); end

%% divide data according to the conditions word list / sentence
cfg        = [];
cfg.trials = find(ismember(dataAX.trialinfo(:,2),[1 5])); % sent
data1  = ft_selectdata(cfg,dataAX); % axial
if doplanar, data3  = ft_selectdata(cfg,dataPL); end % planar

cfg.trials = find(ismember(dataAX.trialinfo(:,2),[3 7])); % WL
data2  = ft_selectdata(cfg,dataAX); % axial
if doplanar, data4  = ft_selectdata(cfg,dataPL); end % planar

%% calculate spectral representation
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
%  mtmfft:   fourier spectra; contains amplitude and phase
%            Cross-spectral density matrix inferred from fourier matrix
%            (infer CSD from fourier coefficients)
%  powandcsd:  cross-spectra, power-spectra; 
<<<<<<< HEAD
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'powandcsd'; 
cfg.foilim     = foi;         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 1;           % 2 Hz smoothing
% cfg.tapsmofrq  = 2;         % 4 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';     
cfg.channel    = {'MEG' 'UADC003' 'audio_avg'};
cfg.channelcmb = {'MEG' 'UADC003';'MEG' 'audio_avg'};
freq1          = ft_freqanalysis(cfg,data1); % axial
freq2          = ft_freqanalysis(cfg,data2); 

freq3          = ft_freqanalysis(cfg,data3); % planar
freq4          = ft_freqanalysis(cfg,data4);
=======

cfg            = cfgfreq;
cfg.method     = 'mtmfft'; 
cfg.output     = 'powandcsd'; 
cfg.foilim     = foi;         % calculate fourier for each frequency showing a peak in coherence spectrum
%cfg.tapsmofrq  = 1;           % 2 Hz smoothing
cfg.tapsmofrq  = ft_getopt(cfg, 'tapsmofrq', 2);      
cfg.taper      = ft_getopt(cfg, 'taper',     'dpss');
cfg.pad        = ft_getopt(cfg, 'pad',       2);
cfg.channel    = {'MEG';'audio_avg'};
cfg.channelcmb = {'MEG' 'audio_avg'};
freq1          = ft_freqanalysis(cfg,data1); % axial
freq2          = ft_freqanalysis(cfg,data2); 
if doplanar,
  freq3          = ft_freqanalysis(cfg,data3); % planar
  freq4          = ft_freqanalysis(cfg,data4);
end
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78

%% calculate coherence 
cfg = [];
cfg.method     = 'coh';
cfg.channelcmb = {'MEG' 'UADC003'; 'MEG' 'audio_avg'}; % Specify channel and channelref
coherence1     = ft_connectivityanalysis(cfg,freq1); % axial
coherence2     = ft_connectivityanalysis(cfg,freq2);
<<<<<<< HEAD
coherence3     = ft_connectivityanalysis(cfg,freq3); % planar
coherence4     = ft_connectivityanalysis(cfg,freq4);

=======

fd1 = ft_freqdescriptives([], freq1);
fd2 = ft_freqdescriptives([], freq2);

if doplanar,
  coherence3     = ft_connectivityanalysis(cfg,freq3); % planar
  coherence4     = ft_connectivityanalysis(cfg,freq4);
  
  fd3 = ft_combineplanar([], ft_freqdescriptives([], freq3));
  fd4 = ft_combineplanar([], ft_freqdescriptives([], freq4));
end
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78

%% combine planar gradient's vertical (dV) and horizontal (dH) components
%  - Freq and Coherence calculation are non-linear (power = take abs)
%  - If combine components prior to freq/coherence calculation we lose
%  coherence estimate 
<<<<<<< HEAD
%  - Combining sensor_dV and sensor_dH using pythagoras leads to a loss
=======
%  - Combining sensor_dV and sensor_dH using pythagoras leads to coherencePeakdetect_stage2_thres001_smoothing_wl.mata loss
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
%  (canceling out) of the coherence estimate.  
%  - Use of pythagoras works for ERFs/TFRs signal; For ERF (because it's
%  caluclate is a linear step, one can actually convert and combine prior
%  to ERF calculation, but not for TFR and coherence calculations).
%  - Combine dV and dH components by doing an average. 
%    An alternative is to use max(dV, dH)

%%% SENT %%%
% select sensors of interest
<<<<<<< HEAD
sensize = size(coherence3.labelcmb,1)/4; % 273; dv and dH for each audio signal
tmp1 = coherence3.cohspctrm(sensize*2+1:sensize*3,:);
tmp2 = coherence3.cohspctrm(sensize*3+1:end,:);

% compute average between dV and dH for combined planar gradient components
coherence3.cohspctrm = (tmp1+tmp2)./2;
coherence3.labelcmb  = coherence3.labelcmb(sensize*2+1:sensize*3,:);
coherence3.labelcmb(1:sensize,1) = tmplabel;


%%% WORD LIST %%%
% select sensors of interest
sensize = size(coherence4.labelcmb,1)/4; % 273; dv and dH for each audio signal
tmp1 = coherence4.cohspctrm(sensize*2+1:sensize*3,:);
tmp2 = coherence4.cohspctrm(sensize*3+1:end,:);

% compute average between dV and dH for combined planar gradient components
coherence4.cohspctrm = (tmp1+tmp2)./2;
coherence4.labelcmb  = coherence4.labelcmb(sensize*2+1:sensize*3,:);
coherence4.labelcmb(1:sensize,1) = tmplabel;


function [data, speech] = computedata(dataset, artfctcfg)

%% define trial
cfg                   = [];
=======
if doplanar
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
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
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
<<<<<<< HEAD
=======
cfg.hpfilter = ft_getopt(cfg, 'hpfilter', 'yes');
cfg.hpfreq   = ft_getopt(cfg, 'hpfreq',   1);
cfg.hpfilttype = ft_getopt(cfg, 'hpfilttype', 'firws');
cfg.usefftfilt = ft_getopt(cfg, 'usefftfilt', 'yes');

>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
<<<<<<< HEAD
=======
cfg.hpfilttype = 'firws';
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
% cfg.boxcar     = 0.025;  % remove boxcar!
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
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);
