function frames = mous_makemovie_erf(data, filename, varargin)

parameter = ft_getopt(varargin, 'parameter', 'avg');
zlim      = ft_getopt(varargin, 'zlim', []);
xlim      = ft_getopt(varargin, 'xlim', []);
demean    = ft_getopt(varargin, 'demean', 'yes');
baselinewindow = ft_getopt(varargin, 'baselinewindow', [-inf 0]);
maskparameter  = ft_getopt(varargin, 'maskparameter',  []);

if isempty(xlim)
  dtime  = mean(diff(data.time));
  xlim   = data.time - dtime/2;
  xlim(end+1) = data.time(end) + dtime/2;
end

if isempty(zlim)
  zlim   = [-1 1]*max(abs(data.(parameter)(:))).*0.9;
end

if istrue(demean)
  % baseline normalise
  ix(1) = nearest(data.time,baselinewindow(1));
  ix(2) = nearest(data.time,baselinewindow(2));
  m     = nanmean(data.(parameter)(:,ix(1):ix(2)),2);
  data.(parameter) = data.(parameter)./(m*ones(1,numel(data.time)))-1;
end

data = ft_selectdata(data, 'channel', ft_channelselection('MEG', data.label));

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
    % create the datamask
    xbeg = nearest(data.time,xlim(k));
    xend = nearest(data.time,xlim(k+1));
    data.datamask = nanmean(data.(maskparameter)(:,xbeg:xend),2);
  end
  ft_topoplotER(cfg, data);
  currFrame   = getframe(gcf,[0 0 abc(3:4)]);
  frames(k,1) = currFrame;
  writeVideo(vidObj, currFrame);
end

% Close the file.
close(vidObj);

close all;