
function [trl] = mous_defineTrial(filename, prestim, poststim)


cfg = [];
cfg.dataset           = filename;
cfg.trialdef.prestim  = prestim;              % baseline
cfg.trialdef.poststim = poststim-1./1200;      % pad
cfg.trialfun          = 'visual_word';    % 1s duration from onset of target word
[cfg]                 = ft_definetrial(cfg);      % ft_definetrial defines trials which are created in cfg.trl which is a parameter for ft_preprocessing
trl                   = cfg.trl;