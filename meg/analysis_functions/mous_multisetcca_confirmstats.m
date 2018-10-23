%This function takes the max-corrected statistical maps for a given
%scenario and tests for each voxel whether the result replicates across all
%other scenarios
function [stats,combimask,confirmmask] = mous_multisetcca_confirmstats(numsce,varargin)

% load data from all scenarios
load atlas_conte69_8196reg_LR_brodmann_subparc.mat
for sce = 1:numsce
    datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',sce);
    load(fullfile(datadir, sprintf('scenario%d_max_results',sce)),'T','Tshuf');
    allT(sce,:,:)   = T;
    allTshuf(sce,:,:,:) = Tshuf;
end

for sce = 1:numsce
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',sce);
load(fullfile(datadir, sprintf('scenario%d_max_results',sce)),'s');
allmask{sce}    = s.mask;
T               = squeeze(mean(allT(~ismember([1:numsce],sce),:,:)));
[nsce,p,t,perm] = size(allTshuf(~ismember([1:numsce],sce),:,:,:));
Tshuf           = reshape(permute(allTshuf(~ismember([1:numsce],sce),:,:,:),[2 3 1 4]),[p t nsce*perm]);

T(~s.mask) = 0;%FIXME how to deal with data selection based on roi? (guess nulling out is fine)
Tshuf(repmat(~s.mask,1,2000)) = 0;
statobs  = reshape(T,[],1);
statrand = reshape(Tshuf,[],size(Tshuf,3));

cfg     = [];
cfg.dim = size(Tshuf(:,:,1));
cfg.numrandomization = size(Tshuf,3);

cfg.correctm = 'max';

prb_pos   = zeros(size(statobs));
for i=1:size(Tshuf,3)
    % compare each data element with the maximum statistic
    prb_pos = prb_pos + (statobs<max(statrand(:,i)));
    posdistribution(i) = max(statrand(:,i));
end
stats{sce}.prob = prb_pos./size(Tshuf,3);
stats{sce}.prob = reshape(stats{sce}.prob,cfg.dim);
stats{sce}.prob(~s.mask) = nan;
stats{sce}.mask = stats{sce}.prob<=0.05;
stats{sce}.mask(~s.mask) = 0;
stats{sce}.posdistribution = posdistribution;

stats{sce}.time = s.time;
stats{sce}.dimord = 'chan_time';
stats{sce}.label  = atlas.parcellationlabel;
stats{sce}.stat   = T;
stats{sce}.stat(~isfinite(stats{sce}.stat)) = 0; stats{sce}.stat([1 2 194 195],:) = nan;
stats{sce}.brainordinate = atlas;

end

combimask   = any(cat(3,allmask{:}),3);
confirmmask = any(cat(3,allconfirm{:}),3);
end
