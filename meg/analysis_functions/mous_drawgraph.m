function mous_drawgraph(dat, label, thr)

if numel(thr)<2
  if thr<0
    thr(2)=inf;
  else
    thr = [-inf thr];
  end
end
dat(dat>thr(1)&dat<thr(2)) = 0;

h = figure; hold on;
set(h,'color','k');
set(gcf, 'renderer', 'opengl');

% sort out the labels such that they are mirror symmetric left and right,
% with the left hemisphere on the left
for k = 1:numel(label)
  if strcmp(label{k}(4),'_')
    label{k} = [label{k}(1:2),'0',label{k}(3:end)];
  end
end
[label,srtidx] = sort(label);
dat            = dat(srtidx,srtidx);

newlabel = label;
for k = 1:numel(newlabel)
  newlabel{k} = newlabel{k}(1:4);
end
ulabel = unique(newlabel);

newlabel = getlabelalias(newlabel);

for k = 1:numel(ulabel)
  sel = find(strcmp(newlabel(:,1),ulabel{k}));
  if numel(sel)>1,
    sel = setdiff(sel,sel(ceil(numel(sel)/2)));
    for m = 1:numel(sel)
      newlabel{sel(m),1} = '';
    end
  else
    % keep as is
  end
end

n = size(newlabel,1)/2;
[srt,srtidx] = sort(newlabel(1:n,2));
srtidx       = [srtidx(:);srtidx(:)+n];
newlabel     = newlabel(srtidx,:);
dat          = dat(srtidx,srtidx);

% The following quick and dirty assumes that the labels are Left first and
% that the left and right homologues exist
srtidx = [n+(1:n) n:-1:1];
newlabel = newlabel(srtidx,:);
dat   = dat(srtidx,srtidx);

n = size(newlabel,1);
x = sin(2*pi*[linspace(0.01,0.49,n/2) linspace(0.51,0.99,n/2)])./2;
x(x<0) = x(x<0)-0.02;
x(x>0) = x(x>0)+0.02;
y = cos(2*pi*(1:n)/n)./2;

lay = [];
lay.label = label;
lay.pos   = [x(:) y(:)];
%lay.outline{1} = [x(1:4:end)'.*1.05 y(1:4:end)'.*1.05];
lay.width = 0.01.*ones(size(lay.pos,1),1);
lay.height = 0.01.*ones(size(lay.pos,1),1);
ft_plot_lay(lay,'label','off','box','off');

for k = 1:size(newlabel,1)
  if ~isempty(newlabel{k,1})
    if x(k)<0,
      rot = 360*atan(y(k)/x(k))/(2*pi);%-180;
      hor_al = 'right';
    else
      rot = 360*atan(y(k)/x(k))/(2*pi);
      hor_al = 'left';
    end
    htext(k) = text(x(k).*1.15,y(k).*1.15,newlabel{k,2},'Rotation',rot,'interpreter','none','horizontalalignment',hor_al,'verticalalignment','middle','fontname','arial','fontsize',12,'color','w');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the data here

[from,to] = find(dat);
rgb = colormap;
colorparam = dat;
if ~isempty(colorparam)
  cmin = min(colorparam(:));
  cmax = max(colorparam(:));
  colorparam = (colorparam - cmin)./(cmax-cmin);
  colorparam = round(colorparam * (size(rgb,1)-1) + 1);
end
widthparam = abs(dat);
minwidth   = min(widthparam(widthparam(:)~=0))
maxwidth   = max(widthparam(:));
widthparam = widthparam-minwidth+1;%./maxwidth;

for k = 1:numel(from)
  %hline = patch([x(from(k)) x(to(k))],[y(from(k)) y(to(k))],1);
  arrowbeg  = [x(from(k)) y(from(k))];
  arrowend  = [x(to(k))   y(to(k))];
  center    = (arrowbeg+arrowend)/2;
  direction = (arrowend - arrowbeg);
  direction = direction/norm(direction);
  offset    = [direction(2) -direction(1)];
  arrowbeg  = 0.99 * (arrowbeg-center) + center;% + cfg.arrowoffset * offset;
  arrowend  = 0.99 * (arrowend-center) + center;% + cfg.arrowoffset * offset;

  hline = arrow(arrowbeg, arrowend, 'Ends', 'stop', 'length', 0.03);
  set(hline, 'linewidth', (widthparam(from(k),to(k))));
  set(hline, 'EdgeColor', rgb(colorparam(from(k),to(k)),:));
  set(hline, 'FaceColor', rgb(colorparam(from(k),to(k)),:)); % for arrowheads
  set(hline, 'linewidth', (widthparam(from(k),to(k))));
end


axis([-0.8 0.8 -0.8 0.8]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION for plotting arrows, see also fieldtrip/private/arrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = arrow(arrowbeg, arrowend, varargin)
ends   = ft_getopt(varargin, 'ends');
length = ft_getopt(varargin, 'length'); % the length of the arrow head, in figure units
color  = [0 0 0]; % in RGB

direction = (arrowend - arrowbeg);
direction = direction/norm(direction);
offset    = [direction(2) -direction(1)];

pnt1 = arrowbeg;
pnt2 = arrowend;
h = patch([pnt1(1) pnt2(1)], [pnt1(2) pnt2(2)], color);

switch ends
  case 'stop'
    pnt1 = arrowend - length*direction + 0.4*length*offset;
    pnt2 = arrowend;
    pnt3 = arrowend - length*direction - 0.4*length*offset;
    h(end+1) = patch([pnt1(1) pnt2(1) pnt3(1)]', [pnt1(2) pnt2(2) pnt3(2)]', color);

  case 'start'
    pnt1 = arrowbeg + length*direction + 0.4*length*offset;
    pnt2 = arrowbeg;
    pnt3 = arrowbeg + length*direction - 0.4*length*offset;
    h(end+1) = patch([pnt1(1) pnt2(1) pnt3(1)]', [pnt1(2) pnt2(2) pnt3(2)]', color);

  case 'both'
    pnt1 = arrowend - length*direction + 0.4*length*offset;
    pnt2 = arrowend;
    pnt3 = arrowend - length*direction - 0.4*length*offset;
    h(end+1) = patch([pnt1(1) pnt2(1) pnt3(1)]', [pnt1(2) pnt2(2) pnt3(2)]', color);

    pnt1 = arrowbeg + length*direction + 0.4*length*offset;
    pnt2 = arrowbeg;
    pnt3 = arrowbeg + length*direction - 0.4*length*offset;
    h(end+1) = patch([pnt1(1) pnt2(1) pnt3(1)]', [pnt1(2) pnt2(2) pnt3(2)]', color);

  case 'none'
    % don't draw arrow heads
end

function label = getlabelalias(label)

label = label(:);
for k = 1:size(label,1)
  switch label{k}(1:4)
    case {'L_01' 'R_01'}
      label{k,2} = 'p_sensory_primary';
    case {'L_02' 'R_02'}
      label{k,2} = 'p_sensory_primary';
    case {'L_03' 'R_03'}
      label{k,2} = 'p_sensory_primary';
    case {'L_04' 'R_04'}
      label{k,2} = 'f_motor_primary';
    case {'L_05' 'R_05'}
      label{k,2} = 'p_area05';
    case {'L_06' 'R_06'}
      label{k,2} = 'f_premotor';
    case {'L_07' 'R_07'}
      label{k,2} = 'p_area07';
    case {'L_08' 'R_08'}
      label{k,2} = 'f_area08';
    case {'L_09' 'R_09'}
      label{k,2} = 'f_area09';
    case {'L_10' 'R_10'}
      label{k,2} = 'f_area10';
    case {'L_11' 'R_11'}
      label{k,2} = 'f_area11';
    case {'L_12' 'R_12'}
    case {'L_13' 'R_13'}
    case {'L_14' 'R_14'}
    case {'L_15' 'R_15'}
    case {'L_16' 'R_16'}
    case {'L_17' 'R_17'}
      label{k,2} = 'o_striate';
    case {'L_18' 'R_18'}
      label{k,2} = 'o_extrastriate';
    case {'L_19' 'R_19'}
      label{k,2} = 'o_extrastriate';
    case {'L_20' 'R_20'}
      label{k,2} = 't_inf';
    case {'L_21' 'R_21'}
      label{k,2} = 't_middle';
    case {'L_22' 'R_22'}
      label{k,2} = 't_sup';
    case {'L_23' 'R_23'}
      label{k,2} = 'p_pcc';
    case {'L_24' 'R_24'}
      label{k,2} = 'f_acc';
    case {'L_25' 'R_25'}
      label{k,2} = 'f_area25';
    case {'L_26' 'R_26'}
      label{k,2} = 'p_area26';
    case {'L_27' 'R_27'}
      label{k,2} = 't_area27';
    case {'L_28' 'R_28'}
      label{k,2} = 't_mtl';
    case {'L_29' 'R_29'}
      label{k,2} = 'p_area29';
    case {'L_30' 'R_30'}
      label{k,2} = 'p_area30';
    case {'L_31' 'R_31'}
      label{k,2} = 'p_pcc';
    case {'L_32' 'R_32'}
      label{k,2} = 'f_acc';
    case {'L_33' 'R_33'}
      label{k,2} = 'f_acc';
    case {'L_34' 'R_34'}
      label{k,2} = 't_entorhinal';
    case {'L_35' 'R_35'}
      label{k,2} = 't_perirhinal';
    case {'L_36' 'R_36'}
      label{k,2} = 't_perirhinal';
    case {'L_37' 'R_37'}
      label{k,2} = 't_inf_fus';
    case {'L_38' 'R_38'}
      label{k,2} = 't_anterior';
    case {'L_39' 'R_39'}
      label{k,2} = 'p_angular';
    case {'L_40' 'R_40'}
      label{k,2} = 'p_supram';
    case {'L_41' 'R_41'}
      label{k,2} = 't_area41';
    case {'L_42' 'R_42'}
      label{k,2} = 't_area42';
    case {'L_43' 'R_43'}
      label{k,2} = 'f_area43';
    case {'L_44' 'R_44'}
      label{k,2} = 'f_ifg_operc';
    case {'L_45' 'R_45'}
      label{k,2} = 'f_ifg_triang';
    case {'L_46' 'R_46'}
      label{k,2} = 'f_dlpfc';
    case {'L_47' 'R_47'}
      label{k,2} = 'f_ifg_orb';
    otherwise
  end
end