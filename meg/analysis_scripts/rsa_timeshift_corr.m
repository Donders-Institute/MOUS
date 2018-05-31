% This script loops over different time windows and creates cell-arrays
% containing voxel-ranges with that as input calling rsa_corr function and
% saving correlation values with supramodal-model
nVtx = 8196;
timesmp = 721;
manyvox = 300;
windowsize = 120;
overlap = 80;
jobid = {};
timex = 1:(windowsize-overlap):(timesmp-windowsize);
voxelsteps =  1:manyvox:nVtx;
count = 1;
for i = 1:length(timex)
    % create cell-arrays to run rsa_corr function for x voxels in each call
    for k = voxelsteps
        if k+manyvox<=nVtx
            jobid{count} = qsubfeval('rsa_corr',k,k+manyvox-1,timex(i),windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat('corr',num2str(timex(i)),'_',num2str(k)),'matlabcmd','matlab2016b');
        else
            jobid{count} = qsubfeval('rsa_corr',k,nVtx,timex(i),windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat('corr',num2str(timex(i)),'_',num2str(k)),'matlabcmd','matlab2016b');
        end
        count = count+1;
    end
end

%% stats
% while jobs are running compute p values on regression
% betas_all = zeros(length(timex),nVtx,11);
% stat_all = zeros(length(timex),nVtx,2);
% stat_mask = zeros(length(timex),nVtx);
% for i = 1:length(timex)
%     [betas,stat] = rsa_regressmodels(1,nVtx,timex(i),windowsize);
%     betas_all(i,:,:) = betas;
%     stat_all(i,:,:) = [stat.p stat.f];
%     i
% end
load('/project/3011020.09/sopara/regression_stats/wordlist_stats')

% bonferroni correction
for i = 1:length(timex)
   stat_mask(i,:) = stat_all(i,:,1)<=(0.05 ./ sum(~isnan(stat_all(i,:,1))));
end


%% load data and visualize
supra_corr = zeros(length(timex),nVtx);
within_corr = zeros(length(timex),nVtx);
% moda = zeros(length(timex),nVtx);
% modv = zeros(length(timex),nVtx);
count = 1;
for i = 1:length(timex)
    tmpS = [];
    tmpM = [];
%     tmpA = [];
%     tmpV = [];
    for k = 1:length(voxelsteps)
        %[V A S A2 V2] = qsubget(jobid{count}, 'timeout',100,'sleep',20);
        load(strcat(jobid{count},'_output')) %[mv_corr,mv2_corr,ma_corr,ma2_corr,ms_corr,ms2_corr,ms3_corr] 
        
        tmpS = [tmpS max(max(argout{5},argout{6}),argout{7})];
        tmpM = [tmpM max(max(argout{3},argout{4}),max(argout{1},argout{2}))];
%         tmpA = [tmpA max(argout{3},argout{4})];
%         tmpV = [tmpV max(argout{1},argout{2})];
        count = count + 1;
    end
     supra_corr(i,:) = tmpS;
     within_corr(i,:) = tmpM;
%        moda (i,:) = tmpA;
%        modv (i,:) = tmpV;
    
end


load atlas_conte69_8196reg_LR_brodmann_subparc
minval = min(min(betas_all(:,:,11)));
maxval = max(max(betas_all(:,:,11)));
for i = 1:length(timex)
    plotdata.pos = atlas.pos;
    plotdata.inside = atlas.inside;
    plotdata.tri = atlas.tri;
    plotdata.avg = squeeze(betas_all(i,:,11))';
    plotdata.mask = stat_mask(i,:)';
    plotdata.avg(~atlas.inside) = nan;
    %x = squeeze(betas_all(i,:,11));
    %figure;
    %ft_plot_mesh(sourcemodel,'vertexcolor',x(:))
    
    cfg = [];
    cfg.method = 'surface';
    cfg.funparameter = 'avg';
    cfg.funcolorlim = [-maxval maxval];
    cfg.funcolormap = 'jet';
    cfg.maskparameter = 'mask';
    cfg.maskstyle     = 'opacity';
    ft_sourceplot(cfg,plotdata)
    
    %subtitle(strcat(timex(i)))
    %alpha 0.5
    %camlight LEFT
end

figHandles = get(groot, 'Children');
for f = 1:numel(figHandles)
      fig = figHandles(f);
      filename = sprintf('/project/3011020.09/sopara/figures/%02d_ms',round(((timex(17-f)-120)/120)*100));
      savefig(fig, filename);
end
