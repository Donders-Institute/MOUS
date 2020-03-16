function connmat = parcellation2connectivity(data, varargin)

% PARCELLATION2CONNECTIVITY computes a binary parcel-wise connectivity matrix 
%
% Use as:
%   connmat = parcellation2connectivity(data, varargin)

parcellation = ft_getopt(varargin, 'parcellation','parcellation');
if isempty(parcellation)
  error('a parcellation needs to be specified in order to compute connectivity between parcels');
end

connectmidline = ft_getopt(varargin, 'connectmidline', true);

tri = data.tri;

% ensure that the vertices are indexed starting from 1
if min(tri(:))==0,
  tri = tri + 1;
end

% ensure that the vertices are indexed according to 1:number of unique vertices
tri = tri_reindex(tri);

% create the unique edges from the triangulation
edges  = [tri(:,[1 2]); tri(:,[1 3]); tri(:,[2 3])];
edges  = double(unique(sort([edges; edges(:,[2 1])],2), 'rows'));

% get the parcel values for the edges that 'go across parcels'
boundary = data.(parcellation)(edges);
boundary = boundary(boundary(:,1)~=boundary(:,2),:);
boundary = unique([boundary; boundary(:,[2 1])], 'rows');

% fill the connectivity matrix
n        = size(boundary,1);
connmat  = sparse(boundary(:,1),boundary(:,2),ones(n,1));

% as an optional step, also connect the homologous parcels across the midline
if connectmidline
  % try and find pairs of L_ and R_ parcels (this is the assumption in the
  % label names
  label = data.([parcellation 'label']);
  for k = 1:numel(label)
    pairs(k,1) = match_str(label, ['L_' label{k}(3:end)]);
    pairs(k,2) = match_str(label, ['R_' label{k}(3:end)]);
  end
  pairs = unique(pairs, 'rows');
  for k = 1:size(pairs,1)
    p1(k,:) = mean(data.pos(data.(parcellation)==pairs(k,1),:));
    p2(k,:) = mean(data.pos(data.(parcellation)==pairs(k,2),:));
  end
  D = sqrt(sum((p1-p2).^2,2));
  D = (D-mean(D))./std(D);
  
  pairs = pairs(D<-1,:);
  for k = 1:size(pairs,1)
    connmat(pairs(k,1),pairs(k,2)) = true;
    connmat(pairs(k,2),pairs(k,1)) = true;
  end
end

function [newtri] = tri_reindex(tri)

% this subfunction reindexes tri such that they run from 1:number of unique vertices
newtri       = tri;
[srt, indx]  = sort(tri(:));
tmp          = cumsum(double(diff([0;srt])>0));
newtri(indx) = tmp;
