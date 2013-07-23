function [cor, corvox, corvert] = mous_corrmnebf_regression(subjectname, voxM, vertM, trialinfo)
%% configure design matrix FOR ONE VERTEX
    % r1 = intercept
    % r2 = trialinfo (word order)
    % ** leave out: observations for vertex y  **

%     % don't standardise regressors    
%     DM = zeros(3,size(trialinfo),1); 
%     DM(1,:) = ones;   
%     DM(2,:) = trialinfo(:,5)';      % linear
%     DM(3,:) = trialinfo(:,5).^2';   % quadratic 
    
    % standardise regressors
    linword     = trialinfo(:,5)';
    linmean     = mean(linword);
    linsd       = std(linword);
    linword     = (linword-linmean)./linsd;

    quadword    = trialinfo(:,5).^2';
    quadmean    = mean(quadword);
    quadsd      = std(quadword);
    quadword    = (quadword-linmean)./quadsd;
    
    DM = zeros(3,size(trialinfo,1)); 
    DM(1,:) = ones;   
    DM(2,:) = linword;      % linear
    DM(3,:) = quadword;   % quadratic 

% There should be no NaNs but just to be safe
if find(isnan(DM) == 1)
    warning('%s has NaNs in DM', subjectname)
end 


%% Get Beta Weights
% Matrices
% X = DM (regressor*words)
% Y = voxM (voxels*words)
% Z = vertM (vertices*words)

% betaY = Y*X'*inv(X*X')
% betaZ = Z*X'*inv(X*X')
% Yclean = Y - betaY * X
% Zclean = Z - betaZ * X

%betaVox = voxM*DM'*inv(DM*DM');
%betaVert = vertM*DM'*inv(DM*DM');
betaVox = voxM/DM;    %'*inv(DM*DM');
betaVert = vertM/DM;  %'*inv(DM*DM');

cleanVoxM = voxM - betaVox*DM;
cleanVertM = vertM - betaVert*DM; 

%% then compute correlation matrix between Yclean and Zclean.

% mean subtraction
cleanVoxM  = cleanVoxM - repmat(mean(cleanVoxM,2),[1 size(cleanVoxM,2)]);
cleanVertM = cleanVertM - repmat(mean(cleanVertM,2),[1 size(cleanVertM,2)]);
    
% within-measure variance     
varVox      = sum(cleanVoxM.^2,2);  
varVert     = sum(cleanVertM.^2,2); 

covVoxvert  = cleanVoxM*cleanVertM';            % covariance matrix
cor         = covVoxvert./sqrt(varVox*varVert');% correlation matrix   

covVertvert = cleanVertM*cleanVertM';
corvert = covVertvert./sqrt(varVert*varVert');  

covVoxvox   = cleanVoxM*cleanVoxM';
corvox      = covVoxvox./sqrt(varVox*varVox');

% calculate variance
% correlation matrix

