dataset = '/home/coherence/jansch/MOUS/data/p001BigUmVis_600hz_20110818_01.ds';

cfg = [];
cfg.dataset  = dataset;
cfg.trialfun = 'chop1000ms';
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

% sanity check: recover the trials which show the strange spectral
% artifacts
cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.keeptrials = 'yes';
cfg.foilim = [1 100];
cfg.taper = 'hanning';
freq = ft_freqanalysis(cfg, data);





trl  = cfg.trl;
[cfg1, cfg2] = detect_blinks(data, trl);

cfg.artfctdef.eog    = cfg1.artfctdef.eog;
cfg.artfctdef.eog2   = cfg2.artfctdef.eog;
cfg.artfctdef.reject = 'complete';
data                 = ft_rejectartifact(cfg, data);


cfg = [];
cfg.resamplefs = 300;
cfg.demean = 'yes';
cfg.detrend = 'no';
data = ft_resampledata(cfg, data);

cfg = [];
cfg.method = 'summary';
data = ft_rejectvisual(cfg, data);


cfg.channel = {'MEGREF' '-B*'};
%cfg.dftfilter = 'yes';
%cfg.dftinvert = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfilttype = 'fir';
cfg.bpfiltord  = 100;
cfg.bpfreq   = [48 52;98 102];
cfg.padding = 4;
refdata = ft_preprocessing(cfg);

cfg = [];
cfg.detrend    = 'no';
cfg.demean     = 'yes';
refdata = ft_resampledata(cfg, refdata);

dataorig = data;

cfg = [];
cfg.truncate = 3;
data = ft_denoise_pca(cfg, dataorig, refdata);

cfg = [];
cfg.method = 'summary';
data = ft_rejectvisual(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.keeptrials = 'no';
cfg.foilim = [0 100];
cfg.tapsmofrq = 4;
cfg.trials = find(data.trialinfo==1);
freq1 = ft_freqanalysis(cfg, data);
cfg.trials = find(data.trialinfo==3);
freq3 = ft_freqanalysis(cfg, data);
cfg.trials = find(data.trialinfo==5);
freq5 = ft_freqanalysis(cfg, data);
cfg.trials = find(data.trialinfo==7);
freq7 = ft_freqanalysis(cfg, data);
