function [cleanMat1, cleanMat2] = mous_corrmnebf_regression(trialinfo,mat1,mat2,numbin)
%% configure design matrix FOR ONE VERTEX
    % r1 = intercept
    % r2 = trialinfo (word order)
    % ** leave out: observations for vertex y  **

% 2 matrices, remove word order from individual trials         
%              OR 
% 1 matrix, remove word order from individual trials
if nargin == 3  && size(trialinfo,2) > 1 || nargin == 2 && size(trialinfo,2) > 1
    linword     = trialinfo(:,5)';    
    quadword    = trialinfo(:,5).^2';
    DM = ones(3,size(trialinfo,1));
    
% 2 matrices, removed averaged word order for each set of binned trials
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

if nargin == 3 || nargin == 4
    beta1 = mat1/DM;     
    beta2 = mat2/DM;  

    cleanMat1 = mat1 - beta1*DM;
    cleanMat2 = mat2 - beta2*DM; 

elseif nargin == 2  
    beta1 = mat1/DM;     
    cleanMat1 = mat1 - beta1*DM;
end 


%%% Backup:

% % voxM, vertM, 
% elseif nargin == 3 && size(trialinfo,2) == 1
%     linword     = trialinfo;   
%     quadword    = trialinfo.^2';
%     DM = ones(3,size(trialinfo,1));

% if nargin == 3 || 4
%     betaVox = voxM/DM;     
%     betaVert = vertM/DM;  
% 
%     cleanVoxM = voxM - betaVox*DM;
%     cleanVertM = vertM - betaVert*DM; 
% 
% elseif nargin == 1  % written as voxM, but if first inarg is given as vertM, then this is fine since the same computation is done for voxM and vertM
%     betaVox = voxM/DM;     
%     cleanVoxM = voxM - betaVox*DM;
% end 

