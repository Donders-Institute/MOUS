function [freq] = mous_bfica_freq_mtmfft(subjectname, frequency, rootdir, options)

if nargin<3
  rootdir = '/home/language/jansch/public/mous/';
end

if nargin<4
  options.tapsmofrq  = 8;
  options.resamplefs = 600;
else
end
if isfield(options, 'tapsmofrq')
  tapsmofrq = options.tapsmofrq;
else
  tapsmofrq = 4;
end
if isfield(options, 'resamplefs')
  resamplefs = options.resamplefs;
else
  resamplefs = 300;
end
if isfield(options, 'taper')
  taper = options.taper;
else
  taper = 'dpss';
end
if isfield(options, 'toilim')
  toilim = options.toilim;
else
  toilim = [0.2 0.6];
end
% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg');

cfg          = [];
cfg.dataset  = dataset{1};
%cfg.trialfun = 'trialfun_visual_sentence';
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = -toilim(1);
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
cfg.padding    = 5;
if any(frequency>45)
  cfg.dftfilter  = 'yes';
  cfg.dftfreq    = [(245:255)./5 (495:505)./5 (745:755)./5]';
end
data           = ft_preprocessing(cfg);

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = resamplefs;
data           = ft_resampledata(cfg, data);

cfg = [];
cfg.toilim    = [toilim(1) toilim(2)-1/resamplefs];
cfg.minlength = diff(toilim);
data = ft_redefinetrial(cfg, data);


% spectral analysis
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
if numel(frequency)==2
  cfg.foilim = frequency;
else
  cfg.foi = frequency;
end
cfg.tapsmofrq = tapsmofrq;
cfg.taper  = taper;
freq       = ft_freqanalysis(cfg, data);
warning off;
freq = ft_struct2single(freq);

