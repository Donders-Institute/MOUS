function [data, ecg] = mous_restingstate_preprocessing(subjectname, rootdir, options)

if nargin<2
  rootdir = '/project/3011020.09/MEG/';
end

if nargin<3
  options = [];
else
end
resamplefs = ft_getopt(options, 'resamplefs', 200);
hpfilter   = ft_getopt(options, 'hpfilter'  , 'yes');
hpfreq     = ft_getopt(options, 'hpfreq'    , 0.5);
hpfiltord  = ft_getopt(options, 'hpfiltord' , 2); 

% get data and apply artifact rejection
dataset   = mous_db_getfilename(subjectname, 'meg_raw_rest');
mous_db_getdata(subjectname, 'meg_artifact_cfg_restingstate',rootdir);

% deal with resting state datasets that are smaller than average (usually
% because the recording was divided into 1 or more files)
hdr         = ft_read_header(dataset{1});

cfg          = [];
cfg.dataset  = dataset{1};
endsample    = min(357600,hdr.nSamples*hdr.nTrials);
trl          = [2401 endsample 0];
trl          = mous_artifact_remove(trl, dataset{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle}, 'partial', 1); % don't do the horizontal EOG

cfg            = [];
cfg.dataset    = dataset{1};
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
%cfg.dftfilter  = 'yes';
%cfg.dftfreq    = [50 100 150 200 250];
cfg.hpfilter   = hpfilter; 
cfg.hpfreq     = hpfreq;
cfg.hpfiltord  = hpfiltord;
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
cfg             = [];
cfg.demean      = 'yes';
cfg.detrend     = 'no';
cfg.resamplefs  = resamplefs;
cfg.sampleindex = 'no';  % 
data            = ft_resampledata(cfg, data);
ecg             = ft_resampledata(cfg, ecg);
