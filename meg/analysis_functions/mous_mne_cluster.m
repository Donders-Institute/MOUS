function [output] = mous_mne_cluster(source, varargin)

% example use:
%  output = mous_mne_clusters(source, 'threshold', 0.2, 'parameter',
%  'avg.dspm');
%
% visualization of the time courses in the clusters can be done with:
%  figure;plot(output.time,output.avg);
% visualization of the topography of the clusters can be done with:
%  output.pos = source.pos_infl; (if you want to see it on the inflated
%  surface
%  figure;ft_plot_mesh(output, 'edgecolor', 'none', 'vertexcolor',
%  clus.ntime(:,k)); (where k is the number of the cluster you want to see
%
% additional options:
%  -neighbourdist
%  -minnbvert

parameter = ft_getopt(varargin, 'parameter', 'avg.dspm');
threshold = ft_getopt(varargin, 'threshold', []);
neighbourdist = ft_getopt(varargin, 'neighbourdist', 0.75);
minnbvert = ft_getopt(varargin, 'minnbvert', 3);

if isempty(threshold)
  error('you should specify a threshold for the clustering');
end

% create a neighbourhood matrix for clustering
npos         = size(source.pos,1);
neighbmatrix = false(npos);
for kk = 1:npos
  tmp  = source.pos(kk,:);
  dmat = source.pos - ones(npos,1)*tmp;
  dmat = sqrt(sum(dmat.^2,2));
  neighbmatrix(find(dmat<neighbourdist), kk) = true;
  neighbmatrix(kk,kk) = false;
end
% transpose according to Eric's definition
% each row represents a voxel's neighbours
neighbmatrix = neighbmatrix';
  
dat     = getsubfield(source, parameter);
clusmat = findcluster(dat>threshold, neighbmatrix, minnbvert);

% process the clusters
nclus = max(clusmat(:));
clus  = struct('avg', [], 'posindx', [], 'timeindx', [], 'npos', [], 'ntime', []);
%%
for k = 1:nclus
  clus(k).posindx  = sum(clusmat==k,2)>0;
  clus(k).timeindx = sum(clusmat==k,1)>0;
  clus(k).avg      = nanmean(dat(clus(k).posindx,:),1);
  clus(k).npos     = sum(clusmat==k,1);
  clus(k).ntime    = sum(clusmat==k,2);
end

output = [];
output.pos  = source.pos;
output.tri  = source.tri;
output.topo = double(cat(2,clus.posindx));
output.avg  = cat(1,clus.avg);
output.time = source.time;
output.npos = cat(1,clus.npos);
output.ntime = cat(2,clus.ntime);