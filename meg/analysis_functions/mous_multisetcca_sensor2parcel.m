function [data] = mous_multisetcca_sensor2parcel(data, source, parcel_indx)

% this function projects the sensor-level data into source space, for the
% specified parcel

hasstim = strncmp(data.label{end},'stim',4);
if hasstim
  cfg = [];
  cfg.channel = data.label(end);
  stim = ft_selectdata(cfg, data);
else
  stim = [];
end

% ensure the channel labels in the data to match the order of the channels
% in the spatial filter, and compute the parcel specific time courses
[a,b]      = match_str(source.filterlabel, data.label);
indx       = 1:min(5,size(source.F{parcel_indx},1));
for t = 1:numel(data.trial)
    data.trial{t} = source.F{parcel_indx}(indx,a)*data.trial{t}(b,:);
end
data.label = data.label(indx);

if hasstim
  %stim.fsample = data.fsample;
  data = ft_appenddata([], data, stim);
end

% mean subtract using the pre-sentence average
cfg                = [];
cfg.demean         = 'yes';
cfg.baselinewindow = [-0.5 0];
data               = ft_preprocessing(cfg, data);
data               = removefields(data, {'grad' 'elec'});