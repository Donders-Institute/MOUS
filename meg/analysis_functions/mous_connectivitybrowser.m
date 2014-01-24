function mous_connectivitybrowser(grid, source, varargin)

% MOUS_CONNECTIVITYBROWSER allows to browse a 6D-connectome
% 
% Use as
%  
% mous_connectivitybrowser(grid, source, parameter)
%
% where grid is the specification of a 3D grid that specified the
% sourcemodel for the connectome, and source is the structure containing
% the connectome (in the sparse representation, i.e. only the inside
% voxels), and parameter is a string denoting the fieldname in the source
% structure denoting the connectivity metric

parameter = ft_getopt(varargin, 'parameter', '');
scale     = ft_getopt(varargin, 'scale', {[] []});
method    = ft_getopt(varargin, 'method', {'ortho' 'slice'});

coh = zeros(prod(grid.dim), 'single')+nan;
if ~isa(source.(parameter), 'single')
  source.(parameter) = single(source.(parameter));
end
if ~isfield(source,'inside1')
  inside1 = grid.inside;
else
  inside1 = source.inside1;
end
if ~isfield(source,'inside2')
  inside2 = grid.inside;
else
  inside2 = source.inside2;
end
coh(inside1, inside2) = source.(parameter);
coh = reshape(coh, [grid.dim grid.dim]);

siz = size(coh);
x1i = round(siz(1)/2);
y1i = round(siz(2)/2);
z1i = round(siz(3)/2);
x2i = round(siz(4)/2);
y2i = round(siz(5)/2);
z2i = round(siz(6)/2);

x = 1:siz(1);
y = 1:siz(2);
z = 1:siz(3);

% ensure same color scaling for all figures
if isempty(scale{1})
c1min = min(coh(:));
c1max = max(coh(:));
else
c1min = scale{1}(1);
c1max = scale{1}(2);
end


if isempty(scale{2})
  c2min = min(coh(:));
  c2max = max(coh(:));
else
  c2min = scale{2}(1);
  c2max = scale{2}(2);
end

h = figure;
p = get(h, 'position');
set(h, 'position', [p(1:2) 2*p(3) p(4)]);
set(h, 'color', [1 1 1]);
set(h, 'visible', 'on');
set(h, 'windowbuttondownfcn', @cb_buttonpress); 
set(h, 'windowbuttonupfcn',   @cb_buttonrelease);
set(h, 'windowkeypressfcn',   @cb_keyboard);

clf;

info = getinfo_pos(squeeze(coh(x1i,y1i,z1i,:,:,:)),  [x1i y1i z1i], [x2i y2i z2i]);
vol1 = squeeze(coh(x1i,y1i,z1i,:,:,:));
vol2 = coh(:,:,:,x1i,y1i,z1i);

% initialize left part of the figure
switch method{1}
  case 'ortho'
    h1a = axes( 'position', [0.05 0.55 0.20 0.4], 'tag', 'ik'); 
    h1b = axes( 'position', [0.3  0.55 0.20 0.4],  'tag', 'jk');
    h1c = axes( 'position', [0.05 0.10 0.20 0.4], 'tag', 'ij');
    h1d = axes( 'position', [0.3  0.10 0.20 0.4]); axis off;
    
    [vol1a,vol1b,vol1c] = makeortho(vol1);
    
    hs1a = imagesc(x, z, vol1a', 'parent', h1a);
    axis equal; axis tight;
    hs1b = imagesc(y, z, vol1b', 'parent', h1b);
    axis equal; axis tight;
    hs1c = imagesc(x, y, vol1c', 'parent', h1c);
    axis equal; axis tight; axis off;
    
    set(h1a, 'tag', 'ik1', 'ydir', 'normal', 'visible', 'off');
    set(h1b, 'tag', 'jk1', 'ydir', 'normal', 'visible', 'off');
    set(h1c, 'tag', 'ij1', 'ydir', 'normal', 'visible', 'off');
    
    hc1a = crosshair([x1i z1i], 'color', 'yellow', 'parent', h1a);
    hc1b = crosshair([y1i z1i], 'color', 'yellow', 'parent', h1b);
    hc1c = crosshair([x1i y1i], 'color', 'yellow', 'parent', h1c);
  case 'slice'
    h1a = axes( 'position', [0.07 0.15 0.4 0.8]);
    h1b = nan;
    h1c = nan;
    h1d = axes( 'position', [0.05  0.05 0.55 0.55]); axis off

    map  = makemontage(vol1);
    hs1a = imagesc(map, 'parent', h1a);
    hs1b = nan;
    hs1c = nan;
    set(h1a, 'tag', 'map1', 'ydir', 'normal', 'visible', 'off');
    colormap jet;
    
    hc1a = crosshair(info.id2d, 'color', 'm', 'parent', h1a);
    hc1b = [nan nan];
    hc1c = [nan nan];

  otherwise
end


% initialize right part of the figure
switch method{2}
  case 'ortho'
  case 'slice'
    h2a = axes( 'position', [0.57 0.15 0.4 0.8]);
    h2b = nan;
    h2c = nan;
    h2d = axes( 'position', [0.55  0.05 0.55 0.55]); axis off

    map  = makemontage(vol2);
    hs2a = imagesc(map, 'parent', h2a);
    hs2b = nan;
    hs2c = nan;
    set(h2a, 'tag', 'map2', 'ydir', 'normal', 'visible', 'off');
    colormap jet;
    
    hc2a = crosshair(info.id2d, 'color', 'm', 'parent', h2a);
    hc2b = [nan nan];
    hc2c = [nan nan];
  otherwise
end


p1   = grid.pos(info.ind1,:);
p2   = grid.pos(info.ind2,:);

ht1  = text(0,0,sprintf('ind1=%6.0f\npos1=[%3.1f %3.1f %3.1f],\nval1=%f', info.ind1,p1(1),p1(2),p1(3), info.val1), 'parent', h1d);
ht2  = text(0,0,sprintf('ind2=%6.0f\npos2=[%3.1f %3.1f %3.1f],\nval2=%f', info.ind2,p2(1),p2(2),p2(3), info.val2), 'parent', h2d);

% create structure to be passed to gui
opt.data          = coh;
opt.handlesaxes   = [h1a  h1b  h1c  h1d h2a  h2b  h2c  h2d];
opt.handlesslice  = [hs1a hs1b hs1c nan hs2a hs2b hs2c nan];
opt.handlescross  = [hc1a(:)';hc1b(:)';hc1c(:)';hc2a(:)';hc2b(:)';hc2c(:)'];
opt.handlestext   = [ht1 ht2];
opt.ijk1          = [x1i y1i z1i];
opt.ijk2          = [x2i y2i z2i];
opt.ijk1ref       = [x1i y1i z1i];
opt.ijk2ref       = [x2i y2i z2i];
opt.ijk1val       = [x1i y1i z1i];
opt.ijk2val       = [x2i y2i z2i];
opt.clim1         = [c1min c1max];
opt.clim2         = [c2min c2max];
opt.dim           = size(coh);
opt.pos           = grid.pos;
opt.quit          = 0;
opt.method        = method;

setappdata(h, 'opt', opt);
cb_redraw(h);
    
while opt.quit==0
  uiwait(h);
  opt = getappdata(h, 'opt'); % needed to update the opt.quit
end
opt = getappdata(h, 'opt');
delete(h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = getinfo_pos(dat1, coord1, coord2)

x1i = coord1(1);
y1i = coord1(2);
z1i = coord1(3);
x2i = coord2(1);
y2i = coord2(2);
z2i = coord2(3);

siz     = size(dat1);
ndiv    = [ceil(sqrt(siz(3))) floor(sqrt(siz(3)))]; 
[nx,ny] = ind2sub(ndiv,z2i);
y2      = siz(2)*(ny-1)+y2i;
x2      = siz(1)*(nx-1)+x2i;

% xcoord  = rem(x2i-1, siz(1))+1;
% ycoord  = rem(y2i-1, siz(2))+1;
% zcoord  = floor(y2i./siz(2))*ndiv(1)+1+floor(x2i./siz(1));

ind1 = sub2ind(siz(1:3),x1i,y1i,z1i);
%ind2 = sub2ind(siz(1:3),xcoord,ycoord,zcoord);
ind2 = sub2ind(siz(1:3),x2i,y2i,z2i);

val1 = dat1(x1i,y1i,z1i);
val2 = dat1(x2i,y2i,z2i);

info.val1 = val1;
info.val2 = val2;
info.ind1 = ind1;
info.ind2 = ind2;
info.id2d = [x2 y2];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function map = makemontage(dat)
  
siz    = size(dat);
ndiv   = [ceil(sqrt(siz(3))) floor(sqrt(siz(3)))]; 
map    = zeros(siz(2)*ndiv(2),siz(1)*ndiv(1));
for k=1:siz(3)
  [nx,ny] = ind2sub(ndiv,k);
  map(siz(2)*(ny-1)+1:siz(2)*ny,siz(1)*(nx-1)+1:siz(1)*nx) = dat(:,:,k)';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vol1a,vol1b,vol1c] = makeortho(vol1)

vol1(~isfinite(vol1))=0;
vol1a=squeeze(max(vol1,[],2));
vol1b=squeeze(max(vol1,[],1));
vol1c=squeeze(max(vol1,[],3));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_keyboard(h, eventdata)

if isempty(eventdata)
  % determine the key that corresponds to the uicontrol element that was activated
  key = get(h, 'userdata');
else
  % determine the key that was pressed on the keyboard
  key = parseKeyboardEvent(eventdata);
end
% get focus back to figure
if ~strcmp(get(h, 'type'), 'figure')
  set(h, 'enable', 'off');
  drawnow;
  set(h, 'enable', 'on');
end

h   = getparent(h);
opt = getappdata(h, 'opt');

curr_ax = get(h,       'currentaxes');
tag     = get(curr_ax, 'tag');
switch tag
  case 'jk'
    xy = [2 3];
  case 'ji'
    xy = [2 1];
  case 'ik'
    xy = [1 3];
  otherwise
end

switch key
  case 'leftarrow'
    opt.ijk(xy(2)) = opt.ijk(xy(2)) - 1;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  case 'rightarrow'
    opt.ijk(xy(2)) = opt.ijk(xy(2)) + 1;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  case 'uparrow'
    opt.ijk(xy(1)) = opt.ijk(xy(1)) - 1;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  case 'downarrow'
    opt.ijk(xy(1)) = opt.ijk(xy(1)) + 1;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  case 'q'
    setappdata(h, 'opt', opt);
    cb_cleanup(h);
  case 'control+control'
    % do nothing
  case 'shift+shift'
    % do nothing
  case 'alt+alt'
    % do nothing
  otherwise
    setappdata(h, 'opt', opt);
    %cb_help(h);
end
uiresume(h);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_redraw(h, eventdata)

h   = getparent(h);
opt = getappdata(h, 'opt');

curr_ax = get(h, 'currentaxes');

x1i  = opt.ijk1ref(1);
y1i  = opt.ijk1ref(2);
z1i  = opt.ijk1ref(3);

x2i  = opt.ijk2ref(1);
y2i  = opt.ijk2ref(2);
z2i  = opt.ijk2ref(3);

vol1 = squeeze(opt.data(x1i,y1i,z1i,:,:,:));
vol2 = opt.data(:,:,:,x2i,y2i,z2i);
info1 = getinfo_pos(vol1, opt.ijk1ref, opt.ijk1val);
info2 = getinfo_pos(vol2, opt.ijk2ref, opt.ijk2val);

% deal with left part of the figure
switch opt.method{1}
  case 'ortho'
    [vol1a,vol1b,vol1c] = makeortho(vol1);
    set(opt.handlesslice(1), 'CData', vol1a');
    set(opt.handlesslice(2), 'CData', vol1b');
    set(opt.handlesslice(3), 'CData', vol1c');
    set(opt.handlesaxes(1), 'clim', opt.clim1);
    set(opt.handlesaxes(2), 'clim', opt.clim1);
    set(opt.handlesaxes(3), 'clim', opt.clim1);
    crosshair([x1i z1i], 'handle', opt.handlescross(1,:));
    crosshair([y1i z1i], 'handle', opt.handlescross(2,:));
    crosshair([x1i y1i], 'handle', opt.handlescross(3,:));
  case 'slice'
    map = makemontage(vol1);
    set(opt.handlesslice(1), 'Cdata', map);
    set(opt.handlesaxes(1), 'clim', opt.clim1);
    crosshair(info1.id2d, 'handle', opt.handlescross(1,:));    
end

% deal with right part of the figure
switch opt.method{2}
  case 'ortho'
    [vol2a,vol2b,vol2c] = makeortho(vol2);
    set(opt.handlesslice(4), 'CData', vol2a');
    set(opt.handlesslice(5), 'CData', vol2b');
    set(opt.handlesslice(6), 'CData', vol2c');
    set(opt.handlesaxes(4), 'clim', opt.clim2);
    set(opt.handlesaxes(5), 'clim', opt.clim2);
    set(opt.handlesaxes(6), 'clim', opt.clim2);
    crosshair([x2i z2i], 'handle', opt.handlescross(4,:));
    crosshair([y2i z2i], 'handle', opt.handlescross(5,:));
    crosshair([x2i y2i], 'handle', opt.handlescross(6,:));
  case 'slice'
    map = makemontage(vol2);
    set(opt.handlesslice(5), 'Cdata', map);
    set(opt.handlesaxes(5), 'clim', opt.clim2);
    crosshair(info2.id2d, 'handle', opt.handlescross(4,:));    
end


p1 = opt.pos(info1.ind2,:);
p2 = opt.pos(info2.ind2,:);

set(opt.handlestext(1), 'string', sprintf('ind1=%6.0f\npos1=[%3.1f %3.1f %3.1f],\nval1=%f', info1.ind2,p1(1),p1(2),p1(3), info1.val2));
set(opt.handlestext(2), 'string', sprintf('ind2=%6.0f\npos2=[%3.1f %3.1f %3.1f],\nval2=%f', info2.ind2,p2(1),p2(2),p2(3), info2.val2));


set(h, 'currentaxes', curr_ax);

setappdata(h, 'opt', opt);
uiresume

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_buttonpress(h, eventdata)

h   = getparent(h);
opt = getappdata(h, 'opt');

cb_getposition(h);
opt = getappdata(h, 'opt');

seltype = get(h, 'selectiontype');
switch seltype
  case 'normal'
    % just update to new position, nothing else to be done here
    opt.ijk1ref = opt.ijk1;
    opt.ijk1val = opt.ijk1;
    opt.ijk2ref = opt.ijk2;
    opt.ijk2val = opt.ijk2;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  case 'alt'
    opt.ijk1val = opt.ijk1;
    opt.ijk2val = opt.ijk2;
    setappdata(h, 'opt', opt);
    cb_redraw(h);
  otherwise
end

uiresume;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_buttonrelease(h, eventdata)

seltype = get(h, 'selectiontype');
switch seltype
  case 'normal'
    % just update to new position, nothing else to be done here
  case 'alt'
    set(h, 'windowbuttonmotionfcn', '');  
  otherwise
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_tracemouse(h, eventdata)

h   = getparent(h);
cb_getposition(h);
opt = getappdata(h, 'opt');

n  = opt.radius;
if numel(n)==1, n = [n n n]; end

xi = opt.ijk(1)+(-n(1):n(1)); xi(xi>opt.dim(1)) = []; xi(xi<1) = [];
yi = opt.ijk(2)+(-n(2):n(2)); yi(yi>opt.dim(2)) = []; yi(yi<1) = [];
zi = opt.ijk(3)+(-n(3):n(3)); zi(zi>opt.dim(3)) = []; zi(zi<1) = [];

opt.mask(xi,yi,zi) = 0;
opt.data = opt.data & opt.mask;

setappdata(h, 'opt', opt);
cb_redraw(h);
uiresume;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_getposition(h, eventdata)

h   = getparent(h);
opt = getappdata(h, 'opt');

curr_ax = get(h,       'currentaxes');
pos     = get(curr_ax, 'currentpoint');

tag = get(curr_ax, 'tag');
switch tag
  case 'jk1'
    opt.ijk1([2,3]) = round(pos(1,1:2));
    opt.ijk2([2,3]) = round(pos(1,1:2));

  case 'ij1'
    opt.ijk1([1,2]) = round(pos(1,1:2));
    opt.ijk2([1,2]) = round(pos(1,1:2));

  case 'ik1'
    opt.ijk1([1,3]) = round(pos(1,1:2));
    opt.ijk2([1,3]) = round(pos(1,1:2));
    
  case 'map1'
    siz    = opt.dim(1:3);
    ndiv   = [ceil(sqrt(siz(3))) floor(sqrt(siz(3)))]; 
    pos    = round(pos(1,1:2));
    xcoord = rem(pos(1)-1, siz(1))+1;
    ycoord = rem(pos(2)-1, siz(2))+1;
    zcoord = floor(pos(2)./siz(2))*ndiv(1)+1+floor(pos(1)./siz(1));
    opt.ijk1 = [xcoord ycoord zcoord];
  
  case 'map2'
    siz    = opt.dim(4:6);
    ndiv   = [ceil(sqrt(siz(3))) floor(sqrt(siz(3)))]; 
    pos    = round(pos(1,1:2));
    xcoord = rem(pos(1)-1, siz(1))+1;
    ycoord = rem(pos(2)-1, siz(2))+1;
    zcoord = floor(pos(2)./siz(2))*ndiv(1)+1+floor(pos(1)./siz(1));
    opt.ijk2 = [xcoord ycoord zcoord];
  otherwise
end
opt.ijk1 = min(opt.ijk1, opt.dim(1:3));
opt.ijk1 = max(opt.ijk1, [1 1 1]);

opt.ijk2 = min(opt.ijk2, opt.dim(4:6));
opt.ijk2 = max(opt.ijk2, [1 1 1]);

setappdata(h, 'opt', opt);
uiresume;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb_cleanup(h, eventdata)

opt = getappdata(h, 'opt');
opt.quit = true;
setappdata(h, 'opt', opt);
uiresume
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = getparent(h)
p = h;
while p~=0
  h = p;
  p = get(h, 'parent');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function key = parseKeyboardEvent(eventdata)

key = eventdata.Key;

% handle possible numpad events (different for Windows and UNIX systems)
% NOTE: shift+numpad number does not work on UNIX, since the shift
% modifier is always sent for numpad events
if isunix()
  shiftInd = match_str(eventdata.Modifier, 'shift');
  if ~isnan(str2double(eventdata.Character)) && ~isempty(shiftInd)
    % now we now it was a numpad keystroke (numeric character sent AND
    % shift modifier present)
    key = eventdata.Character;
    eventdata.Modifier(shiftInd) = []; % strip the shift modifier
  end
elseif ispc()
  if strfind(eventdata.Key, 'numpad')
    key = eventdata.Character;
  end
end

if ~isempty(eventdata.Modifier)
  key = [eventdata.Modifier{1} '+' key];
end
  
