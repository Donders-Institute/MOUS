function [trl, sel] = mous_defineTrial(filename, prestim, poststim, trialfun)

[p,f,e] = fileparts(filename);
tok     = tokenize(trialfun, '_');
if strcmp(f(1:5), 'A2036') && any(strcmp(tok, 'auditory')) && any(strcmp(tok, 'word'))
 % use a slightly modified version of the trialfun 
 trialfun = [trialfun,'_A2036'];
end

if ischar(poststim)
else
  poststim = poststim-1./1200; % adjust to make for a nice number of samples
end

cfg                   = [];
cfg.dataset           = filename;
cfg.trialdef.prestim  = prestim;      % baseline
cfg.trialdef.poststim = poststim;     % pad
cfg.trialfun          = trialfun;             % 'visual_word' or 'visual_sentence'
[cfg]                 = ft_definetrial(cfg);  % ft_definetrial defines trials which are created in cfg.trl which is a parameter for ft_preprocessing
trl                   = cfg.trl;

