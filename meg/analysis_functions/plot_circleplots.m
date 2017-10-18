function [f,out,labellist,p] = plot_circleplots(C, label, thr, varargin)

if nargin<3 || isempty(thr)
  thr = 1;
end

globalscale = ft_getopt(varargin, 'globalscale', true);
lay         = ft_getopt(varargin, 'layout');
cmap        = ft_getopt(varargin, 'colormap', []);
doannotate  = ft_getopt(varargin, 'doannotate', true);

if isempty(lay)
  % get the default layout
  [c,labels,p,labellist, lay] = mous_edgesofinterest_visaud;
  lay.pos = lay.pos./1.5;
  
  [a,b] = match_str(label, labels(:,1));
  p     = p(:,b); % projection matrix, sub parcels -> main parcels
  c     = c(b,b); % existing connections per definition
  labels = labels(b,:); % labels
  
  % sparsify the layout
  laynew     = lay;
  laynew.pos = laynew.pos.*1.05;
  
  % set some parameters for the layout plotting
  rot = 360*atan(laynew.pos(:,2)./laynew.pos(:,1))/(2*pi);
  n   = numel(laynew.label)/2;
  alh = [repmat({'left'},[n 1]);repmat({'right'},[n 1])];
  
  % reorder and subselect the 'channels' according to what matches between the layout and the selected ROIs 
  [a,b] = match_str(lay.label, labellist);
  laynew.label  = laynew.label(a);
  laynew.pos    = laynew.pos(a,:);
  laynew.height = laynew.height(a);
  laynew.width  = laynew.width(a);
  
  rot       = rot(a);
  alh       = alh(a);
  labellist = labellist(b);
  p         = p(b,:);
else
  % Something else happening here: don't exactly understand anymore what...
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

% rename the labels in the labelling to be plotted (i.e. remove L/R and
% replace with B.A.
laynew.label = labellist2newlabellist(laynew.label);

% set the options for the spaghetti plotting
cfg             = [];
cfg.colorparam  = 'cohspctrm';
cfg.layout      = lay;
cfg.foi         = 0;
cfg.arrowhead   = 'stop';
cfg.linestyle   = 'curve';%_bundle';
cfg.widthparam  = 'widthpos';
%cfg.alphaparam  = 'widthpos';

% re-set the options for the layout plotting
plotlayoptions = {'interpreter','none','point','no','box','no','labelrotate',rot,'labelalignh',alh,'labelsize',16};

% create a dummy data structure that ft_topoplotCC can deal with
data = [];
data.label     = labellist;
data.freq      = 0;
data.dimord    = 'chan_chan';

cfg.newfigure = 'no';
cfg.curveparam = 0.7;

if isempty(cmap)
  map(1:64,1) = 1;
  map(1:64,3) = 0;
  map(:,2) = linspace(0,0.8,64);
  cfg.colormap  = map;
else
  cfg.colormap = cmap;
end
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
  if iscell(cmap)
    cfg.colormap = cmap{k};
  end
  X = C(:,:,k);
  data.cohspctrm = X;
  data.widthpos  = 2.*Cwidth(:,:,k);
  data.widthpos(data.widthpos<thr)=0;
  figure('position',[50 50 900 600]);
  subplot('position',[0.01 0.01 0.98 0.98]);
  ft_topoplotCC(cfg, data);
  ft_plot_lay(laynew, plotlayoptions{:});
  axis([-1.2 1.2 -1.2 1.2]);
  
  if doannotate,
  % annotate the figure with left/right, and
  % frontal/parietal/temporal/occitpital, this only works with the default
  % lay
  ad = 0.075; % angular distance between the letters
  amp = 0.60;
  
  coords{1} = atan(mean(laynew.pos(1:6,2))./mean(laynew.pos(1:6,1)))+(3:-1:-3).*ad + [0 0 0 0 0 0 0.02];
  coords{2} = atan(mean(laynew.pos(7:8,2))./mean(laynew.pos(7:8,1)))+(3.5:-1:-3.5).*ad + [-0.02 -0.025 -0.02 0.01 0.02 0.02 0.02 0.04];
  coords{3} = atan(mean(laynew.pos(9:15,2))./mean(laynew.pos(9:15,1)))+(-3.5:3.5).*ad + [-0.04 -0.03 0 0.015 0.0125 0.01 0.01 0.0];
  coords{4} = atan(mean(laynew.pos(16:18,2))./mean(laynew.pos(16:18,1)))+(-4:4).*ad + [0.015 0.015 0.015 0.0075 0 -0.0075 -0.015 -0.015 -0.015];
  coords{5} = atan(mean(laynew.pos(19:21,2))./mean(laynew.pos(19:21,1)))+(-4:4).*ad + pi + [0.015 0.015 0.015 0.0075 0 -0.0075 -0.015 -0.015 -0.015];
  coords{6} = atan(mean(laynew.pos(22:28,2))./mean(laynew.pos(22:28,1)))+(-3.5:3.5).*ad + pi + [-0.04 -0.03 0 0.015 0.0125 0.01 0.01 0.0];
  coords{7} = atan(mean(laynew.pos(29:30,2))./mean(laynew.pos(29:30,1)))+(3.5:-1:-3.5).*ad + pi + [-0.02 -0.025 -0.02 0 0.02 0.02 0.02 0.04];
  coords{8} = atan(mean(laynew.pos(31:36,2))./mean(laynew.pos(31:36,1)))+(3:-1:-3).*ad + pi + [0 0 0 0 0 0 0.02];
  
  strings{1} = 'frontal';
  strings{2} = 'parietal';
  strings{3} = 'temporal';
  strings{4} = 'occipital';
  strings{5}  = 'occipital';
  strings{6}  = 'temporal';
  strings{7}  = 'parietal';
  strings{8}  = 'frontal';
  
  rotation{1} = coords{1}.*(180./pi)-90;
  rotation{2} = coords{2}.*(180./pi)-90;
  rotation{3} = coords{3}.*(180./pi)+90;
  rotation{4} = coords{4}.*(180./pi)+90;
  rotation{5} = coords{5}.*(180./pi)+90;
  rotation{6} = coords{6}.*(180./pi)+90;
  rotation{7} = coords{7}.*(180./pi)-90;
  rotation{8} = coords{8}.*(180./pi)-90;
  
  for m = 1:numel(coords)
    for p = 1:numel(coords{m})
      text(amp.*cos(coords{m}(p)),amp.*sin(coords{m}(p)),strings{m}(p),'fontsize',15,'rotation',rotation{m}(p),'horizontalalignment','center','verticalalignment','middle','fontname','arial','color',[0.4 0.4 0.4],'interpreter','none');
    end
  end
  
  title(['component ',num2str(k)],'fontname','arial','fontsize',16);
  set(gcf, 'color', 'w');
  end
  
  %set(gcf,'renderer','painters');
  out(:,:,k) = X;
  f(k) = getframe(gcf);
end


function out = labellist2newlabellist(in)

out = strrep(in, 'L_', 'B.A.');
out = strrep(out, 'R_', 'B.A.');

sel = find(strncmp(out, 'B.A.t', 5));
for k = sel(:)'
  tok = tokenize(out{k},'_');
  tok = strrep(tok,'mid','middle ');
  tok = strrep(tok,'ant','ant.');
  tok = strrep(tok,'post','post.');
  tok = strrep(tok,'inf','inf.');
  tok = strrep(tok,'sup','sup.');
  
  out{k} = [tok{2},tok{3},'temp.'];
end

