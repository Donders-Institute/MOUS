function [data] = mous_preprocessing(filename, trl, resamplefs, analysisType)

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
    cfg.padding    = 4;
    
elseif (strcmp(analysisType, 'ERF') > 0)
    % ERF-specific parameters
%     cfg.lpfilter        = 'yes';   % apply lowpass filter
%     cfg.lpfreq          = 40;
%     cfg.lpfiltord       = 100;
%     cfg.lpfilttype      = 'fir';
%     
%     cfg.hpfilter        = 'yes';
%     cfg.hpfilttype      = 'fir'; 
%     cfg.hpfiltord       = 1800;  
%     cfg.hpfreq          = 0.5;
%     cfg.padding         = 4;    % big padding for hp to work   

    cfg.bpfilter   = 'yes';
    cfg.bpfilttype = 'fir';
    cfg.bpfiltord  = 600;
    cfg.bpfreq     = [0.5 40];
    cfg.padding    = 4;
    
    %cfg.padding = 4;
    %cfg.custom.funhandle = @ft_preproc_highpass_box;
    %cfg.custom.varargin  = 1200;
    
else
    error('unrecognized type requested');
end

data = ft_preprocessing(cfg);

%% Downsample data (to resamplefs = target frequency)

%   cfg.resamplefs = frequency at which the data will be resampled (default = 256 Hz)
%   cfg.detrend    = 'no' or 'yes', detrend the data prior to resampling (no default specified, see below)
%   cfg.demean     = 'no' or 'yes', baseline correct the data prior to resampling (default = 'no')
%   cfg.feedback   = 'no', 'text', 'textbar', 'gui' (default = 'text')
%   cfg.trials     = 'all' or a selection given as a 1xN vector (default =
%   'all')
cfg            = [];
cfg.resamplefs = resamplefs;
cfg.detrend    = 'no';  % not good for evoked data
cfg.demean     = 'yes';
cfg.trials     = 'all';
data = ft_resampledata(cfg, data);


%% Do ERF baseline correction AFTER downsampling.
%% so that different baselines can be applied.

cfg            = [];
cfg.channel    = {'MEG' 'EEG057' 'EEG058'};

if (strcmp(analysisType, 'TFR') > 0)
    cfg.detrend    = 'yes';
    
elseif (strcmp(analysisType, 'ERF') > 0)
    cfg.detrend    = 'no';
    cfg.demean     = 'yes';
    cfg.baselinewindow  = [-inf 0];
else
    error('unrecognized type requested');
    
end

data = ft_preprocessing(cfg, data);



