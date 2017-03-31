% This script loops over different time windows and creates cell-arrays
% containing voxel-ranges with that as input calling rsa_corr function and
% saving correlation values with supramodal-model
nVtx = 8196;
timesmp = 721;
manyvox = 300;
windowsize = 120;
overlap = 80; 
count = 1;
jobid = {};
timex = 1:(windowsize-overlap):(timesmp-windowsize);
for swindow = timex
% create cell-arrays to run rsa_corr function for x voxels in each call
for k = 1:manyvox:nVtx
    if k+manyvox<=nVtx
        jobid{count} = qsubfeval('rsa_corr',k,k+manyvox-1,swindow,windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat(num2str(swindow),'_',num2str(k)));
    else
        jobid{count} = qsubfeval('rsa_corr',k,nVtx,swindow,windowsize,'memreq',1024^3,'timreq',1500,'batchid',strcat(num2str(swindow),'_',num2str(k)));
    end
count = count+1;
end
end

supra_corr = zeros(length(timex),nVtx);
within_corr = zeros(length(timex),nVtx);
count = 1;
for i = 1:length(timex)
    tmpS = [];
    tmpM = [];
    for k = 1:length(1:manyvox:nVtx)
        %[V A S A2 V2] = qsubget(jobid{count}, 'timeout',100,'sleep',20);
        load(strcat(jobid{count},'_output'))

        tmpS = [tmpS max(max(argout{5},argout{6}),argout{7})];
        tmpM = [tmpM max(max(argout{3},argout{4}),max(argout{1},argout{2}))];
        count = count+1;
    end
    supra_corr(i,:) = tmpS;
    within_corr(i,:) = tmpM;
    
end

mask = supra_corr > within_corr;

for i = 1:length(timex)
x = squeeze(within_corr(i,:));
%xmask = squeeze(mask(i,:));
%x = x.*xmask;
figure;ft_plot_mesh(atlas,'vertexcolor',x(:))
caxis([minval maxval])
end

%% stats
design = [ones(1,size(supra_corr,2)) ones(1,size(supra_corr,2))*2; 1:size(supra_corr,2) 1:size(supra_corr,2)];

timeslice = 1;
% cfg = [];
% cfg.statistic = 'statfun_mengz';
% cfg.correctm = 'no';
% cfg. alpha = 0.025;
% cfg.ivar = 1;
% cfg.uvar = 2;
% [stat, cfg] = ft_statistics_analytic(cfg,[supra_corr(timeslice,:)' within_corr(timeslice,:)'],design);

cfg = [];
cfg.statistic = 'depsamplesregrT';
cfg.numrandomization = 100;
cfg.correctm = 'max';
cfg.ivar = 1;
cfg.uvar = 2;
cfg.tail = 1;
stat = ft_statistics_montecarlo(cfg, [supra_corr(timeslice,:) within_corr(timeslice,:)], design);


