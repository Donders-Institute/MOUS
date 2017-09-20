function [mi] = mous_neuralspeech_mi(subjectname)

%% get name of the datafile
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

% get planar gradients
cfg = [];
cfg.method = 'template';
cfg.template = 'CTF275_neighb.mat';
neighb = ft_prepare_neighbours(cfg);

cfg = [];
cfg.method = 'sincos';
cfg.neighbours = neighb;
data = ft_megplanar(cfg, data);


% get the sentence trials
cfg = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 5]));
data = ft_selectdata(cfg, data);

% set the cfgs
cfgf = [];
cfgf.bpfilter = 'yes';
cfgf.bpfilttype = 'firws';

cfgc = [];
cfgc.method = 'svd';

cfgh = [];
cfgh.hilbert = 'angle';

cfg = [];
cfg.method = 'mi';
<<<<<<< HEAD
cfg.mi.lags = (-0.7:0.1:0.7);

freqs = [linspace(0.5,16,20);linspace(1,20,20);linspace(1.5,24,20)];
for k = 1:size(freqs,2)
=======
cfg.mi.lags = 0;(-0.7:0.1:0.7);
cfg.mi.method = 'gcmi';

freqs = [linspace(0.5,16,20);linspace(1,20,20);linspace(1.5,24,20)];
for k = 2%1:size(freqs,2)
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
  cfgf.bpfreq = freqs([1 3],k)';

  tmp       = ft_preprocessing(cfgf, data);
  tmpspeech = ft_preprocessing(cfgf, speech);
  
  tmp         = ft_appenddata([], tmp, tmpspeech);
  cfg.refindx = match_str(tmp.label, 'audio_avg');

  mi(k)       = ft_connectivityanalysis(cfg,ft_preprocessing(cfgh, tmp));
end



function [data, speech] = computedata(dataset, artfctcfg)

%% define trial
cfg                   = [];
cfg.dataset           = dataset;
cfg.trialfun          = 'trialfun_auditory_sentence';
cfg.trialdef.prestim  = 'audioonset';
cfg.trialdef.poststim = 0; % DIFFERENT FROM COHERENCE FUNCTION
cfg = ft_definetrial(cfg);

%% define audio onset to be time point 0, and remove artifacts
trl = cfg.trl;
trl(:,3) = 0;
trl = mous_artifact_remove(trl, dataset, artfctcfg, 'partial', 1); 


%% select only the sentence chunks
trl = trl(ismember(trl(:,5),[1 5]),:); % DIFFERENT FROM COHERENCE

%% preprocess neural data and speech audio file
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
% cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
% cfg.bsfreq     = [49 51];
% cfg.bsfilttype = 'firws';
% cfg.usefftfilt = 'yes';
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
cfg.resamplefs  = 150;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);
