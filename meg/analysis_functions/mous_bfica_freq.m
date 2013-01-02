function [freq] = mous_bfica_freq(subjectname, frequency, rootdir, options)

if nargin==1
  frequency = 20;
end

if nargin<3
  rootdir = '/home/language/jansch/public/mous/';
end

if nargin<4
  options.tapsmofrq  = 8;
  options.t_ftimwin  = 0.25;
  options.resamplefs = 200;
else
end
if isfield(options, 'tapsmofrq')
  tapsmofrq = options.tapsmofrq;
else
  tapsmofrq = 8;
end
if isfield(options, 't_ftimwin')
  t_ftimwin = options.t_ftimwin;
else
  t_ftimwin = 0.250;
end
if isfield(options, 'resamplefs')
  resamplefs = options.resamplefs;
else
  resamplefs = 200;
end

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg');
comp      = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_comp}', rootdir);
avgcomp   = comp{1};
avgpre    = comp{2};
comp      = comp{3};

cfg          = [];
cfg.dataset  = dataset{1};
%cfg.trialfun = 'trialfun_visual_sentence';
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = 0.3;
cfg.trialdef.poststim = 'nextword';
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 3 4]), 'partial', 1); % don't do the horizontal EOG

% trl > 2 second does not make sense, sanity check: FIXME
nsmp = trl(:,2)-trl(:,1);
trl  = trl(nsmp<2400,:);

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
cfg.resamplefs = resamplefs;
data           = ft_resampledata(cfg, data);

% reject cardiac components
v = var(avgcomp,[],2);
v = v./v(1);

% dummy trial to fool ft_rejectcomponent
comp.trial = comp.time;

cfg           = [];
cfg.component = find(v>0.1);
data          = ft_rejectcomponent(cfg, comp, data);

if frequency>=20 && frequency < 30
  % spectral analysis
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'fourier';
  %cfg.toi    = 0.125:0.025:0.625;
  cfg.toi    = -0.2:0.05:0.8;
  cfg.foi    = frequency;
  cfg.t_ftimwin = 0.250;
  %cfg.tapsmofrq = 8;
  cfg.taper = 'hanning';
  cfg.pad    = 10;
  freq       = ft_freqanalysis(cfg, data);
elseif frequency>=30
  % spectral analysis
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'fourier';
  %cfg.toi    = 0.125:0.025:0.625;
  cfg.toi    = -0.2:0.05:0.8;
  cfg.foi    = frequency;
  cfg.t_ftimwin = t_ftimwin;
  cfg.tapsmofrq = tapsmofrq;
  cfg.pad    = 4;
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
warning off;
freq = ft_struct2single(freq);

