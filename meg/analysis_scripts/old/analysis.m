dataset = '/home/coherence/jansch/MOUS/data/p001BigUmVis_600hz_20110818_01.ds';

cfg = [];
cfg.dataset  = dataset;
cfg.trialfun = 'firstword';
cfg = ft_definetrial(cfg);

cfg.channel   = {'MEG' 'EEG057' 'EEG058'};
cfg.demean    = 'yes';
%cfg.dftfilter = 'yes';
% cfg.hpfilter  = 'yes';
% cfg.hpfreq    = 1;
% cfg.hpfilttype = 'fir';
% cfg.hpfiltord = 100;
% cfg.padding   = 5;
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

cfg.channel = {'MEGREF' '-B*'};
%cfg.dftfilter = 'yes';
%cfg.dftinvert = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfilttype = 'fir';
cfg.bpfiltord  = 100;
cfg.bpfreq   = [48 52;98 102];
cfg.padding = 4;
refdata = ft_preprocessing(cfg);

dataorig = data;

% cfg = [];
% cfg.truncate = 3;
% cfg.shift    = (-2:2);
% data = ft_denoise_tsr(cfg, dataorig, refdata);

cfg = [];
cfg.resamplefs = 300;
cfg.detrend    = 'yes';
data = ft_resampledata(cfg, data);

cfg = [];
cfg.method = 'summary';
data = ft_rejectvisual(cfg, data);

cfg = [];
cfg.toilim = [-0.5 0-1/300];
pre = ft_redefinetrial(cfg, data);
cfg.toilim = [0.25 0.75-1/300];
pst = ft_redefinetrial(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.keeptrials = 'yes';
cfg.foilim = [0 100];
cfg.tapsmofrq = 4;
%cfg.taper = 'hanning';
freqpre = ft_freqanalysis(cfg, pre);
freqpst = ft_freqanalysis(cfg, pst);
