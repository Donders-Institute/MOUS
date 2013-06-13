function [freq] = mous_bfica_freqbaseline(subjectname, rootdir, options)

if nargin<2
  rootdir = '/home/language/jansch/public/mous/';
end

if nargin<3
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
  resamplefs = 300;
end
if isfield(options, 'taper')
  taper = options.taper;
else
  taper = 'dpss';
end
% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg');
comp      = mous_db_getdata(subjectname, 'meg_bfica_comp', rootdir);
avgcomp   = comp{1};
avgpre    = comp{2};
comp      = comp{3};


% HACK otherwise crash 
tmp=~isfinite(comp.grad.tra);
sel=sum(tmp,1);
sel2=sum(tmp,2);
comp.grad.tra(sel2>0,sel>0)=randn(sum(sel2>0),sum(sel>0));
comp.grad = rmfield(comp.grad,'balance');

cfg          = [];
cfg.dataset  = dataset{1};
cfg.trialfun = 'trialfun_visual_sentence';
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl(:,2)     = trl(:,1)+1199;
trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 2 3 4]), 'partial', 0.5); % don't do the horizontal EOG

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

% spectral analysis
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
cfg.tapsmofrq = tapsmofrq;
cfg.foilim = [0 40];
cfg.taper  = taper;
cfg.pad    = 1;
freq       = ft_freqanalysis(cfg, data);
warning off;
%freq = ft_struct2single(freq);

