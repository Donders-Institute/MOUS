function [data, ecg] = mous_restingstate_preprocessing(subjectname, rootdir, options)

if nargin<2
  rootdir = '/project/3011020.09/MEG/';
end

if nargin<3
  options.resamplefs = 200;
else
end
if isfield(options, 'resamplefs')
  resamplefs = options.resamplefs;
else
  resamplefs = 200;
end

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_rest');
artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg_restingstate',rootdir);

cfg          = [];
cfg.dataset  = dataset{1};
%hdr          = ft_read_header(cfg.dataset);
%trl          = [2401 hdr.nSamples*hdr.nTrials-2400 0]; % adjust for the two seconds deleted for padding purposes
trl          = [2401 365000 0];
%trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 3 4]), 'partial', 1); % don't do the horizontal EOG
trl          = mous_artifact_remove(trl, dataset{1}, artfctcfg([1 2 3 4]), 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset{1};
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
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
