function [polarity, threshold, p] = mous_bfica_ecg(subjectname)

% helper function to extract the polarity, threshold and ECG peaks. 

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_ds_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg');

cfg          = [];
cfg.dataset  = dataset{1};
cfg.trialfun = 'trialfun_visual_sentence';
%cfg.trialfun = 'trialfun_visual_word';
%cfg.trialdef.prestim  = 0;
%cfg.trialdef.poststim = 0.8;
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 3 4]), 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset{1};
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.padding    = 1.5;
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 4;
cfg.channel    = 'EEG059';
ecg            = ft_preprocessing(cfg);

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = 200;
ecg            = ft_resampledata(cfg, ecg);

% compute peak times for ecg
ecg = ft_channelnormalise([], ecg);
tmp = cat(2, ecg.trial{:});
%polarity = 2*(double(sum(tmp>4)>sum(tmp<-4))-0.5);
figure;plot(tmp);
s1 = input('polarity?','s');
s2 = input('threshold?','s');
close;

polarity = str2double(s1);
threshold = str2double(s2);

for k = 1:numel(ecg.trial)
  p{k} = peakdetect2(polarity*ecg.trial{k},threshold,100);
end
