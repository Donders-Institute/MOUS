function [cleanVoxM, cleanVertM] = mous_corrmnebf_regression(trialinfo,voxM,vertM,numbin)
%% configure design matrix FOR ONE VERTEX
    % r1 = intercept
    % r2 = trialinfo (word order)
    % ** leave out: observations for vertex y  **

% voxM, vertM, individual trials         OR  voxM/VertM, individual trials
if nargin == 3  && size(trialinfo,2) > 1 || nargin == 2 && size(trialinfo,2) > 1
    linword     = trialinfo(:,5)';    
    quadword    = trialinfo(:,5).^2';
    DM = ones(3,size(trialinfo,1));

% % voxM, vertM, 
% elseif nargin == 3 && size(trialinfo,2) == 1
%     linword     = trialinfo;   
%     quadword    = trialinfo.^2';
%     DM = ones(3,size(trialinfo,1));
     
% voxM, vertM, binning trials
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

if nargin == 3 || 4
    betaVox = voxM/DM;     
    betaVert = vertM/DM;  

    cleanVoxM = voxM - betaVox*DM;
    cleanVertM = vertM - betaVert*DM; 

elseif nargin == 1  % written as voxM, but if first inarg is given as vertM, then this is fine since the same computation is done for voxM and vertM
    betaVox = voxM/DM;     
    cleanVoxM = voxM - betaVox*DM;
end 



