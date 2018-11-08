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

%plot
%1. mask parcels where global null is rejected
%2. plot values of lower bound gamma
%3. 2nd plot with median correlation?

load atlas_conte69_8196reg_LR_brodmann_subparc.mat
load ~/MOUS/meg/templates/cortex_midthickness_8196reg.mat
cmap = brewermap(6,'YlOrRd');
load(fullfile(datadir, sprintf('scenario%d_results',sce)));

%create source structure for plotting
source1                = [];
source1.brainordinate  = atlas;
source1.label          = atlas.parcellationlabel;
source1.time           = s.time;
source1.dimord         = 'chan_time';
source1.pow            = results.gamma0c;%mT;
source1.mask           = results.pcGN < 0.05;
source2 = source1;
source2.pow            = mT;
source2.mask           = results.pcMN < 0.05;

%plot both hemispheres simultaneously
pos = sourcemodel.pos;
n = 4098;
pos(1:n,2) = pos(1:n,2)+210;
pos(1:n,1:2) = -pos(1:n,1:2);
source1.brainordinate.pos = pos;
source2.brainordinate.pos = pos;

cfgp                  = [];
cfgp.funparameter     = 'pow';
cfgp.maskparameter    = 'mask';
cfgp.funcolormap      = cmap;
%ft_sourcemovie(cfgp, source);

xs = source1;
xs = ft_checkdata(xs,'datatype','source');

%find where first cluster begins and plot from there to end
[~, firstcol]   = find(source1.mask,1);
[~, lastcol]    = find(source1.mask,1,'last');

splot = xs;
%figure('position',[1 1 900 900]);
for k = firstcol:4:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    figure;
    ft_plot_mesh(splot,'edgecolor','none','vertexcolor',splot.pow,'facealpha', splot.mask, 'clim', [0 0.015], 'alphalim', [0 0.005], 'alphamap', 'rampup', 'colormap', cmap, 'maskstyle', 'colormix');lighting gouraud;material dull;view([90 0]);h=light('position',[10 0 0]);
    set(gcf,'color','w');
    title(sprintf('time = %d',round(1000.*s.time(k))),'position',[33 -104 100]);
    colormap(brewermap([],'YlOrRd'))
    %fname = strcat(outdir,sprintf('/crossmod_sce%d_timestamp%03d_trc_cluster%d',scenario,k,cluster));
    %export_fig(fname,'-png');
    %clf;
end
