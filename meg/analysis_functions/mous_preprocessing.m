function [data] = mous_preprocessing(filename, trl, resamplefs, analysisType, baseline)

%% Preprocess data
% Created by AH, NL. 31-5-2012

%% Do filtering BEFORE down sampling
% define filter parameters common to TFR and ERFs
cfg            = [];
cfg.dataset    = filename;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.channel    = {'MEG' 'EEG057' 'EEG058'};


if (strcmp(analysisType, 'TFR') > 0)
    %TFR-specific parameters
    cfg.dftfilter  = 'yes';
    cfg.padding    = 5;
    
elseif (strcmp(analysisType, 'ERF') > 0)
    % ERF-specific parameters
    cfg.lpfilter        = 'yes';   % apply lowpass filter
    cfg.lpfreq          = 40;
    cfg.hpfilter        = 'yes';
    cfg.hpfilttype      = 'fir';  %not in Tinekes script
    cfg.hpfiltord       = 100;    %not in Tinekes script
    cfg.hpfreq          = 0.5;    %weired number  % tineke has 0.5
    cfg.padding         = 10;     %big padding for hp to work   
else
    error('unrecognized type requested');
end

data = ft_preprocessing(cfg);

%% Downsample data (to resamplefs = target frequency)
cfg            = [];
cfg.resamplefs = resamplefs;
cfg.detrend    = 'no';  % not good for evoked data
cfg.demean     = 'yes';
data = ft_resampledata(cfg, data);


%% Do ERF baseline correction and de-trending AFTER downsampling.
cfg            = [];

if (strcmp(analysisType, 'TFR') > 0)
    cfg.detrend    = 'yes';
    
elseif (strcmp(analysisType, 'ERF') > 0)
    cfg.demean     = 'yes';
    cfg.detrend    = 'no';
    cfg.baselinewindow  = [baseline 0];
else
    error('unrecognized type requested');
    
end

data = ft_preprocessing(cfg);



