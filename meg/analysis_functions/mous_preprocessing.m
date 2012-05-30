function [data] = mous_preprocessing(filename, trl, resamplefs)

cfg            = [];
cfg.dataset    = filename;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.dftfilter  = 'yes';
cfg.padding    = 5;
cfg.channel    = 'MEG';
data = ft_preprocessing(cfg);

cfg            = [];
cfg.resamplefs = resamplefs;
cfg.demean     = 'yes';
cfg.detrend    = 'no';
data = ft_resampledata(cfg, data);