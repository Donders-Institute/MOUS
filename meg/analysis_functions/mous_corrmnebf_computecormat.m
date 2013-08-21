function [cor, corvox, corvert] = mous_corrmnebf_computecormat(voxM, vertM, trialinfo)
% this function computes the correlation matrix between a beamforming
% solution and an MNE solution
% to be able to visualise the results, the correlation matrix must first
% be interpolated. See mous_connectivity_browser and
% mous_corrmnebf_visualise for more information.
% NL 2013


% mean subtraction
voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]);
vertM = vertM - repmat(mean(vertM,2),[1 size(vertM,2)]);
    
% within-measure variance     
varVox      = sum(voxM.^2,2);  
varVert     = sum(vertM.^2,2); 

covVoxvert  = voxM*vertM';            % covariance matrix
cor         = covVoxvert./sqrt(varVox*varVert');% correlation matrix   

covVertvert = vertM*vertM';
corvert     = covVertvert./sqrt(varVert*varVert');  

covVoxvox   = voxM*voxM';
corvox      = covVoxvox./sqrt(varVox*varVox');

if nargin == 3
    %% perform Fisher's Z transform and standardise for number of trials 

    cor  = 0.5*(log(1+cor) - log(1-cor));       %  z' = .5[ln(1+r) - ln(1-r)] where ln = natural logarithm 
    cor  = cor./(1./sqrt(size(trialinfo,1)-3));   %  standardise for num of trials contributed by subject
end 
