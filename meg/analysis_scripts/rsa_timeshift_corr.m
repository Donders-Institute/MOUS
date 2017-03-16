% This script loops over different time windows and creates cell-arrays
% containing voxel-ranges with that as input calling rsa_corr function and
% saving correlation values with supramodal-model
nVtx = 8196;
count = 1;
windowshift = 121:120:601;
supra_corr = zeros(length(windowshift),nVtx);

for swindow = windowshift
% create cell-arrays to run rsa_corr function for 100 voxels in each call
for k = 1:100:nVtx
x{count} = k;
x2{count} = k+99;
xtim{count} = swindow;
count = count+1;
end

[V,A,S,A2,V2] = qsubcellfun('rsa_corr',x,x2,xtim,'memreq',2*(1024^3),'timreq',100);

S = cell2mat(S);
supra_corr(count,:) = S;

count = count+1
end