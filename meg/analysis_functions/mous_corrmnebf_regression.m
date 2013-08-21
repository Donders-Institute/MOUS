function [cleanVoxM, cleanVertM] = mous_corrmnebf_regression(voxM, vertM,trialinfo,numbin)
%% configure design matrix FOR ONE VERTEX
    % r1 = intercept
    % r2 = trialinfo (word order)
    % ** leave out: observations for vertex y  **
  
if nargin == 3 % regress out individual (standardised) word order for each trial(word)

    linword     = trialinfo(:,5)';    
    quadword    = trialinfo(:,5).^2';
    DM = ones(3,size(trialinfo,1)); 

elseif nargin == 4 % regress out average word order for each bin  
    linword     = nanmean(trialinfo);   % average word order of each bin
    quadword    = nanmean(trialinfo.^2);
    DM = ones(3,numbin);
end

    linmean     = nanmean(linword);
    linsd       = nanstd(linword);
    linword     = (linword-linmean)./linsd;

    quadmean    = nanmean(quadword);
    quadsd      = nanstd(quadword);
    quadword    = (quadword-quadmean)./quadsd;  
    
    DM(2,:) = linword;      % linear
    DM(3,:) = quadword;   % quadratic 


%% Get Beta Weights
% Matrices
% X = DM (regressor*words)
% Y = voxM (voxels*words)
% Z = vertM (vertices*words)

% betaY = Y*X'*inv(X*X')
% betaZ = Z*X'*inv(X*X')
% Yclean = Y - betaY * X
% Zclean = Z - betaZ * X
% y = b*x, therefore, b = y/x

betaVox = voxM/DM;     
betaVert = vertM/DM;  

cleanVoxM = voxM - betaVox*DM;
cleanVertM = vertM - betaVert*DM; 


