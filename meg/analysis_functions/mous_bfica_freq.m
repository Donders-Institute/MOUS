function [freq] = mous_bfica_freq(subjectname, frequency)

if nargin==1
  frequency = 20;
end

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_ds_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_processed_{artifactcfg}');
comp      = mous_db_getdata(subjectname, 'meg_processed_{bfICA_comp}');
avgcomp   = comp{1};
avgpre    = comp{2};
comp      = comp{3};

cfg          = [];
cfg.dataset  = dataset{1};
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = 0;
cfg.trialdef.poststim = 0.8;
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 3 4]), 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset{1};
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
data           = ft_preprocessing(cfg);

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = 200;
data           = ft_resampledata(cfg, data);

% reject cardiac components
v = var(avgcomp,[],2);
v = v./v(1);

% dummy trial to fool ft_rejectcomponent
comp.trial = comp.time;

cfg           = [];
cfg.component = find(v>0.1);
data          = ft_rejectcomponent(cfg, comp, data);

if frequency>=20
  % spectral analysis
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'fourier';
  cfg.toi    = 0.125:0.025:0.625;
  cfg.foi    = frequency;
  cfg.t_ftimwin = 0.250;
  cfg.tapsmofrq = 8;
  cfg.pad    = 1;
  freq       = ft_freqanalysis(cfg, data);
else
  % spectral analysis
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'fourier';
  cfg.toi    = 0.2:0.025:0.6;
  cfg.foi    = frequency;
  cfg.t_ftimwin = 0.40;
  %cfg.tapsmofrq = 8;
  cfg.taper  = 'hanning';
  cfg.pad    = 1;
  freq       = ft_freqanalysis(cfg, data);
end
