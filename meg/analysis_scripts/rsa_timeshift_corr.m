% This script loops over different time windows and creates cell-arrays
% containing voxel-ranges with that as input calling rsa_corr function and
% saving correlation values with supramodal-model
nVtx = 8196;
timesmp = 721;
manyvox = 100;
windowsize = 120;
overlap = 80; 
supra_corr = zeros(ceil((timesmp-120)/(windowsize-overlap)),nVtx);
countouter = 1;
for swindow = 1:(windowsize-overlap):(timesmp-120)
% create cell-arrays to run rsa_corr function for 100 voxels in each call
jobid = {};
count = 1;
for k = 1:manyvox:nVtx
    if k+manyvox<=nVtx
        jobid{count} = qsubfeval('rsa_corr',k,k+manyvox-1,swindow,windowsize,'memreq',1024^3,'timreq',200);
    else
        jobid{count} = qsubfeval('rsa_corr',k,nVtx,swindow,windowsize,'memreq',1024^3,'timreq',200);
    end
count = count+1;
end

tmp = [];
for k = 1:length(jobid) 
    [V A S A2 V2] = qsubget(jobid{k}, 'timeout',500,'sleep',20,'StopOnError', true);
    tmp = [tmp S];
    k
end
supra_corr(countouter,:) = tmp;
countouter = countouter +1;
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

