function [data] = mous_preprocessing(filename, trl, resamplefs, analysisType, baseline)

% Created by AH, NL. 31-5-2012

%% preprocess data
% define filter parameters common to TFR and ERFs
cfg            = [];
cfg.dataset    = filename;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';

% TFR-specific parameters 
if (strcmp(analysisType, 'TFR') > 0)
cfg.dftfilter  = 'yes';
cfg.padding    = 5;

% ERF-specific parameters
elseif (strcmp(analysisType, 'ERF') > 0)
cfg.baselinewindow  = [baseline 0];
cfg.lpfilter   = 'yes';   % apply lowpass filter
cfg.lpfreq     = 40;
cfg.hpfilter = 'yes';
cfg.hpfilttype = 'fir';  %not in Tinekes script
cfg.hpfiltord  = 100;   %not in Tinekes script
cfg.hpfreq = 0.5; %wired number  % tineke has 0.5
cfg.padding = 10; %big padding for hp to work 
      
else
    error('unrecognized type requested');
end

data = ft_preprocessing(cfg);

%% downsample data (to resamplefs = target frequency)

cfg            = [];
cfg.resamplefs = resamplefs;
cfg.demean     = 'yes';
cfg.detrend    = 'no';
data = ft_resampledata(cfg, data);
      