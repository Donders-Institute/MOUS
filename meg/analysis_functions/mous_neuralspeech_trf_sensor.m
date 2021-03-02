function [tlck, tlck_sent, tlck_seq, trf_all, trf_sent, trf_seq, data, speech] = mous_neuralspeech_trf_sensor(subjectname, refchan, lambda)

if nargin<2 || isempty(refchan)
  refchan = {'audio_avg'};
end

if nargin<3 || isempty(lambda)
  lambda = 10;
end

%% load raw data
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts, preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg');
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

if any(contains(refchan, 'stimon'))
  out    = addstimchan(speech, 'aud');
  speech = ft_appenddata([], speech, out);
  speech.label{end} = 'stimon';
end

nfold = 5;
ix    = round(linspace(0,numel(data.trial),nfold+1));
N     = randperm(numel(data.trial));
for k = 1:numel(ix)-1
  testtrials{1,k} = sort(N((ix(k)+1):ix(k+1)));
end

reflags = (-6:180)./300; % consider making this configureable

if numel(lambda)>1 && numel(refchan)==numel(lambda)
  % this suggests a reference channel specific lambda, unfold this for all
  % lags, so that the threshold cfg argument is nrefchan x nlag + 1 (the
  % first element coincides with the dependent variable, and should be 0.
  % the lambda values are assumed to coincide with the order of the
  % refchans
  lambda = [0 repmat(lambda(:)', 1, numel(reflags))];
else 
  lambda = [lambda 0];
end

cfg             = [];
cfg.method      = 'mlrridge';
cfg.refchannel  = refchan;
cfg.reflags     = reflags; 
cfg.threshold   = lambda;
cfg.feedback    = 'text';
cfg.standardiserefdata = true;
cfg.standardisedata    = true;
cfg.demeanrefdata      = true;
cfg.demeandata         = true;
cfg.testtrials         = testtrials;
trf_all         = ft_denoise_tsr(cfg, data, speech);
weights_all     = cat(4, trf_all.weights.beta); % diag(trf_all.weights.rho)*trf_all.weights.beta;

cfgs        = [];
cfgs.trials = find(ismember(data.trialinfo(:,2),[1 5]));
data_       = ft_selectdata(cfgs, data);
speech_     = ft_selectdata(cfgs, speech);

ix    = round(linspace(0,numel(data_.trial),nfold+1));
N     = randperm(numel(data_.trial));
for k = 1:numel(ix)-1
  testtrials{1,k} = sort(N((ix(k)+1):ix(k+1)));
end
cfg.testtrials = testtrials;

trf_sent        = ft_denoise_tsr(cfg, data_, speech_);
weights_sent    = cat(4, trf_sent.weights.beta); % diag(trf_sent.weights.rho)*trf_sent.weights.beta;

cfgs.trials = find(ismember(data.trialinfo(:,2),[3 7]));
data_       = ft_selectdata(cfgs, data);
speech_     = ft_selectdata(cfgs, speech);

ix    = round(linspace(0,numel(data_.trial),nfold+1));
N     = randperm(numel(data_.trial));
for k = 1:numel(ix)-1
  testtrials{1,k} = sort(N((ix(k)+1):ix(k+1)));
end
cfg.testtrials = testtrials;

trf_seq         = ft_denoise_tsr(cfg, data_, speech_);
weights_seq     = cat(4,trf_seq.weights.beta); % diag(trf_seq.weights.rho)*trf_seq.weights.beta;

tlck       = [];
tlck.time  = trf_all.weights.time;
tlck.grad  = data.grad;
tlck.label = data.label;
tlck.dimord = 'chan_time';
tlck.avg   = weights_all;
tlck.rho   = cat(2, trf_all.weights.rho);

tlck_sent       = [];
tlck_sent.time  = trf_seq.weights.time;
tlck_sent.grad  = data.grad;
tlck_sent.label = data.label;
tlck_sent.dimord = 'chan_time';
tlck_sent.avg   = weights_sent;
tlck_sent.rho   = cat(2, trf_sent.weights.rho);
%weights    = weights_sent;
%tlck_sent.avg   = (squeeze(weights.W{1}(end-1:-1:1,:,:))*diag(weights.rho)*diag(1./squeeze(weights.W{2}))*diag(weights.zscore.s))';

tlck_seq       = [];
tlck_seq.time  = trf_seq.weights.time;
tlck_seq.grad  = data.grad;
tlck_seq.label = data.label;
tlck_seq.dimord = 'chan_time';
tlck_seq.avg   = weights_seq;
tlck_seq.rho   = cat(2, trf_seq.weights.rho);

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
cfg.trl        = trl;%(1:50,:);
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
%cfg.bsfreq     = [49 51];
%cfg.bsfilttype = 'firws'; % windowed sinc FIR filter
cfg.bpfilter = 'yes';
cfg.bpfreq   = [.5 30];
cfg.bpfilttype = 'firws';
cfg.padding    = 15;
cfg.usefftfilt = 'yes'; 
data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.bpfilter   = 'no';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
speech         = ft_preprocessing(cfg);

% load in the audioenvelopes as constructed from the wav files.
previous_sentid = 0;
for k = 1:numel(data.trial)
  sentid = num2str(data.trialinfo(k,5),'%03d');
  if ~strcmp(previous_sentid,sentid)
    load(fullfile('/project/3011020.09/misc/audiostimuli',['audiodata_envelope',sentid]));
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

