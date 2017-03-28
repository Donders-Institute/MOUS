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
        jobid{count} = qsubfeval('rsa_corr',k,k+manyvox-1,swindow,windowsize,'memreq',1024^3,'timreq',1000,'batchid',strcat(num2str(swindow),'_',num2str(k)));
    else
        jobid{count} = qsubfeval('rsa_corr',k,nVtx,swindow,windowsize,'memreq',1024^3,'timreq',1000,'batchid',strcat(num2str(swindow),'_',num2str(k)));
    end
count = count+1;
end
end

supra_corr = zeros(length(timex),nVtx);
aud_corr = zeros(length(timex),nVtx);
vis_corr = zeros(length(timex),nVtx);
count = 1;
for i = 1:length(timex)
    tmpS = [];
    tmpA = [];
    tmpV = [];
    for k = 1:length(1:manyvox:nVtx)
        %[V A S A2 V2] = qsubget(jobid{count}, 'timeout',100,'sleep',20);
        load(strcat(jobid{count},'_output'))

        tmpS = [tmpS max(max(argout{5},argout{6}),argout{7})];
        tmpA = [tmpA max(argout{3},argout{4})];
        tmpV = [tmpV max(argout{1},argout{2})];
        count = count+1;
    end
    supra_corr(i,:) = tmpS;
    aud_corr(i,:) = tmpA;
    vis_corr(i,:) = tmpV;
end

mask = (supra_corr > aud_corr) & (supra_corr > vis_corr);

for i = 1:length(timex)
x = squeeze(supra_corr(i,:));
 %xmask = squeeze(mask(i,:));
 %x = x.*xmask;
figure;ft_plot_mesh(atlas,'vertexcolor',x(:))
caxis([minval maxval])
end
% 
% for k = 1:steps:nVtx
% x2{count} = k+99;
% x{count} = k;
% xtim{count} = swindow;
% count = count+1;
% end
% 
% x2{end} = [nVtx];
% [V,A,S,A2,V2] = qsubcellfun('rsa_corr',x,x2,xtim,'memreq',1024^3,'timreq',100);

