function [tlck, tlck_sent, tlck_seq, tlck_seq2] = mous_neuralspeechtimelocked_sensor(subjectname, ramp) %, varargin)

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

pre = 30;
pst = 659;

s.X        = 1;
params.pre = pre;
params.pst = pst;
params.tr_inds = p;
params.demean  = 'prezero';
[~,~,avg,cnt] = denoise_avg2(params,data.trial,s);

sel1  = find(ismember(data.trialinfo(:,2),[1 2 5 6]));
data1 = ft_selectdata(data, 'rpt', sel1);
params.tr_inds = p(sel1);
params.time    = data1.time;
[~,~,avg_sent,cnt_sent] = denoise_avg2(params,data1.trial,s);
sel2  = find(ismember(data.trialinfo(:,2),[3 4 7 8]));
data2 = ft_selectdata(data, 'rpt', sel2);
params.tr_inds = p(sel2);
params.time    = data2.time;
[~,~,avg_seq,cnt_seq]  = denoise_avg2(params,data2.trial,s);

% get the histograms of the inter-ramp intervals:
for k = 1:numel(p)
  D{k} = diff(p{k});
end
dp1 = cat(1,D{sel1});
dp2 = cat(1,D{sel2});
dp  = cat(1,D{:});

% now get the average from a subset of the wordlist ramps, where the next
% ramp is at least 1/3 seconds away
D = D(sel2); % subselect the word lists
for k = 1:numel(D)
  sel = find(D{k}>data2.fsample./3);
  params.tr_inds{k} = params.tr_inds{k}(sel);
end
[~,~,avg_seq2,cnt_seq2]  = denoise_avg2(params,data2.trial,s);

tlck       = [];
tlck.time  = (-pre:pst)./300;
tlck.grad  = data.grad;
tlck.label = data.label;
tlck.dimord = 'chan_time';
tlck.delta  = dp;

tlck.avg      = avg;
tlck.dof      = cnt;
tlck_sent     = tlck;
tlck_sent.avg = avg_sent;
tlck_sent.dof = cnt_sent;
tlck_sent.delta = dp1;
tlck_seq      = tlck;
tlck_seq.avg  = avg_seq;
tlck_seq.dof  = cnt_seq;
tlck_seq.delta = dp2; 
tlck_seq2      = tlck;
tlck_seq2.avg  = avg_seq2;
tlck_seq2.dof  = cnt_seq2;
tlck_seq2.delta = cat(1,D{:}); 

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
cfg.trl        = trl;%(1:100,:);
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
%cfg.bsfreq     = [49 51];
%cfg.bsfilttype = 'firws'; % windowed sinc FIR filter
cfg.bpfilter = 'yes';
cfg.bpfreq   = [1 40];
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

