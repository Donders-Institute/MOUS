function [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname)

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_ds_task');
artfctcfg = mous_db_getdata(subjectname, 'meg_processed_{artifactcfg}');

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
cfg.channel    = 'MEG';
data           = ft_preprocessing(cfg);

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
data           = ft_resampledata(cfg, data);

% compute peak times for ecg
ecg = ft_channelnormalise([], ecg);
tmp = cat(2, ecg.trial{:});
polarity = 2*(double(sum(tmp>4)>sum(tmp<-4))-0.5);
for k = 1:numel(ecg.trial)
  p{k} = peakdetect2(polarity*ecg.trial{k},4,1);
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
comp = rmfield(comp, 'trial');
