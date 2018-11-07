%This function takes the max-corrected statistical maps for a given
%scenario as well as the first-level permutation statistics and computes a 
%prevalence statistic for each voxel across scenarios

function [stats,combimask,confirmmask,T,Tshuf] = mous_multisetcca_prevalence(numsce,varargin)

%step 1: load in all per-scenario (first-level) statistics
% end up with one vector containing mxtxn correlations (m is sscenarios, t 
%is time and n is voxels) and one vector containing mxnxr correlations 
%(where r is permutation)
load atlas_conte69_8196reg_LR_brodmann_subparc.mat
for sce = 1:numsce
    datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',sce);
    load(fullfile(datadir, sprintf('scenario%d_max_results',sce)),'T','Tshuf');
    allT(sce,:,:)   = T;
    allTshuf(sce,:,:,:) = Tshuf;
end

%not sure how to deal with negative correlations, generally not interested
%in those, as difficult to interpret?
allT(allT<0)            = 0;
allTshuf(allTshuf<0)    = 0;
%step 2: choose the minimum correlation across scenarios per voxel and time
%same for each permutation, if too many permutations make subselection
mT       = squeeze(min(allT));
mTshuf   = squeeze(min(allTshuf)); %FIXME is this correct or do I need to concat permutations??

%step 3: determine uncorrected p-value for global null hypothesis at each voxel, i.e. the
%fraction of combined-permutation values being larger or equal to the
%actual value (1/r sum(permutation is bigger than actual value))
[m,n,z] = size(mTshuf);
p = sum(reshape(mTshuf,[m*n z])>mT(:),2)/z;
p = reshape(p,[m,n]);

%step 4: to correcct for multiple comparison,take maximum statistic across
%voxels for each combined permutation. compute p-value for spatially
%extended global null hypotehsis, i.e. the fraction of combined permutation
%maximum values beging larger or equal actual value.

%step 5: prevalence
%