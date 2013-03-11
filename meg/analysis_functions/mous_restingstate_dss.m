function [comp, avgpre, avgcomp] = mous_restingstate_dss(data)

cfg = [];
cfg.channel = 'EEG059';
ecg = ft_preprocessing(cfg, data);

% compute peak times for ecg
ecg = ft_channelnormalise([], ecg);
tmp = cat(2, ecg.trial{:});
%polarity = 2*(double(sum(tmp>3.5)>sum(tmp<-3.5))-0.5);
figure;plot(tmp);
s1 = input('polarity?','s');
s2 = input('threshold?','s');
close;

polarity = str2double(s1);
threshold = str2double(s2);
for k = 1:numel(ecg.trial)
  p{k} = peakdetect2(polarity*ecg.trial{k},threshold,1);
end
paramscell.tr = p;
paramscell.pre = 0.25*ecg.fsample;
paramscell.pst = 0.50*ecg.fsample;
paramscell.demean = true;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = paramscell;
cfg.dss.wdim          = 75;
cfg.numcomponent      = 10;
cfg.channel           = 'MEG';
cfg.cellmode          = 'yes';
comp                  = ft_componentanalysis(cfg, data);

s.state = 1;
[~,~,avgcomp] = denoise_avg2(paramscell, comp.trial, s);
[~,~,avgpre]  = denoise_avg2(paramscell, data.trial, s);
