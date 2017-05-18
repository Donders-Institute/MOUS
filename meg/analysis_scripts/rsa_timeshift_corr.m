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
            jobid{count} = qsubfeval('rsa_corr',k,k+manyvox-1,timex(i),windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat('corr',num2str(timex(i)),'_',num2str(k)));
        else
            jobid{count} = qsubfeval('rsa_corr',k,nVtx,timex(i),windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat('corr',num2str(timex(i)),'_',num2str(k)));
        end
        count = count+1;
    end
end

%% stats
% while jobs are running compute p values on regression
betas_all = zeros(length(timex),nVtx,11);
stat_all = zeros(length(timex),nVtx,2);
stat_mask = zeros(length(timex),nVtx);
for i = 1:length(timex)
    [betas,stat] = rsa_regressmodels(1,nVtx,timex(i),windowsize);
    betas_all(i,:,:) = betas;
    stat_all(i,:,:) = [stat.p stat.f];
    i
end

% bonferroni correction
for i = 1:length(timex)
   stat_mask(i,:) = stat_all(i,:,1)<=(0.05 ./ sum(~isnan(stat_all(i,:,1))));
end


%% load data and visualize
supra_corr = zeros(length(timex),nVtx);
within_corr = zeros(length(timex),nVtx);
count = 1;
for i = 1:length(timex)
    tmpS = [];
    tmpM = [];
    for k = 1:length(voxelsteps)
        %[V A S A2 V2] = qsubget(jobid{count}, 'timeout',100,'sleep',20);
        load(strcat(jobid{count},'_output'))
        
        tmpS = [tmpS max(max(argout{5},argout{6}),argout{7})];
        tmpM = [tmpM max(max(argout{3},argout{4}),max(argout{1},argout{2}))];
        count = count + 1;
    end
    supra_corr(i,:) = tmpS;
    within_corr(i,:) = tmpM;
    
end


for i = 1:length(timex)
    x = squeeze(betas_all(i,:,11));
    x = x.*stat_mask(i,:);
    figure;
    ft_plot_mesh(atlas,'vertexcolor',x(:))
    caxis([minval maxval])
   % pause
end

