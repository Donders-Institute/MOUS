%This function takes the max-corrected statistical maps for a given
%scenario and tests for each voxel whether the result replicates across all
%other scenarios
function [stats, T, Tshuf] = mous_multisetcca_confirmstats(scenario,varargin)

% load data from all scenarios
datadir = '/project/3011020.09/jansch/mscca_group/';

for sce = 1:5
    load(fullfile(datadir, sprintf('scenario%d_results',sce)),'T','Tshuf');
    allT(sce,:,:)   = T;
    allTshuf(sce,:,:,:) = Tshuf;
end
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
load(fullfile(datadir, sprintf('scenario%d_max_results',scenario)),'s');

T               = squeeze(mean(allT(~ismember([1:5],sce),:,:)));
[sce,p,t,perm]    = size(allTshuf(~ismember([1:5],sce),:,:,:));
Tshuf           = reshape(permute(allTshuf(~ismember([1:5],sce),:,:,:),[2 3 1 4]),[p t sce*perm]);

load atlas_conte69_8196reg_LR_brodmann_subparc.mat

T(~s.mask) = 0;%FIXME how to deal with data selection based on roi? (guess nulling out is fine)
Tshuf(repmat(s.mask,1,2000)) = 0;
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
stats.prob = prb_pos./size(Tshuf,3);
stats.prob = reshape(stats.prob,cfg.dim);
stats.prob(~s.mask) = nan;
stats.mask = stats.prob<=0.05;
stats.mask(~s.mask) = 0;
stats.posdistribution = posdistribution;

stats.time = s.time;
stats.dimord = 'chan_time';
stats.label  = atlas.parcellationlabel;
stats.stat   = T;
stats.stat(~isfinite(stats.stat)) = 0; stats.stat([1 2 194 195],:) = nan;
stats.brainordinate = atlas;

end