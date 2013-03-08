function mous_connectivitybrowser(grid, source, parameter, anasc, cohsc)

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


if nargin<4
  anasc = [];
end
if nargin<5
  cohsc = [];
end

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
if isempty(anasc)
c1min = min(coh(:));
c1max = max(coh(:));
else
c1min = anasc(1);
c1max = anasc(2);
end


if isempty(cohsc)
  c2min = min(coh(:));
  c2max = max(coh(:));
else
  c2min = cohsc(1);
  c2max = cohsc(2);
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
h1a = axes( 'position', [0.05 0.55 0.20 0.4], 'tag', 'ik'); 
h1b = axes( 'position', [0.3  0.55 0.20 0.4],  'tag', 'jk'); 
h1c = axes( 'position', [0.05 0.10 0.20 0.4], 'tag', 'ij'); 
h1d = axes( 'position', [0.3  0.10 0.20 0.4]); axis off;
h2a = axes( 'position', [0.57 0.15 0.4 0.8]); 
h2d = axes( 'position', [0.55  0.05 0.55 0.55]); axis off

% initialize left part of the figure
vol1 = coh(:,:,:,x1i,y1i,z1i);
vol1(~isfinite(vol1))=0;
vol1a=squeeze(max(vol1,[],2));
vol1b=squeeze(max(vol1,[],1));
vol1c=squeeze(max(vol1,[],3));
  
hs1a = imagesc(x, z, vol1a', 'parent', h1a); 
axis equal; axis tight; 
hs1b = imagesc(y, z, vol1b', 'parent', h1b); 
axis equal; axis tight; 
hs1c = imagesc(x, y, vol1c', 'parent', h1c); 
axis equal; axis tight; axis off;

set(h1a, 'tag', 'ik', 'ydir', 'normal', 'visible', 'off');
set(h1b, 'tag', 'jk', 'ydir', 'normal', 'visible', 'off');
set(h1c, 'tag', 'ij', 'ydir', 'normal', 'visible', 'off');

% initialize right part of the figure
map  = makemontage(coh(:,:,:,x1i,y1i,z1i));
hs2a = imagesc(map, 'parent', h2a);
set(h2a, 'tag', 'map', 'ydir', 'normal', 'visible', 'off');
colormap jet;

hc1a = crosshair([x1i z1i], 'color', 'yellow', 'parent', h1a);
hc1b = crosshair([y1i z1i], 'color', 'yellow', 'parent', h1b);
hc1c = crosshair([x1i y1i], 'color', 'yellow', 'parent', h1c);

info = getinfo_pos(squeeze(coh(x1i,y1i,z1i,:,:,:)), coh(:,:,:,x1i,y1i,z1i),  [x1i y1i z1i], [x2i y2i z2i]);

p1   = grid.pos(info.ind1,:);
p2   = grid.pos(info.ind2,:);

hc2  = crosshair(info.id2d, 'color', 'm', 'parent', h2a);
ht1  = text(0,0,sprintf('ind1=%6.0f\npos1=[%3.1f %3.1f %3.1f],\nval1=%f', info.ind1,p1(1),p1(2),p1(3), info.val1), 'parent', h1d);
ht2  = text(0,0,sprintf('ind2=%6.0f\npos2=[%3.1f %3.1f %3.1f],\nval2=%f', info.ind2,p2(1),p2(2),p2(3), info.val2), 'parent', h2d);

% create structure to be passed to gui
opt.data          = coh;
opt.handlesaxes   = [h1a  h1b  h1c  h1d h2a  h2d];
opt.handlesslice  = [hs1a hs1b hs1c nan hs2a nan];
opt.handlescross  = [hc1a(:)';hc1b(:)';hc1c(:)';hc2(:)'];
opt.handlestext   = [ht1 ht2];
opt.ijk1          = [x1i y1i z1i];
opt.ijk2          = [x2i y2i z2i];
opt.clim1         = [c1min c1max];
opt.clim2         = [c2min c2max];
opt.dim           = size(coh);
opt.pos           = grid.pos;
opt.quit          = 0;

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
function info = getinfo_pos(dat1, dat2, coord1, coord2)

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
val2 = dat2(x2i,y2i,z2i);

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

x1i  = opt.ijk1(1);
y1i  = opt.ijk1(2);
z1i  = opt.ijk1(3);

x2i  = opt.ijk2(1);
y2i  = opt.ijk2(2);
z2i  = opt.ijk2(3);

vol1 = squeeze(opt.data(x1i,y1i,z1i,:,:,:));
vol2 = opt.data(:,:,:,x1i,y1i,z1i);
map  = makemontage(vol2);


set(opt.handlesslice(1), 'CData', squeeze(vol1(:,y2i,:))');
set(opt.handlesslice(2), 'CData', squeeze(vol1(x2i,:,:))');
set(opt.handlesslice(3), 'CData', vol1(:,:,z2i)');
set(opt.handlesslice(5), 'Cdata', map);

set(opt.handlesaxes(1), 'clim', opt.clim1);
set(opt.handlesaxes(2), 'clim', opt.clim1);
set(opt.handlesaxes(3), 'clim', opt.clim1);
set(opt.handlesaxes(5), 'clim', opt.clim2);

crosshair([x1i z1i], 'handle', opt.handlescross(1,:));
crosshair([y1i z1i], 'handle', opt.handlescross(2,:));
crosshair([x1i y1i], 'handle', opt.handlescross(3,:));

info = getinfo_pos(vol1, vol2, opt.ijk1, opt.ijk2);
crosshair(info.id2d, 'handle', opt.handlescross(4,:));

p1 = opt.pos(info.ind1,:);
p2 = opt.pos(info.ind2,:);
set(opt.handlestext(1), 'string', sprintf('ind1=%6.0f\npos1=[%3.1f %3.1f %3.1f],\nval1=%f', info.ind1,p1(1),p1(2),p1(3), info.val1));
set(opt.handlestext(2), 'string', sprintf('ind2=%6.0f\npos2=[%3.1f %3.1f %3.1f],\nval2=%f', info.ind2,p2(1),p2(2),p2(3), info.val2));


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
    cb_redraw(h);
  case 'alt'
    set(h, 'windowbuttonmotionfcn', @cb_tracemouse);
    opt = getappdata(h, 'opt');
    cb_redraw(h);
  otherwise
end

setappdata(h, 'opt', opt);

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
  case 'jk'
    opt.ijk1([2,3]) = round(pos(1,1:2));
    opt.ijk2([2,3]) = round(pos(1,1:2));

  case 'ij'
    opt.ijk1([1,2]) = round(pos(1,1:2));
    opt.ijk2([1,2]) = round(pos(1,1:2));

  case 'ik'
    opt.ijk1([1,3]) = round(pos(1,1:2));
    opt.ijk2([1,3]) = round(pos(1,1:2));

  case 'map'
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
  
