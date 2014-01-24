function [freq] = mous_beamformer_freq(filename, trl)

% get the data
cfg.dataset    = filename;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.dftfilter  = 'yes';
cfg.padding    = 2;
cfg.channel    = 'MEG';
data = ft_preprocessing(cfg);

cfg        = [];
cfg.method = 'summary';
data       = ft_rejectvisual(cfg, data);

% spectral analysis
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
cfg.foilim = [2 30];
%cfg.tapsmofrq = 4;
%cfg.pad   = 1;
cfg.taper  = 'hanning';
freq       = ft_freqanalysis(cfg, data);
