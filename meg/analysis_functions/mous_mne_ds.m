function [dataout] = mous_mne_ds(data, varargin)
% function computes timewindows by averaging over the desired parameters.
% Use must make sure parameter values do not conflict (e.g. if the the
% range is 400-500, and windowsize 100, the timepoints cannot be larger
% than 1)

dataout = data;
param = ft_getopt(varargin, 'parameter', 'avg.pow');
range = ft_getopt(varargin, 'range', [50 550]);
timepoints = ft_getopt(varargin, 'timepoints', 5);
windowsize = ft_getopt(varargin, 'windowsize', 100);

range = range *0.001; 
windowsize = windowsize *0.001; 

tmpdat   = getsubfield(data, param);

tmpout = nan(size(tmpdat,1),timepoints);
tmptime = zeros(1,timepoints);

for i = 1:timepoints
    start = nearest(data.time, range(1));
    stop = nearest(data.time, range(1)+windowsize);
    tmpout(:,i) = nanmean(tmpdat(:,start:stop),2);
    tmptime(1,i) = nanmean(data.time(start:stop));
    range(1) = range(1) + windowsize;
    % NOTE: the second entry in range is not used. 
end

dataout   = setsubfield(dataout, param, tmpout);    
dataout   = setsubfield(dataout, 'time', tmptime);    
    
end
