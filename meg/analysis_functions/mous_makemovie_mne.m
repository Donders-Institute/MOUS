function frames = mous_makemovie_mne(source, filename, varargin)

parameter       = ft_getopt(varargin, 'parameter', 'avg.pow');
baselinecorrect = istrue(ft_getopt(varargin, 'baselinecorrect', true));

load cortex_inflated_8196reg

s      = sourcemodel;
s.sulc = s.sulc - min(s.sulc) + 0.3;
s.sulc = s.sulc./max(s.sulc);

indxl    = 1:4098;
minpntl  = min(s.pnt(indxl,:),[],1);
maxpntl  = max(s.pnt(indxl,:),[],1);
refpntl  = [maxpntl(1) minpntl(2) 0;
            minpntl(1) minpntl(2) 0;
            minpntl(1) maxpntl(2) 0;
            maxpntl(1) maxpntl(2) 0];
          
indxr    = (1:4098)+4098;
minpntr  = min(s.pnt(indxr,:),[],1);
maxpntr  = max(s.pnt(indxr,:),[],1);
refpntr  = [minpntr(1) minpntr(2) 0;
            maxpntr(1) minpntr(2) 0;
            maxpntr(1) maxpntr(2) 0;
            minpntr(1) maxpntr(2) 0];
% rotation matrices
rl = [0 -1 0  0; 1 0 0 0;0 0 1 0;0 0 0 1];
rr = [0  1 0  0;-1 0 0 0;0 0 1 0;0 0 0 1];

% translation matrices
tl1 = eye(4);
tr1 = eye(4);
tl1(1:3,4) = refpntl(1,:) - warp_apply(rl,refpntl(1,:));
tr1(1:3,4) = refpntr(1,:) - warp_apply(rr,refpntr(1,:));

tl2 = eye(4);
tr2 = eye(4);
tl2(1:3,4) = warp_apply(rl,refpntl(4,:)) - warp_apply(rr,refpntl(2,:));
tr2(1:3,4) = warp_apply(rr,refpntr(2,:)) - warp_apply(rl,refpntr(4,:));

% composite matrix to expose the lateral surface of both hemispheres
hl1 = tl1*rl; hl1(3,4) = maxpntl(3)*1.05;
hr1 = tr1*rr; hr1(3,4) = maxpntr(3)*1.05;

% composite matrix to expose the medial surface of both hemispheres
hl2 = tl2*tl1*rr; hl2(3,4) = minpntl(3)*1.05;
hr2 = tr2*tr1*rl; hr2(3,4) = minpntr(3)*1.05;% rotation is intentionally flipped

s.pnt(indxl,:) = warp_apply(hl1,sourcemodel.pnt(indxl,:));
s.pnt(indxr,:) = warp_apply(hr1,sourcemodel.pnt(indxr,:));
s.pnt(indxl+8196,:) = warp_apply(hl2,sourcemodel.pnt(indxl,:));
s.pnt(indxr+8196,:) = warp_apply(hr2,sourcemodel.pnt(indxr,:));

s.sulc = repmat(s.sulc,[2 1]);
s.curv = repmat(s.curv,[2 1]);
s.tri  = [s.tri;s.tri + 8196];

data = getsubfield(source, parameter);

% baseline normalise
if baselinecorrect
  ix(1) = nearest(source.time,-inf);
  ix(2) = nearest(source.time,0);
  m     = nanmean(data(:,ix(1):ix(2)),2);
  data  = data./(m*ones(1,numel(source.time)))-1;
end

data = repmat(data,[2 1]);

h = figure; view([0 0]); hold on; set(h, 'color', 'k');
ft_plot_mesh(s, 'edgecolor', 'none', 'vertexcolor', repmat(s.sulc, [1 3]));
textstring = ['time = ',num2str(source.time(1),'%1.2f')];
htxt = text(-200,0,-200,textstring);
set(htxt, 'color', 'w');
set(htxt, 'fontsize', 15);

hfun1 = ft_plot_mesh(s, 'edgecolor', 'none', 'vertexcolor', data(:,1), 'facealpha', data(:,1));
set(hfun1, 'FaceVertexAlphaData', data(:,1));
set(hfun1, 'alphadatamapping', 'scaled');
set(hfun1, 'FaceAlpha', 'flat');

xlim  = (-0.075:0.005:0.6);
cmax  = max(data(:));
%clim  = [0 max(data(:))*0.7];
clim = [-0.5 0.5];
caxis(clim);

% Prepare the new file.
vidObj = VideoWriter(filename);
vidObj.FrameRate = 15;

open(vidObj);
abc = get(gcf, 'position');
for k = 1:numel(xlim)
  ix(1) = nearest(source.time, xlim(k)-0.01);
  ix(2) = nearest(source.time, xlim(k)+0.01);
  dat   = nanmean(data(:,ix(1):ix(2)),2);
  set(hfun1, 'FaceVertexCData',     dat(:));
  alphadat = abs(dat(:));%-min(data(:));%./(cmax);
  alphadat(alphadat>0.3) = 0.3;
  alphadat(alphadat<0.15) = 0;
  alphadat(~isfinite(alphadat))=0;
  set(hfun1, 'FaceVertexAlphaData', alphadat);
  textstring = ['time = ',num2str(mean(source.time(ix)),'%1.2f')];
  set(htxt, 'string', textstring);

  currFrame   = getframe(gcf,[1 1 abc(3:4)-1]);
  frames(k,1) = currFrame;
  writeVideo(vidObj, currFrame);
end

% Close the file.
close(vidObj);

close all;