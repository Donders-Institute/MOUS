function [comp, comp1, comp2] = mous_neuralspeechcoherence_cca(subjectname, varargin)

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
  [data, audio] = computedata(dataset{1}, artfctcfg);
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [tmpdata, tmpaudio] = computedata(tmpdataset, tmpartfctcfg);
    
    if k==1,
      tmpsens1(k) = tmpdata.grad;
      weights1(k) = numel(tmpdata.trial);
      data       = tmpdata;
      
      tmpsens2(k) = tmpdata.grad;
      weights2(k) = numel(tmpdata.trial);
      audio     = tmpaudio;
    else
      % update the sentence counter
      tmpdata.trialinfo(:,1)  = tmpdata.trialinfo(:,1)   + data.trialinfo(end,1);
      tmpsens1(k)             = tmpdata.grad;
      weights1(k)             = numel(tmpdata.trial);
      data                    = ft_appenddata([], data, tmpdata);
      
      tmpaudio.trialinfo(:,1)  = tmpaudio.trialinfo(:,1) + audio.trialinfo(end,1);
      tmpsens2(k)              = tmpdata.grad;
      weights2(k)              = numel(tmpdata.trial);
      audio                    = ft_appenddata([], audio, tmpaudio);
    end
    
  end
  data.grad  = ft_average_sens(tmpsens1, 'weights', weights1);   
  audio.grad = ft_average_sens(tmpsens2, 'weights', weights2);   
end

% select the audio channel
cfg = [];
cfg.channel = audio.label(2:end);
audio = ft_selectdata(cfg,audio);

%% split conditions
cfg = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 5])); % sent
data1  = ft_selectdata(cfg,data); % axial
audio1 = ft_selectdata(cfg,audio);

cfg.trials = find(ismember(data.trialinfo(:,2),[3 7])); % WL
data2  = ft_selectdata(cfg,data); % axial
audio2 = ft_selectdata(cfg,audio);

%% compute cca
cfg = [];
cfg.method = 'bsscca';
cfg.updatesens = 'no';
cfg.cellmode   = 'yes';
cfg.bsscca.refdelay  = (0:3:300);
cfg.bsscca.prewhiten = true;
cfg.bsscca.chantol   = 1e-3;
cfg.bsscca.reftol    = 1e-2;
cfg.bsscca.refdata   = audio.trial;
comp = ft_componentanalysis(cfg, data);
cfg.bsscca.refdata   = audio1.trial;
comp1 = ft_componentanalysis(cfg, data1);
cfg.bsscca.refdata   = audio2.trial;
comp2 = ft_componentanalysis(cfg, data2);

% varargout{1} = coherence1;
% varargout{2} = coherence2;
% varargout{3} = coherence3;
% varargout{4} = coherence4;

%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION %%%%
function [data, audiodata] = computedata(dataset, artfctcfg)

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

%% preprocess neural data and audio audio file
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
audiodata      = ft_preprocessing(cfg);

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
  audiodata.trial{k}(2:(numel(audio.label)-1),:) = 0;
  audiodata.trial{k}(2:end,i3:i4) = audio.trial{1}(2:end-1,i1:i2);
  previous_sentid = sentid;
end
audiodata.label = [audiodata.label;audio.label(2:end-1)];

%% downsample
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
audiodata       = ft_resampledata(cfg,audiodata);

