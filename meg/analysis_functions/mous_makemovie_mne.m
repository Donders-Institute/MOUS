function frames = mous_makemovie_mne(source, filename, varargin)

% MOUS_MAKEMOVIE_MNE produces an *.avi movie from a source-level functional
% image, defined on the registered 8196-node cortical sheet, where the 
% functional data is defined across time.
% 
% Use as:
%   mous_makemovie_mne(source, filename, key1, value1, key2, value2, ...)
%
% Input arguments:
%   source = a source-structure (or derivations thereof) that has a direct
%            mapping to the cortical sheet (8196 nodes registered to freesurfer_LR)
%            it can also be a parcellation, in that case the corresponding parcellation
%            needs to be provided
%   filename = the filename of the .avi file
%
% Additional arguments have to be provided as key-value pairs:
%   parameter = string, functional parameter to be plotted
%   zlim      = [min max], limits that constrain the color scale
%   xlim      = vector, specifying the time limits per frame, default is 1 time point per frame,
%   baselinecorrect = 'yes' (default) or 'no', perform baselinecorrection on the time series
%   baselinewindow  = [min max], limits of baseline windoew
%   maskparameter   = TO-BE-IMPLEMENTED
%   parcellation    = parcellation-structure that describes the parcels. at present it should be 
%                     defined in the field 'parcellation'
%   hemisphere      = 'both' (default), 'left', 'right' the hemisphere(s) to be plotted
%   viewmode        = 'both' (default), 'lateral', 'medial', the viewmode 

%% set the parameters
parameter = ft_getopt(varargin, 'parameter', 'avg');
zlim      = ft_getopt(varargin, 'zlim', []);
xlim      = ft_getopt(varargin, 'xlim', []);
demean    = ft_getopt(varargin, 'demean', 'yes');
demean    = ft_getopt(varargin, 'baselinecorrect', demean);
baselinewindow = ft_getopt(varargin, 'baselinewindow', [-inf 0]);
maskparameter  = ft_getopt(varargin, 'maskparameter',  []);
parcellation   = ft_getopt(varargin, 'parcellation', []);
hemimode       = ft_getopt(varargin, 'hemisphere', 'both');
viewmode       = ft_getopt(varargin, 'viewmode',   'both');
textstring     = ft_getopt(varargin, 'textstring', 'time = ');
%% deal with xlim and zlim
if isempty(xlim)
  dtime  = mean(diff(source.time));
  xlim   = source.time - dtime/2;
  xlim(end+1) = source.time(end) + dtime/2;
end

if isempty(zlim)
  zlim   = [-1 1]*max(abs(source.(parameter)(:))).*0.9;
end

%% get the functional data
if ~isempty(parcellation)
  data = unparcellate(source, parcellation, parameter);
else
  data = getsubfield(source, parameter);
end

% baseline normalise
if istrue(demean)
  ix(1) = nearest(source.time,baselinewindow(1));
  ix(2) = nearest(source.time,baselinewindow(2));
  m     = nanmean(data(:,ix(1):ix(2)),2);
  data  = data./(m*ones(1,numel(source.time)))-1;
end

%% use the inflated cortex for display purposes: THIS DOES NOT WORK IF THE DATA IS REPRESENTED ON A DIFFERENT MESH
load cortex_inflated_8196reg

s      = sourcemodel;
s.sulc = s.sulc - min(s.sulc) + 0.3;
s.sulc = s.sulc./max(s.sulc);

indxl    = 1:4098;
indxltri = find(sum(s.tri<=4098,2)==3);
minpntl  = min(s.pnt(indxl,:),[],1);
maxpntl  = max(s.pnt(indxl,:),[],1);
refpntl  = [maxpntl(1) minpntl(2) 0;
            minpntl(1) minpntl(2) 0;
            minpntl(1) maxpntl(2) 0;
            maxpntl(1) maxpntl(2) 0];
          
indxr    = (1:4098)+4098;
indxrtri = find(sum(s.tri>4098,2)==3);
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

tl1(1:3,4) = refpntl(1,:) - ft_warp_apply(rl,refpntl(1,:));
tr1(1:3,4) = refpntr(1,:) - ft_warp_apply(rr,refpntr(1,:));

tl2 = eye(4);
tr2 = eye(4);
tl2(1:3,4) = ft_warp_apply(rl,refpntl(4,:)) - ft_warp_apply(rr,refpntl(2,:));
tr2(1:3,4) = ft_warp_apply(rr,refpntr(2,:)) - ft_warp_apply(rl,refpntr(4,:));

% composite matrix to expose the lateral surface of both hemispheres
hl1 = tl1*rl; hl1(3,4) = maxpntl(3)*1.05;
hr1 = tr1*rr; hr1(3,4) = maxpntr(3)*1.05;

% composite matrix to expose the medial surface of both hemispheres
hl2 = tl2*tl1*rr; hl2(3,4) = minpntl(3)*1.05;
hr2 = tr2*tr1*rl; hr2(3,4) = minpntr(3)*1.05;% rotation is intentionally flipped

s.pnt(indxl,:) = ft_warp_apply(hl1,sourcemodel.pnt(indxl,:));
s.pnt(indxr,:) = ft_warp_apply(hr1,sourcemodel.pnt(indxr,:));
s.pnt(indxl+8196,:) = ft_warp_apply(hl2,sourcemodel.pnt(indxl,:));
s.pnt(indxr+8196,:) = ft_warp_apply(hr2,sourcemodel.pnt(indxr,:));

s.sulc = repmat(s.sulc,[2 1]);
s.curv = repmat(s.curv,[2 1]);
s.tri  = [s.tri;s.tri + 8196];

% this is needed when presenting both medial and lateral views
data = repmat(data,[2 1]);

usepnt = true(size(data,1),1);
usetri = true(size(s.tri,1),1);

xpos_text = -200;
switch hemimode
  case 'left'
    usepnt(indxr)      = false;
    usepnt(indxr+8196) = false;
    usetri(indxrtri)   = false;
    usetri(indxrtri+16384) = false;
  case 'right'
    usepnt(indxl)      = false;
    usepnt(indxl+8196) = false;
    usetri(indxltri)   = false;
    usetri(indxltri+16384) = false;
    xpos_text = 0;
  case 'both'
    % do nothing
end

ypos_text = -200;
switch viewmode
    case 'lateral'
      usepnt([indxl;indxr]+8196) = false;
      usetri((1:16384)+16384)    = false;
      ypos_text                  = -20;
    case 'medial'
      usepnt([indxl;indxr]) = false;
      usetri(1:16384)       = false;
    case 'both'
      % do nothing
end

data = data(usepnt,:);
s.pnt = s.pnt(usepnt,:);
s.tri = tri_reindex(s.tri(usetri,:));
s.sulc = s.sulc(usepnt);
s.curv = s.curv(usepnt);

h = figure; view([0 0]); hold on; set(h, 'color', 'k');
ft_plot_mesh(s, 'edgecolor', 'none', 'vertexcolor', repmat(s.sulc, [1 3]));
textstring = [textstring,num2str(source.time(1),'%1.2f')];
htxt = text(xpos_text,0,ypos_text,textstring);
set(htxt, 'color', 'w');
set(htxt, 'fontsize', 15);

hfun1 = ft_plot_mesh(s, 'edgecolor', 'none', 'vertexcolor', data(:,1), 'facealpha', 0.6);%data(:,1));
%set(hfun1, 'FaceVertexAlphaData', 0.5*ones(size(data,1),1));
%set(hfun1, 'alphadatamapping', 'scaled');
%set(hfun1, 'FaceAlpha', 'flat');

caxis(zlim);

% Prepare the new file.
vidObj = VideoWriter(filename);
vidObj.FrameRate = 15;

open(vidObj);
abc = get(gcf, 'position');
for k = 1:numel(xlim)-1
  ix(1) = nearest(source.time, xlim(k)+eps*100);
  ix(2) = nearest(source.time, xlim(k+1));
  dat   = nanmean(data(:,ix(1):ix(2)),2);
  set(hfun1, 'FaceVertexCData',     dat(:));
  %alphadat = abs(dat(:));%-min(data(:));%./(cmax);
  %alphadat(alphadat>0.3) = 0.3;
  %alphadat(alphadat<0.15) = 0;
  %alphadat(~isfinite(alphadat))=0;
  %set(hfun1, 'FaceVertexAlphaData', alphadat);
  textstring = ['time = ',num2str(mean(source.time(ix)),'%1.2f')];
  set(htxt, 'string', textstring);

  currFrame   = getframe(gcf,[1 1 abc(3:4)-1]);
  frames(k,1) = currFrame;
  writeVideo(vidObj, currFrame);
end

% Close the file.
close(vidObj);

close all;

function fun = unparcellate(data, parcellation, parameter)

tmp = getsubfield(data, parameter);
fun = zeros(size(parcellation.pos, 1), size(tmp, 2));
for k = 1:numel(data.label)
  sel = match_str(parcellation.parcellationlabel, data.label{k});
  if ~isempty(sel)
    sel = parcellation.parcellation==sel;
    fun(sel,:) = repmat(tmp(k,:), [sum(sel) 1]);
  end
end

function [newtri] = tri_reindex(tri)

%this function reindexes tri such that they run from 1:number of unique vertices

newtri       = tri;
[srt, indx]  = sort(tri(:));
tmp          = cumsum(double(diff([0;srt])>0));
newtri(indx) = tmp;
