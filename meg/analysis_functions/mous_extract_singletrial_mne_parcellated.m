% script for Andre to get single trial source-level MEG data, parcellated

% add fieldtrip + necessary subfolders to the path
addpath /home/common/matlab/fieldtrip
ft_defaults;

subjectname = 'V1020';

% load channel level data
load(fullfile('/project/3011020.09/MEG',subjectname,'erf',[subjectname,'_erf_allwords_02-nextword']));

% keep the MEG channels
cfg = [];
cfg.channel = ft_channelselection('MEG', data.label);
data = ft_selectdata(cfg, data);

% load the linear mapping to parcel-space
load(fullfile('/project/3011020.09/MEG',subjectname,'mne',[subjectname,'_mne_parcellated_wordsent']));

for k = 1:numel(data.trial)
  data.trial{k} = tlck.F*data.trial{k}; % assuming channel order to be the same in data and tlck, fair assumption
end
data.label = tlck.label;

% convert cell-array into 3D matrix trials x parcels x time, with NaNs for
% missing data
cfg = [];
cfg.keeptrials = 'yes';
cfg.vartrllength = 2;
cfg.preproc.demean = 'yes';
cfg.preproc.baselinewindow = [-inf 0];
data = ft_timelockanalysis(cfg, data);

% now you probably want to make a distinction between words presented in a
% sentence, and words in a word list
cfg = [];
cfg.trials = find(ismember(data.trialinfo(:,2),[1 2 5 6]));
data_sent = ft_selectdata(cfg, data);
cfg.trials = find(ismember(data.trialinfo(:,2),[3 4 7 8]));
data_list = ft_selectdata(cfg, data);

