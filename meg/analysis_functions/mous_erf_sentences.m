function [data] = mous_erf_sentences(subjectname, cond)

if nargin<2
  cond = 1;
end

if cond==1
  triggers = [1 2 5 6];
elseif cond==2
  triggers = [3 4 7 8];
elseif cond==3
  triggers = 1:8;
end

%% load raw data
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts, preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
  artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  [data, speech] = computedata(dataset{1}, artfctcfg, triggers);
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg, triggers);
    
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

data = ft_appenddata([], data, speech);


%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION %%%%
function [data, speech] = computedata(dataset, artfctcfg, triggers)

%% define trial
cfg                   = [];
cfg.dataset           = dataset;
if ~isempty(strfind(dataset, 'sub-2'))
  cfg.trialfun          = 'trialfun_auditory_sentence';
  cfg.trialdef.prestim  = 'audioonset';
  cfg.trialdef.poststim = 0.05;
else
%   cfg2 = cfg;
%   cfg2.trialfun = 'trialfun_visual_word';
%   cfg2.trialdef.prestim = 0;
%   cfg2.trialdef.poststim = 0.1;
%   cfg2 = ft_definetrial(cfg2);
%   
  cfg.trialfun          = 'trialfun_visual_sentence';
  cfg.trialdef.prestim  = 0;  
end
cfg = ft_definetrial(cfg);
cfg.trl = cfg.trl(ismember(cfg.trl(:,5),triggers),:);
cfg.trl(:,2) = min(cfg.trl(:,1)+12*1200,cfg.trl(:,2));

cfg.trl(:,1) = cfg.trl(:,1)-600;
cfg.trl(:,3) = cfg.trl(:,3)-600;


%% preprocess neural data and speech audio file
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
%cfg.bsfreq     = [49 51];
%cfg.bsfilttype = 'firws'; % windowed sinc FIR filter
cfg.bpfilter = 'yes';
cfg.bpfreq   = [0.5 20];
cfg.bpfilttype = 'firws';
cfg.padding    = 12;
cfg.usefftfilt = 'yes';
%cfg.hilbert    = 'abs';
data           = ft_preprocessing(cfg);

%tmpcfg = [];
%tmpcfg.boxcar = 0.250;
%data = ft_preprocessing(tmpcfg, data);

cfg.channel    = 'UADC003';
cfg.bpfilter   = 'no';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 12;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
%cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
speech         = ft_preprocessing(cfg);

if ~isempty(strfind(dataset, 's-2'))
  
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
else
  tmpcfg = [];
  tmpcfg.channel = data.label(1);
  speech = ft_selectdata(tmpcfg, data);
  speech.label = {'audio_avg'}; % just a dummy channel to make this work
end

% widen the scope of the eye artifacts a bit, because of the heavy
% filtering there may be a wider spread
tmp = artfctcfg{1}.artfctdef.zvalue.artifact;
tmp(:,1) = tmp(:,1) - 150;
tmp(:,2) = tmp(:,2) + 150;
artfctcfg{1}.artfctdef.zvalue.artifact = tmp;

%% define audio onset to be time point 0, and remove artifacts
data = mous_artifact_remove(data, dataset, artfctcfg, 'nan', 1); 


%% downsample, using a time axis that has 0, allowing for a good alignment
% between time axes
time = cell(1,numel(data.trial));
for k =1:numel(data.trial)
  idx0 = nearest(data.time{k},0);
  idx  = mod(idx0-1,10)+1;
  time{k} = data.time{k}(idx:10:end);
end

cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
%cfg.resamplefs  = 120;
cfg.time        = time;
speech          = ft_resampledata(cfg,speech);
%cfg.resamplemethod = 'downsample'; % assumes lpfilter to already be applied 
cfg.demean      = 'no';
cfg.method      = 'nearest'; % using interp1 when supplying a time axis requires this
data            = ft_resampledata(cfg,data);


