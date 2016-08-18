 function parcellation = mous_mne_makeparcellation(subjectname, n)

% MOUS_MNE_MAKEPARCELLATION creates a parcellation of the cortical sheet
% based on the source-level correlation matrix.
%
% Use as 
%   [parcellation] = mous_mne_makeparcellation(subjectname, n)
%
% Input arguments
%   subjectname = string
%   n = scalar, number of parcels

fprintf('loading data...\n');
mous_db_getdata(subjectname, 'meg_mne_allwords_02-nextword_sent');
mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword');

% select the MEG channels and comput the channel level covariance
fprintf('computing channel covariance...\n');
cfg         = [];
cfg.channel = 'MEG';
data        = ft_selectdata(cfg, data);
C           = cov(data.trial);

% getting the estimated orientation aligned with the vertex normals

% check the consistency of the orientation of the normals (either all
% pointing in or outward)

% first check the consistency of the orientation in the mesh
mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
npnt = size(bnd.pos,1)/2;
ntri = size(bnd.tri,1)/2;

pnt1  = bnd.pos(1:npnt,:);
tri1  = double(bnd.tri(1:ntri,:));
m1    = mean(pnt1);
m1(2) = m1(2)-1; % assume left hemisphere, shift the center a bit to the right
pnt1  = pnt1 - m1(ones(npnt,1),:);
w1    = sum(solid_angle(pnt1, tri1));
  
pnt2  = bnd.pos((1:npnt)+npnt,:);
tri2  = double(bnd.tri((1:ntri)+ntri,:));
m2    = mean(pnt2);
m2(2) = m2(2)+1;
pnt2  = pnt2 - m2(ones(npnt,1),:);
w2    = sum(solid_angle(pnt2, tri2-max(tri1(:))));

if w1<0 && w2<0 && abs(w1)-4*pi<1000*eps && abs(w2)-4*pi<1000*eps
  % do nothing: this is what MNE seems to return
elseif w>0 && w2>0 && abs(w1)-4*pi<1000*eps && abs(w2)-4*pi<1000*eps
  tri1 = fliplr(tri2);
  tri2 = fliplr(tri1);
else
  error('mesh is inconsistent');
end
bnd.tri = [tri1; tri2];

% get the normals of the sourcemodel mesh
nrm     = normals(bnd.pos, bnd.tri, 'vertex');

% get the sign of the angle between the mesh normals and the estimated
% orientation (which is 'ambiguous')
ori     = zeros(8196,3);
for k = source.inside(:)'
  ori(k,:) = source.avg.ori{k};
end
dot_nrmori = sum(nrm.*ori,2);
sel_flip   = find(dot_nrmori<0);
ori(sel_flip,:) = -ori(sel_flip,:);

% create a matrix with the spatial filters
fprintf('getting the spatial filters...\n');
in = source.inside;
W  = zeros(8196,273);
for k = in(:)'
  %W(k,:) = source.avg.ori{k}*source.avg.filter{k};
  W(k,:) = ori(k,:)*source.avg.filter{k};
end

% create the neighbourhood matrix for the triangulation
Ctri = double(triangle2connectivity(source.tri));
Ctri = Ctri*Ctri*Ctri*Ctri;
Ctri = Ctri>0;

%D = dist(source.pos');
%D(D>0.04) = 0.04;
%D(1:4098, 4099:end) = 0.04;
%D(4099:end, 1:4098) = 0.04;
%D = D.* 100;
%D = exp(-(D.^2));

%D = (0.04.^2 - D.^2)./(0.04.^2);

% get the source level correlation matrix and zero out all non neighbours
fprintf('computing the source correlation matrix...\n');
C          = W*C*W';
C          = C./sqrt(diag(C)*diag(C)');
%C(Ctri==0) = 0;
%C          = abs(C);

%C = abs(C).*D;

C(1:4098, 4099:end) = 0;
C(4099:end, 1:4098) = 0;
C(Ctri==0) = 0;
C = C.^2;
% use a graph cut algorithm for the creation of parcels
fprintf('parcellating...\n');
addpath ~/matlab/toolboxes/Ncut_9/
opt.valeurMin = 2e-1;
indx = ncutW(C(in,in), n, opt);

lab  = zeros(8196,1);
cnt  = 1;
for k = 1:n
  if sum(indx(:,k))>0,
    cnt = cnt+1;
  end
  lab(in(indx(:,k)==1)) = cnt;
end
n = cnt;

label = cell(n,1);
for k = 1:n
  label{k} = ['parcel',num2str(k, '%03d')];
end

fprintf('creating output...\n');
parcellation     = [];
parcellation.pos = source.pos;
parcellation.tri = source.tri;
parcellation.ori = ori;
parcellation.parcellationlabel = label;
parcellation.parcellation = lab;
parcellation.inside  = source.inside;
parcellation.outside = source.outside;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [connmat] = triangle2connectivity(tri)

% TRIANGLE2CONNECTIVITY computes a connectivity-matrix from a triangulation.
%
% Use as
%  [connmat] = triangle2connectivity(tri)
%
% The input tri is an Nx3 matrix describing a triangulated surface,
% containing indices to connecting vertices
% The output connmat is a sparse logical NxN matrix, with ones, where vertices
% are connected, and zeros otherwise.

% ensure that the vertices are indexed starting from 1
if min(tri(:))==0,
  tri = tri + 1;
end

% ensure that the vertices are indexed according to 1:number of unique vertices
tri = tri_reindex(tri);

% create the unique edges from the triangulation
edges  = [tri(:,[1 2]); tri(:,[1 3]); tri(:,[2 3])];
edges  = double(unique(sort([edges; edges(:,[2 1])],2), 'rows'));

% fill the connectivity matrix
n        = size(edges,1);
connmat  = sparse([edges(:,1);edges(:,2)],[edges(:,2);edges(:,1)],true(2*n,1));

function [newtri] = tri_reindex(tri)

% this subfunction reindexes tri such that they run from 1:number of unique vertices
newtri       = tri;
[srt, indx]  = sort(tri(:));
tmp          = cumsum(double(diff([0;srt])>0));
newtri(indx) = tmp;
