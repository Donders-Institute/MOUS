function [dataout] = mous_ds_mne(data, varargin)

% FIXME please document the function here

dataout = data;
param = ft_getopt(varargin, 'parameter', 'avg.pow');
range = ft_getopt(varargin, 'range', [50 550]);
timepoints = ft_getopt(varargin, 'timepoints', 5);

range = range *0.001; 

tmpdat   = getsubfield(data, param);

tmpout = nan(size(tmpdat,1),timepoints);
tmptime = zeros(1,timepoints);

% FIXME, what is happening in the for loop? 
% It's increasing i, but start and stop don't change within the loop
for i = 1:timepoints
    start = nearest(data.time, range(1));
    stop = nearest(data.time, range(1)+0.1);
    tmpout(:,i) = nanmean(tmpdat(:,start:stop),2);
    tmptime(1,i) = nanmean(data.time(start:stop));
    range(1) = range(1) + 0.1;
    
end

dataout   = setsubfield(dataout, param, tmpout);    
dataout   = setsubfield(dataout, 'time', tmptime);    
    
end
