function [f,out,labellist,p] = plotCcc(C, A, label, thr, varargin)

if nargin<4 || isempty(thr)
  thr = 1;
end

globalscale = ft_getopt(varargin, 'globalscale', true);
lay         = ft_getopt(varargin, 'layout');
plotstyle   = ft_getopt(varargin, 'plotstyle', 'median');
zlim        = ft_getopt(varargin, 'zlim',      'zeromax');

if isempty(lay)
  [c,labels,p,labellist, lay] = mous_edgesofinterest;
  
  X = C(:,:,1);
  [a,b] = match_str(label, labels(:,1));
  p = p(:,b);
  c = c(b,b);
  labels = labels(b,:);
  
  % sparsify the layout
  laynew     = lay;
  laynew.pos = laynew.pos.*1.05;
  rot = 360*atan(laynew.pos(:,2)./laynew.pos(:,1))/(2*pi);
  n   = numel(laynew.label)/2;
  alh = [repmat({'left'},[n 1]);repmat({'right'},[n 1])];
  [a,b] = match_str(lay.label, labellist);
  laynew.label  = laynew.label(a);
  laynew.pos    = laynew.pos(a,:);
  laynew.height = laynew.height(a);
  laynew.width  = laynew.width(a);
  rot = rot(a);
  alh = alh(a);
  
  labellist = labellist(b);
  p         = p(b,:);
else
  laynew     = lay;
  laynew.pos = laynew.pos.*1.05;
  rot = 360*atan(laynew.pos(:,2)./laynew.pos(:,1))/(2*pi);
  n   = numel(laynew.label)/2;
  alh = [repmat({'right'},[n 1]);repmat({'left'},[n 1])];
  [a,b] = match_str(lay.label, label);
  laynew.label  = laynew.label(a);
  laynew.pos    = laynew.pos(a,:);
  laynew.height = laynew.height(a);
  laynew.width  = laynew.width(a);
  rot = rot(a);
  alh = alh(a);
  
  
  labellist = label(b);
  C = C(b,b,:);
  
  % now collapse across the subparcels
  for k = 1:numel(labellist)
    labellist2{k,1} = labellist{k}(1:end-3);
  end
  [U, i1, i2] = unique(labellist2);
  p = zeros(numel(U),numel(labellist));%eye(numel(labellist));
  for k = 1:numel(U)
    p(k,strcmp(labellist2,U{k})) = 1./sum(strcmp(labellist2,U{k}));
  end
  labellist = U;
  
  laynew.label  = labellist2(i1);
  laynew.pos    = laynew.pos(i1,:);
  laynew.height = laynew.height(i1);
  laynew.width  = laynew.width(i1);
  rot = rot(i1);
  alh = alh(i1);
  
  lay = laynew;
  lay.pos = lay.pos./1.05;
end


% set the options for the spaghetti plotting
cfg             = [];
cfg.colorparam  = 'cohspctrm';
cfg.layout      = lay;
cfg.foi         = 0;
cfg.arrowhead   = 'stop';
cfg.linestyle   = 'curve';
cfg.widthparam  = 'widthpos';
%cfg.alphaparam  = 'widthpos';

% re-set the options for the layout plotting
plotlayoptions = {'interpreter','none','point','no','box','no','labelrotate',rot,'labelalignh',alh,'labelsize',12};

% create a dummy data structure that ft_topoplotCC can deal with
data = [];
data.label     = labellist;
data.freq      = 0;
data.dimord    = 'chan_chan';

cfg.newfigure = 'no';

map = colormap('autumn');
map(:,2) = linspace(0,0.8,64);
cfg.colormap  = map;

p(p>0) = 1;
for k = 1:size(C,3)
  C2(:,:,k) = p*C(:,:,k)*p';
  w = p*double(C(:,:,k)>0)*p';
  C2(:,:,k) = C2(:,:,k)./w;
end
C2(~isfinite(C2)) = 0;
C = C2;
if globalscale 
  Cwidth = 2.*abs(C)./max(C(:));
else
  for k = 1:size(C,3)
    Cwidth(:,:,k) = 2.*abs(C(:,:,k))./max(max(C(:,:,k)));
  end
end
for k = 1:size(C,3)
  X = C(:,:,k);
  data.cohspctrm = X;
  data.widthpos  = 2.*Cwidth(:,:,k);
  data.widthpos(data.widthpos<thr)=0;
  figure('position',[50 50 900 600]);
  subplot('position',[0.01 0.01 0.98 0.98]);
  ft_topoplotCC(cfg, data);
  ft_plot_lay(laynew, plotlayoptions{:});
  axis([-1.2 1.2 -1.2 1.2]);
  
  plotstring = false;
  if ~isempty(A) && isnumeric(A)
    axes('position',[0.32 0.4 0.2 0.2]);
    if ndims(A)==3
      switch plotstyle
        case 'median'
          [q1,q2]=idealf(A(:,:,k),2);
          q = [q1' flipud(q2)' q1(1)];
          fax = [0:(size(A,1)-1) (size(A,1)-1):-1:0 0];
      
          plot(0:(size(A,1)-1), nanmedian(A(:,:,k),2), 'k');
          hold on; patch(fax,q,[0.6 0.6 0.6],'facealpha',0.1,'edgecolor',[0.6 0.6 0.6]);
        otherwise
          plot(0:(size(A,1)-1),A(:,:,k));
      end
    else
      plot(0:(size(A,1)-1),A(:,k),'k');
    end
    abc = axis;
    switch 'zlim',
      case 'zeromax'
        axis([0 size(A,1)-1 0 abc(4)]);
      otherwise
        axis([0 size(A,1)-1 abc(3:4)]);
    end
    set(gca,'xtick',[0 10 25 50 75 100],'tickdir','out');
    axes('position',[0.51 0.4 0.2 0.2]);
  elseif ~isempty(A) && iscell(A)
    plotstring = true;
    axes('position', [0.35 0.35 0.3 0.3]);
  else
    axes('position', [0.35 0.35 0.3 0.3]);
  end
  
  [srt,ix]=sort(mod(cart2pol(laynew.pos(:,1),laynew.pos(:,2))-pi/2,2*pi));
  dat = data.cohspctrm(ix,ix);
  map = colormap('autumn');
  map(1:12,:) = map(1:12,:)+linspace(1,0,12)'*ones(1,3);
  map = min(map,1);
  rgb = ind2rgb(round(64.*(dat./max(C(:)))),map);
  
  imagesc(rgb);axis square;set(gca,'yaxislocation','right');
  n = size(dat,1)./2;
  hold on;
  plot([0.5 n*2+0.5],[n+0.5 n+0.5],'k');
  plot([n+0.5 n+0.5],[0.5 n*2+0.5],'k');
  plot([0.5 n*2+0.5],[0.5 n*2+0.5],'k');
  if plotstring
    axes('position', [0.4 0.68 0.3 0.2]);axis off
    text(0, 0, A{k});
  end
  
  set(gcf,'color','white');
  %set(gcf,'renderer','painters');
  out(:,:,k) = X;
  f(k) = getframe(gcf);
end
