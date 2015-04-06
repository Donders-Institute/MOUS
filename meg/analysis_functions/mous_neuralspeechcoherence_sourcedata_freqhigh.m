function [varargout] = mous_neuralspeechcoherence_sourcedata_freqhigh(subjectname,gamfoi,freq,varargin)
% mous_neuralspeechcoherence_sourcedata_high computes coherence at the
% source-level for gamma envelope.  Raw data is preprocessed once and then
% used for all coherence calculations
% gamfoi = gamma frequencies of interest
% foi = frequencies at which to calculate coherence between gamma envelope and speech envelope
% NL 02-04-2015

if nargin < 4
  datpp = [];
elseif nargin == 4
  datpp = varargin{1};
end

%% PREPROCESS DATA
if isempty(datpp)
  
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

% get envelope from neural data
cfg = [];
cfg.bpfilter   = 'yes';    
cfg.bpfreq     = gamfoi;  % coupling btw 35-45; lateralization 40 - 70
cfg.bpfilttype = 'firws';
% cfg.bpfiltdir  = % onepass-zerophase is set in ft_preproc_bandpassfilter.m
% cfg.bpfiltord  = % determined in ft_preproc_bandpassfilter.m
% cfg.bpfiltwintype = % default is hamming 
% cfg.bpfiltdf   = % default width heuristic used fir_df.m
cfg.hilbert    = 'abs';
datpp           = ft_preprocessing(cfg,datpp);  % Axial data,

% concatenate into one dataset
datpp = ft_appenddata([],datpp,speech);  % axial gradiometers, for subj-specific frequency search

% cut the data into fragments with overlap (increase data - like welch method)
cfg = [];
cfg.length  = 2;  
cfg.overlap = 0.5; % 0 to 1 (exclusive)
datpp = ft_redefinetrial(cfg, datpp);
end

%% SOURCE LEVEL  %%%%
[subj,~] = mous_db_getfilename('allA','subjectname');
load('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect_gammaenvelopecoh_stage2');
idx      = find(ismember(subj,subjectname));
switch freq
  case 'delta'
    freqcol = 1;
  case 'theta'
    freqcol = 2;
end
foi         = peakfreqfirst(idx,freqcol);

% calculate cross-spectral density matrix 
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'fourier'; % not 'powandcsd; compute csd online'
cfg.foi        = foi;         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 1;         % 2 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channel    = {'MEG' 'audio_avg'};
fourier        = ft_freqanalysis(cfg, datpp);

% load forward model (headmodel)
headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

% load sourcemodel   (grid); stick with 5798
mous_db_getdata(subjectname, 'meg_bfica_leadfield8mm', '/project/3011020.09/nielam/');

cfg = [];
cfg.method    = 'dics';
cfg.frequency = foi;
cfg.refchan   = 'audio_avg';
cfg.vol       = headmodel;
cfg.grid      = sourcemodel;
cfg.dics.fixedori   = 'yes';
cfg.dics.realfilter = 'yes';  % consider real+complex filter; complex may try to rotate back to 'original phase'
cfg.dics.keepfilter = 'yes'; 
cfg.dics.lambda     = '5%';
cfg.dics.projectnoise = 'yes';
cfg.grad            = fourier.grad;
source              = ft_sourceanalysis(cfg, fourier);

% return results
varargout{1} = source;
if nargout > 1
  varargout{2} = datpp;
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
cfg.trl        = trl;
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

