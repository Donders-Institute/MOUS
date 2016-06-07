function [freq] = mous_neuralspeechcoherence_evoke2freq(subj)

% Determine the peak in power spectrum of time-locked transients to onset of speech (sent) ramp
% Chapter 4 analysis part 2

mous_db_getdata(subj,'meg_erf_speech_tlck');
cfg = [];
% cfg.channel     = ft_channelselection({'MRT','MLT'},tlck.label);
cfg.latency     = [0 2-1./300];
% cfg.avgoverchan = 'yes'; 
tlck            = ft_selectdata(cfg,tlck_sent);

cfg = [];
cfg.method      = 'mtmfft';
cfg.output      = 'pow';
cfg.foilim      = [0 20];
cfg.taper       = 'hanning';
cfg.pad         = 2;
cfg.polyremoval = 1; % remove drift
freq       = ft_freqanalysis(cfg,tlck); 




