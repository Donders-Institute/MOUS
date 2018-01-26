function [source, data, leadfield] = mous_neuralspeechcoherence_source(subjectname, foi, varargin)

% This function calculates the coherence between the neural signal to the
% speech envelope at the source level, use this function instead of

if nargin < 2
  varargin = [];
  foi      = [];
end

cfgredefine = ft_getopt(varargin, 'cfgredefine', []);
cfgfreq     = ft_getopt(varargin, 'cfgfreq',     []);
cfgpreproc  = ft_getopt(varargin, 'cfgpreproc',  []);
condition   = ft_getopt(varargin, 'condition',   'sent');

if isempty(foi)
  mous_db_getdata(subjectname, 'meg_coh_sensor');
  switch condition
    case 'sent'
      foi = sentpeak(sentpeak<=10);
    case 'wl'
      foi = wlpeak(wlpeak<=10);
    case 'combined'
      error('no support for combined data with unspecified foi');
    otherwise
      error('no support for unspecified foi when the condition is not specified');
  end
  
  for k = 1:numel(foi)
    if k==1,
      [source, data, leadfield] = mous_neuralspeechcoherence_source(subjectname, foi(k), 'condition', condition);
    else
      source(k) = mous_neuralspeechcoherence_source(subjectname, foi(k), 'condition', condition, 'data', data, 'leadfield', leadfield);
    end
  end
  
  for k = 1:numel(source)
    source(k).cfg.callinfo.usercfg.grid = rmfield(source(k).cfg.callinfo.usercfg.grid,'leadfield');
  end
  
  return;
end


data        = ft_getopt(varargin, 'data');
leadfield   = ft_getopt(varargin, 'leadfield');

if isempty(data),
  %% get the filename of the dataset
  dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');
  
  %% define trials, remove artifacts, preprocess data
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
  cfg = [];
  switch condition,
    case 'sent'
      cfg.trials = find(ismember(data.trialinfo(:,2),[1 5])); % sent
    case 'wl'
      cfg.trials = find(ismember(data.trialinfo(:,2),[3 7])); % WL
    case 'combined'
      % no selection is needed
      cfg.trials = 'all';
    otherwise
  end
  data = ft_selectdata(cfg,data);
end

%% calculate spectral representation
cfgf            = cfgfreq;
cfgf.method     = 'mtmfft'; 
cfgf.output     = 'fourier'; 
cfgf.foilim     = foi + [-0.05 0.05];
cfgf.tapsmofrq  = ft_getopt(cfgf, 'tapsmofrq', 2);      
cfgf.taper      = ft_getopt(cfgf, 'taper',     'dpss');
cfgf.pad        = ft_getopt(cfgf, 'pad',       4);
cfgf.channel    = {'MEG';'audio_avg'};
cfgf.polyremoval = 1;
freq            = ft_freqanalysis(cfgf, data);

%% get the necessary geometric information
headmodel   = ft_datatype_headmodel(mous_db_getdata(subjectname, 'meg_anatomy_headmodel'));
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
sourcemodel.inside = true(8196,1);

if isempty(leadfield)
  cfg           = [];
  cfg.headmodel = headmodel;
  cfg.grid      = sourcemodel;
  cfg.channel   = 'MEG';
  leadfield     = ft_prepare_leadfield(cfg, freq);
end

cfg             = [];
cfg.method      = 'dics';
cfg.frequency   = foi;
cfg.refchan     = 'audio_avg';
cfg.headmodel   = headmodel;
cfg.grid        = leadfield;
cfg.grid.inside = true(8196,1);
cfg.dics.fixedori     = 'yes';
cfg.dics.realfilter   = 'yes';  
cfg.dics.keepfilter   = 'no'; 
cfg.dics.lambda       = '5%';
cfg.dics.projectnoise = 'yes';
cfg.grad      = freq.grad;
source        = ft_sourceanalysis(cfg,freq); 

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
cfg.hpfilter = ft_getopt(cfg, 'hpfilter', 'no');
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
