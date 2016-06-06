function [coh, dataorig] = mous_neuralspeechtimelocked_sensor_surrogate(tlck, delta, snr)

% MOUS_NEURALSPEECHTIMELOCKED_SENSOR_SURROGATE creates a surrogate MEG
% dataset, which is built as a temporal concatenation of ERFs.

if nargin==2,
  snr = 1;
end

if ischar(tlck)
  mous_db_getdata(tlck, 'meg_erf_speech_tlck');
  tlck = tlck_seq2;
  delta = tlck_sent.delta;
end

% get the template
cfg = [];
cfg.latency = [0 1-1./300]; % assume 300Hz sampling
tlck = ft_selectdata(cfg, tlck);

smp      = cumsum(delta);
impulses = zeros(1,max(smp));
impulses(smp) = 1;

dat = zeros(size(tlck.avg,1),max(smp));
for k = 1:size(tlck.avg,1)
  fprintf('convolving the impulses time series with the template for channel %s\n',tlck.label{k});
  dat(k,:) = convn(impulses, tlck.avg(k,:), 'same');
end

selmeg = match_str(tlck.label, ft_channelselection('MEG', tlck.label));
n      = norm(dat(selmeg,'fro'));

noise  = randn(numel(selmeg), size(dat,2)).*n./snr;
dat(selmeg,:) = dat(selmeg,:) + noise;

data.trial{1} = dat;
data.time{1}  = (0:size(dat,2)-1)./300;
data.label    = tlck.label;
dataorig = data;

cfg = [];
cfg.length  = 2;
cfg.overlap = 0.5;
data = ft_redefinetrial(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
%cfg.taper  = 'hanning';
cfg.tapsmofrq = 2;
cfg.foilim = [0 30];
freq = ft_freqanalysis(cfg, data);

cfg = [];
cfg.channelcmb = ft_channelcombination({'MEG' 'audio_avg'}, freq.label);
cfg.method     = 'coh';
coh = ft_connectivityanalysis(cfg, freq);


