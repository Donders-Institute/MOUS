%This function takes the max-corrected statistical maps for a given
%scenario as well as the first-level permutation statistics and computes a
%prevalence statistic for each voxel across scenarios using implementation from
%Allefeld 2016

function [stats,combimask,confirmmask,T,Tshuf] = mous_multisetcca_prevalence(numsce,varargin)

%step 1: load in all per-scenario (first-level) statistics
% end up with one vector containing mxtxn correlations (m is sscenarios, t
%is time and n is voxels) and one vector containing mxnxr correlations
%(where r is permutation)
for sce = 1:numsce
    datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',sce);
    load(fullfile(datadir, sprintf('scenario%d_max_results',sce)),'T','Tshuf');
    allT(sce,:,:,1)     = T;
    allT(sce,:,:,2:501) = Tshuf;
end

%not sure how to deal with negative correlations, generally not interested
%in those, as difficult to interpret?
allT(allT<0)            = 0;
[s,v,t,i]               = size(allT);
a                    = reshape(permute(allT,[2 3 1 4]),[v*t s i]);

[results, params] = prevalenceCore(a);

%reshape resulting matrix into voxelXtime matrix
mT      = squeeze(mean(squeeze(allT(:,:,:,1))));
nanind  = ~isfinite(mT);
results = structfun(@(x)reshape(x,[v t]),results,'UniformOutput',0);
results.gamma0c(nanind) = nan;
results.pcMN(nanind)    = nan;
results.pcGN(nanind)    = nan;

