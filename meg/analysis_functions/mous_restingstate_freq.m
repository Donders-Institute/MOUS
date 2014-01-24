function [freq] = mous_restingstate_freq(data, options)

if nargin<2
  options.tapsmofrq  = 1;
  options.length     = 2;
  options.overlap    = 0.5;
else
end
if isfield(options, 'tapsmofrq')
  tapsmofrq = options.tapsmofrq;
else
  tapsmofrq = 1;
end
if isfield(options, 'length')
  length = options.length;
else
  length = 2;
end
if isfield(options, 'overlap')
  overlap = options.overlap;
else
  overlap = 0.5;
end

% redefine
cfg         = [];
cfg.length  = length;
cfg.overlap = overlap;
data = ft_redefinetrial(cfg, data);

% spectral analysis
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
cfg.foilim = [0 40];
cfg.tapsmofrq = tapsmofrq;
freq = ft_freqanalysis(cfg, data);
