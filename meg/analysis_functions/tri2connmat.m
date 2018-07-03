function [connmat] = tri2connmat(tri, pos)

% TRI2CONNMAT computes a connectivity-matrix from a triangulated mesh.
%
% Use as
%  [connmat] = tri2connmat(tri)
%
% or
%  [connmat] = tri2connmat(tri, pos)
%
% The input tri is an Nx3 matrix describing a triangulated surface,
% containing indices to connecting vertices. 
% The output connmat is a sparse NxN matrix, with ones, where vertices
% are connected, and zeros otherwise. If a second input pos is
% provided (Mx3 matrix with the positions of the vertices in 3D space), the
% values in connmat represent 1/(edge length)

% ensure that the vertices are indexed starting from 1
if min(tri(:))==0,
  tri = tri + 1;
end

% ensure that the vertices are indexed according to 1:number of unique vertices
tri = tri_reindex(tri);

% create the unique edges from the triangulation
edges  = [tri(:,[1 2]); tri(:,[1 3]); tri(:,[2 3])];
edges  = double(unique(sort([edges; edges(:,[2 1])],2), 'rows'));

if nargin<2
  % fill the connectivity matrix
  n        = size(edges,1);
  connmat  = sparse([edges(:,1);edges(:,2)],[edges(:,2);edges(:,1)],ones(2*n,1));
else
  n        = size(edges,1);
  d        = zeros(2*n,1);
  for k = 1:n
    tmpd = sqrt(sum((pos(edges(k,1),:)-pos(edges(k,2),:)).^2,2));
    d(k) = 1./tmpd;
    d(k+n) = 1./tmpd;
  end
  connmat = sparse([edges(:,1);edges(:,2)],[edges(:,2);edges(:,1)],d);
end
function [newtri] = tri_reindex(tri)

% this subfunction reindexes tri such that they run from 1:number of unique vertices
newtri       = tri;
[srt, indx]  = sort(tri(:));
tmp          = cumsum(double(diff([0;srt])>0));
newtri(indx) = tmp;
