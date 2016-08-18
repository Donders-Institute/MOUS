function [freq, freq_sent, freq_seq] = mous_neuralspeechtimelockeditc_sensor(subjectname, ramp) %, varargin)

if nargin<2
  ramp = 'up';
end

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

%% zscore and differentiate the speech signal
speechorig = speech;
for k = 1:numel(speech.trial)
  speech.trial{k} = ft_preproc_smooth(diff(speech.trial{k},[],2),5);
  speech.trial{k}(:,end) = speech.trial{k}(:,end-1);
end
speech.trial = zscore(speech.trial, [], 2);

if strcmp(ramp, 'up')
  %% find the 'up'-ramps
  for k = 1:numel(speech.trial)
    p{1,k} = peakdetect2(speech.trial{k}(2,:),1,15)';
  end
elseif strcmp(ramp, 'down')
  %% find the 'down'-ramps
  for k = 1:numel(speech.trial)
    p{1,k} = peakdetect2(-speech.trial{k}(2,:),1,15)';
  end
end

data = ft_appenddata([], data, speechorig);

s.X        = 1;
params.pre = 150;
params.pst = 659;
params.tr_inds = p;
params.demean  = 'prezero';
params.computenew = 0;
params.fsample = 300;
params.time = data.time;
params.timeoi = -0.25:0.01:2;
params.freqoi = 2:2:40;
params.timwin = 5./params.freqoi;
params.output = 'itc';
params.nrand = 10;

[~,~,avg,~,shuf,pval] = denoise_avg_spectrogram(params,data.trial,s);

sel1  = find(ismember(data.trialinfo(:,2),[1 2 5 6]));
data1 = ft_selectdata(data, 'rpt', sel1);
params.tr_inds = p(sel1);
params.time    = data1.time;
[~,~,avg_sent,~,shufsent,psent] = denoise_avg_spectrogram(params,data1.trial,s);
sel2  = find(ismember(data.trialinfo(:,2),[3 4 7 8]));
data2 = ft_selectdata(data, 'rpt', sel2);
params.tr_inds = p(sel2);
params.time   = data2.time;
[~,~,avg_seq,~,shufseq,pseq] = denoise_avg_spectrogram(params,data2.trial,s);

freq       = [];
freq.time  = params.timeoi;
freq.freq  = params.freqoi;
freq.grad  = data.grad;
freq.label = data.label;
freq.dimord = 'chan_freq_time';

freq.powspctrm = avg;
freq.powspctrmshuf = shuf;
freq.p        = pval;
freq_sent     = freq;
freq_sent.powspctrm = avg_sent;
freq_sent.powspctrmshuf = shufsent;
freq_sent.p   = psent;
freq_seq      = freq;
freq_seq.powspctrm  = avg_seq;
freq_seq.powspctrmshuf = shufseq;
freq_seq.p             = pseq;

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
cfg.trl        = trl;%(1:40,:);
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
%cfg.bsfreq     = [49 51];
%cfg.bsfilttype = 'firws'; % windowed sinc FIR filter
cfg.bpfilter = 'yes';
cfg.bpfreq   = [0.1 80];
cfg.bpfilttype = 'firws';
%cfg.padding    = 10;
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

