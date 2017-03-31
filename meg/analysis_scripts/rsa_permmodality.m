%% This script will call rsa_m to create the data rsa-matrix for each voxel (group of voxels)
%% it will then for each voxel determine statistical significance using a nonparametrical permutation approach


% set variables
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
    
end

nVtx = 8196;
timesmp = 721;
manyvox = 300;
windowsize = 120;
overlap = 80;
count = 1;
timex = 1:(windowsize-overlap):(timesmp-windowsize);
nperm = 10;
%% Create model matrix
% visual-specific model
mv=zeros(408);
mv(1:102,1:102)=1;
mv = mv-diag(diag(mv));
mv=squareform(mv,'tovector');
% auditory-specific model
ma=zeros(408);
ma(205:306,205:306)=1;
ma = ma-diag(diag(ma));
ma=squareform(ma,'tovector');
%
ma2=zeros(408);
ma2(205:306,205:306)=1;
ma2(307:end,307:end)=1;
ma2 = ma2-diag(diag(ma2));
ma2=squareform(ma2,'tovector');

mv2=zeros(408);
mv2(1:102,1:102)=1;
mv2(103:204,103:204)=1;
mv2 = mv2-diag(diag(mv2));
mv2=squareform(mv2,'tovector');
% supramodal model
ms=zeros(408);
ms(103:204,103:204)=1;
ms(307:408,103:204)=1;
ms(103:204,307:408)=1;
ms(307:408,307:408)=1;
ms = ms-diag(diag(ms));
ms=squareform(ms,'tovector');
% supramodal + early visual/auditory/both and within modality earlyXlate
% supramodal model + early visual
ms2=zeros(408);
ms2(1:102,1:102)=1;
ms2(103:204,103:204)=1;
ms2(307:408,103:204)=1;
ms2(103:204,307:408)=1;
ms2(307:408,307:408)=1;
ms2 = ms2-diag(diag(ms2));
ms2=squareform(ms2,'tovector');
% supramodal model + early auditory
ms3=zeros(408);
ms3(205:306,205:306)=1;
ms3(103:204,103:204)=1;
ms3(307:408,103:204)=1;
ms3(103:204,307:408)=1;
ms3(307:408,307:408)=1;
ms3 = ms3-diag(diag(ms3));
ms3=squareform(ms3,'tovector');

% create data model

p = rsa_m(3188,481,120);
[n,m,l] = size(p);
% shuffle design matrix nperm times, so that for each column/row in M, you get an
% integer that marks with which row/column to swap
design = [ones(1,m) ones(1,m)*2; 1:m 1:m];

resample = zeros(nperm,max(design(2,:)));
for i=1:nperm
    resample(i,:) = randperm(max(design(2,:)));
end


newp = zeros(n,m,l);
statout = zeros(nperm,1);
for i = 1:nperm
    for interval = 1:l
        tmpp = squeeze(p(:,:,interval));
        %swap all rows
        for k = 1:size(resample,2)
            tmpp([k resample(i,k)],:) = tmpp([resample(i,k) k],:);
        end
        %swap all columns
        for k = 1:size(resample,2)
            tmpp(:,[k resample(i,k)]) = tmpp(:,[resample(i,k) k]);
        end
        %compute statistic
        newp(:,:,interval) = tmpp;
    end
    %compute statistic
    % missing: compute complete rsa matrix using code in rsa_corr
    % compute correlation with models
    % combine models with max
    % compute difference between coef for supra and for within
    % save difference to permutation distribution
end

% compute actual difference and compare against permutation distribution





