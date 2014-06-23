function frames = mous_makemovie_erf(data, filename, varargin)

% MOUS_MAKEMOVIE_ERF creates a movie (.avi) for a specified channel level
% spatiotemporal data matrix.
%
% Use as:
%  mous_makemovie_erf(data, filename, key1, value1, ...)
%
% Input arguments:
%  data     = FieldTrip data structure with 'chan_time' dimord
%  filename = filename of the movie.
%
% Optional arguments come in key-value pairs:
%  parameter = string, fieldname of the parameter to be used for plotting
%  zlim      = [lower upper], array that determines the color limits
%  xlim      = 1xN array that determines the temporal windows that are used
%               per 'snapshot'.
%  demean    = 'yes', or 'no' (default 'yes'), specifies whether baseline
%               subtraction is performed
%  baselinewindow = [begin end] (in combination with demean='yes'),
%               specifies the begin and end of the baseline window
%  maskparameter

parameter = ft_getopt(varargin, 'parameter', 'avg');
zlim      = ft_getopt(varargin, 'zlim', []);
xlim      = ft_getopt(varargin, 'xlim', []);
demean    = ft_getopt(varargin, 'demean', 'yes');
baselinewindow = ft_getopt(varargin, 'baselinewindow', [-inf 0]);
maskparameter  = ft_getopt(varargin, 'maskparameter',  []);

if ~iscell(data)
  data = {data};
end

if isempty(xlim)
  dtime  = mean(diff(data{1}.time));
  xlim   = data{1}.time - dtime/2;
  xlim(end+1) = data{1}.time(end) + dtime/2;
end

if isempty(zlim)
  zlim   = [-1 1]*max(abs(data{1}.(parameter)(:))).*0.9;
end

if istrue(demean)
  for k = 1:numel(data)
    % baseline normalise
    ix(1) = nearest(data{k}.time,baselinewindow(1));
    ix(2) = nearest(data{k}.time,baselinewindow(2));
    m     = nanmean(data{k}.(parameter)(:,ix(1):ix(2)),2);
    data{k}.(parameter) = data{k}.(parameter)./(m*ones(1,numel(data{k}.time)))-1;
  end
end

for k = 1:numel(data)
  data{k} = ft_selectdata(data{k}, 'channel', ft_channelselection('MEG', data{k}.label));
end
nrow = floor(sqrt(numel(data)));
ncol = ceil(sqrt(numel(data)));


cfg.layout = 'CTF275.lay';
cfg.layout = ft_prepare_layout(cfg);
cfg.parameter = parameter;
cfg.contournum = 0;
cfg.zlim       = zlim;
cfg.gridscale  = 120;

% Prepare the new file.
vidObj = VideoWriter(filename);
vidObj.FrameRate = 15;

open(vidObj);
 
figure; set(gcf,'color','w');
abc = get(gcf,'position');
for k = 1:(numel(xlim)-1)
  cfg.xlim = [xlim(k) xlim(k+1)];
  if ~isempty(maskparameter)
    cfg.maskparameter = 'datamask';
    for m = 1:numel(data)
      % create the datamask
      xbeg = nearest(data{m}.time,xlim(k));
      xend = nearest(data{m}.time,xlim(k+1));
      data{m}.datamask = nanmean(data{m}.(maskparameter)(:,xbeg:xend),2);
    end
  end
  
  if numel(data)>1
    for m = 1:numel(data)
      subplot(nrow,ncol,m);ft_topoplotER(cfg, data{m});
    end
  else
    ft_topoplotER(cfg, data{1});
  end
  currFrame   = getframe(gcf,[0 0 abc(3:4)]);
  frames(k,1) = currFrame;
  writeVideo(vidObj, currFrame);
end

% Close the file.
close(vidObj);

close all;