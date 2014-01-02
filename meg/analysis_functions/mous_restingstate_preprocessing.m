function [data, ecg] = mous_restingstate_preprocessing(subjectname, rootdir, options)

if nargin<2
  rootdir = '/project/3011020.09/MEG/';
end

if nargin<3
  options = [];
else
end
resamplefs = ft_getopt(options, 'resamplefs', 200);

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_rest');
mous_db_getdata(subjectname, 'meg_artifact_cfg_restingstate',rootdir);

cfg          = [];
cfg.dataset  = dataset{1};
trl          = [2401 357600 0];
trl          = mous_artifact_remove(trl, dataset{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle}, 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset{1};
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.dftfilter  = 'yes';
%cfg.dftfreq    = [50 100 150 200 250];
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 0.5;
cfg.hpfiltord  = 2;
cfg.padding    = 5;
data           = ft_preprocessing(cfg);
cfg.channel    = {'EEG059'};
ecg            = ft_preprocessing(cfg);

% change time axis per trial, to facilitate the resampling step: time carries no info here
for k = 1:numel(data.trial)
  data.time{k} = data.time{k}-data.time{k}(1);
  ecg.time{k}  = ecg.time{k}-ecg.time{k}(1);
end

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = resamplefs;
data           = ft_resampledata(cfg, data);
ecg            = ft_resampledata(cfg, ecg);
