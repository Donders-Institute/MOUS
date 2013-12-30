function [cormat1, cormat2, cormat12] = mous_corrmnebf_computecormat(trialinfo, mat1, mat2)
% this function computes the correlation matrix between a beamforming
% solution and an MNE solution
% Correlation = covariance of A and B, divided by the sqrt of the standard deviation of A and B
% Covariance =  (Ai-Amean) * (Bi-Bmean)
% NL 2013  Updated: 30.12.2013


%% calculations for first matrix 
% correlation matrix
mat1         = mat1 - repmat(mean(mat1,2),[1 size(mat1,2)]);
varmat1      = sum(mat1.^2,2);                  % covariance between each matrix and itself = variance
covmat1      = mat1*mat1';
cormat1      = covmat1./sqrt(varmat1*varmat1'); % covariance/sqrt(variance); where sqrt(variance) = Std

% fisher's transform (standardise for numtrials)
cormat1  = 0.5*(log(1+cormat1) - log(1-cormat1));       %  z' = .5[ln(1+r) - ln(1-r)] where ln = natural logarithm 
cormat1  = cormat1./(1./sqrt(size(trialinfo,1)-3));   %  standardise for num of trials contributed by subject


%% calculations for second matrix (if it exists)
if nargin == 3
    % correlation matrices
    mat2       = mat2 - repmat(mean(mat2,2),[1 size(mat2,2)]);
    varmat2    = sum(mat2.^2,2);
    
    covmat2    = mat2*mat2';
    cormat2    = covmat2./sqrt(varmat2*varmat2'); % corrmnemne

    covmat12   = mat1*mat2';                        
    cormat12   = covmat12./sqrt(varmat1*varmat2');   % corrmnebf: covariance matrix
    
    % fisher's transform (standardise for numtrials)    
    cormat2  = 0.5*(log(1+cormat2) - log(1-cormat2));       %  z' = .5[ln(1+r) - ln(1-r)] where ln = natural logarithm 
    cormat2  = cormat2./(1./sqrt(size(trialinfo,1)-3));   %  standardise for num of trials contributed by subject

    
    cormat12  = 0.5*(log(1+cormat12) - log(1-cormat12));       %  z' = .5[ln(1+r) - ln(1-r)] where ln = natural logarithm 
    cormat12  = cormat12./(1./sqrt(size(trialinfo,1)-3));   %  standardise for num of trials contributed by subject
end 

% if size(mat1,2) > 1   % voxels * trials
    % mean subtraction: subtract mean value across trials, for each voxel
% elseif size(mat1,2) == 1  % voxels * 1 trial
%     stdvox      = (mat1-mean(mat1))./std(mat1);  % mean subtract and standardise
%     stdvert     = (mat2-nanmean(mat2))./nanstd(mat2);  % mean subtract and standardise
%     cor         = (stdvox * stdvert')/sum(stdvox.^2);
% 
%     % mean subtract: subtract mean value across voxels  - IS THIS NECESSARY?
%     mat1    = mat1 - mean(mat1);
%     mat2   = mat2 - nanmean(mat2);
%     
%     varmat1  = sum(mat1.^2);
%     varmat2 = nansum(mat2.^2);
%     
%     covmat12  = mat1*mat2';                      % covariance matrix
%     cor         = covmat12./sqrt(varmat1*varmat2');% covariance/sqrt(variance); where sqrt(variance) = Std   
% end
