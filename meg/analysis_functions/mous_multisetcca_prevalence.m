%This function takes the cluster-corrected statistical maps for a given
%scenario as well as the first-level permutation statistics and computes a
%prevalence statistic for each voxel across scenarios using the toolbox from
%Allefeld et al.(2016)
%https://github.com/allefeld/prevalence-permutation

function mous_multisetcca_prevalence(rootdir,savedir,numsce)

%step 1: load in all per-scenario (first-level) statistics
% end up with one vector containing mxtxn correlations (m is sscenarios, t
%is time and n is voxels) and one vector containing mxnxr correlations
%(where r is permutation)
for sce = 1:numsce
    datadir = sprintf(fullfile(rootdir,'scenario%d'),sce);
    load(fullfile(datadir, sprintf('scenario%d_results_sent_contentwords',sce)),'T','Tshuf');
    
    allT(sce,:,:,1)     = T;
    allT(sce,:,:,2:1001) = Tshuf;
end

%ignoring negative correlations
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
time = s.time;

save(fullfile(savedir,'prevalence',date), 'time', 'mT','results','params');
