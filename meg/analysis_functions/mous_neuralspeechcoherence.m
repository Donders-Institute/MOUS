function mous_neuralspeechcoherence(subj)

% This function calculates the coherence between the neural signal to the
% speech envelope

%% load raw data
dataset   = mous_db_getfilename(subj, 'meg_raw_task');

%% define trial
cfg                   = [];
cfg.dataset           = dataset{1};
cfg.trialfun          = 'trialfun_auditory_sentence';
cfg.trialdef.prestim  = 'audioonset';
cfg.trialdef.poststim = 0.2;
cfg = ft_definetrial(cfg);

% remove artifacts
% trialinfo holds .wav filename
trl = cfg.trl;
mous_db_getdata(subj,'meg_artifact_cfg','/project/3011020.09/MEG/');
artfctcfg = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
trl = mous_artifact_remove(trl, dataset{1}, artfctcfg, 'partial', 1); % don't do the horizontal EOG

%% preprocess neural data and speech audio file
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
cfg.bsfreq     = [49 51];
cfg.bsfilttype = 'firws';
% cfg.bsfiltdev  = 0.001;
% cfg.dftfilter  = 'yes'; 
% cfg.padding    = 2;     % duration: length of trial + extra on each side;  trial length varies...
data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
cfg.boxcar     = 0.025;  % can't find as a cfg option in ft_preprocessing.
speech         = ft_preprocessing(cfg);

%% downsample
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'yes';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);


%% concatenate into one dataset
%  there should now be all MEG (+EEG) channels and one speech channel
data = ft_appenddata([],data,speech);

%% cut the data into 2 second fragments to make life easier later on
cfg.length = 2;
cfg.overlap = 0.5;
data = ft_redefinetrial(cfg, data);


%% calculate power- and cross-spectra
%  mtmfft:     fourier spectra; contains amplitude and phase
%  powandcsd:  cross-spectra, power-spectra; 
%  MOUS used mtmconvol and only returned 'fourier' -> calculate pow, csd
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'powandcsd';
cfg.foilim     = [2 60];
cfg.tapsmofrq  = 1;         % 2 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channelcmb = {'MEG' 'UADC003'};
freqlow        = ft_freqanalysis(cfg,data);

cfg.foilim     = [60 100];
cfg.taper      = 'dpss';
cfg.tapsmofrq  = 4;
freqhigh       = ft_freqanalysis(cfg,data);

%% calculate coherence
cfg = [];
cfg.method    = 'coh';
coherencelow  = ft_connectivityanalysis(cfg,freqlow);
coherencehigh = ft_connectivityanalysis(cfg,freqhigh);

mous_db_putdata(subj,'meg_other_neuralspeechenvecoh','coherencelow','coherencehigh','/project/3011020.09/MEG/',1);

% beamform coherence data


%% getting .wav files relevant to subject
cfg                  = [];
cfg.parameter        = 'cohspctrm';
% cfg.xlim             = [5 40];
% cfg.ylim             = [0 0.2];
cfg.refchannel       = 'UADC003';
cfg.layout           = 'CTF275.lay';
% cfg.showlabels       = 'yes';
figure; ft_multiplotER(cfg, coherencelow)


% look at word-list to neural
figure;
subplot(2,1,1)
plot(data.time{10},data.trial{10}(109,:))
legend(data.label(109))
subplot(2,1,2);
plot(data.time{10},data.trial{10}(274,:));
axis tight;
legend(data.label(274));
title('trial 1 - woorden');

% look at sentence  to neural
figure;
subplot(2,1,1)
plot(data.time{11},data.trial{11}(109,:))
legend(data.label(109))
subplot(2,1,2);
plot(data.time{11},data.trial{11}(274,:));
axis tight;
legend(data.label(274));
title('trial 6 - zinnen');

%% tutorial
cfg            = [];
cfg.output     = 'fourier';
cfg.method     = 'mtmfft';
cfg.foilim     = [18 18];
cfg.tapsmofrq  = 5;
cfg.keeptrials = 'yes';
cfg.channel    = {'MEG' 'EMGlft' 'EMGrgt'};
freqf   = ft_freqanalysis(cfg, data);


cfg            = [];
cfg.output     = 'powandcsd';
cfg.method     = 'mtmfft';
cfg.foilim     = [18 18];
cfg.tapsmofrq  = 5;
cfg.keeptrials = 'yes';
cfg.channel    = {'MEG' 'EMGlft' 'EMGrgt'};
cfg.channelcmb = {'MEG' 'EMGlft'; 'MEG' 'EMGrgt'};
freq           = ft_freqanalysis(cfg, data);