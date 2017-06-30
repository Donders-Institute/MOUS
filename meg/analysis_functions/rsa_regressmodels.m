function [betas,stat] = rsa_regressmodels(voxelstart,voxelend,latewindow,windowsize)
% This function will call rsa_m to create the data rsa-matrix for each voxel (group of voxels)
% it will then use the RSMs as regressors to evaluate which model best
% predicts the data.

% set variables
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
    
end

%% Create model matrix
fill = NaN(102,1);
% visual-specific model
mv = [ones(102,1);fill;zeros(102,1);fill;zeros(102,1);fill;zeros(102,1);zeros(102,1);fill;zeros(102,1)];
% auditory-specific model
ma = [zeros(102,1);fill;zeros(102,1);fill;zeros(102,1);fill;zeros(102,1);ones(102,1);fill;zeros(102,1)];
%
ma2 = [zeros(102,1);fill;zeros(102,1);fill;zeros(102,1);fill;zeros(102,1);ones(102,1);fill;ones(102,1)];
%
mv2 = [ones(102,1);fill;zeros(102,1);fill;ones(102,1);fill;zeros(102,1);zeros(102,1);fill;zeros(102,1)];

% supramodal model
ms = [zeros(102,1);fill;zeros(102,1);fill;ones(102,1);fill;ones(102,1);zeros(102,1);fill;ones(102,1)];

% create data model

p = rsa_m(voxelstart,voxelend,latewindow,windowsize);
[n,m,l,j] = size(p);

%design matrices
n = size(mv,2);
design1 = [mv mv2 ma ma2];
design2 = [mv mv2 ma ma2 ms];

%betas = nan(j,size([design1; design2],1)+2);
stat.p = nan(j,1);
stat.f = nan(j,1);
stat.mask = nan(j,1);
for v = 1:j
    
    tmpp = squeeze(p(:,:,:,v));
    
    if ~all(isnan(tmpp(:)))
        
   
        %quads=reshape(permute(reshape(tmpp(:,:,:),[Nsubj 2 Nsubj 2 3]),[1 3 2 4 5]),Nsubj^2,4,3);
        %reduce dimensions by averaging over subjects within condition
        quads = permute(reshape(tmpp(:,:,:),[Nsubj 2 Nsubj 2 3]),[1 3 2 4 5]);
        quads = squeeze(mean(quads,2));
        quads = reshape(quads,[Nsubj 4 3]);
 
        %
        M = cat(2,squeeze(quads(:,1,2)),fill,squeeze(quads(:,2,2)),fill,squeeze(quads(:,1,3)),fill,squeeze(quads(:,2,3)),squeeze(quads(:,4,2)),fill,squeeze(quads(:,4,3)));
        M = M(:);
        sel = isfinite(M);
        
%         design1(:,sel) = design1(:,sel)-repmat(mean(design1(:,sel),2),[1 sum(sel)]);
%         design2(:,sel) = design2(:,sel)-repmat(mean(design2(:,sel),2),[1 sum(sel)]);
        
        %
        %         cfg = [];
        %         cfg.glm.statistic = 'beta';
        %         cfg.glm.demean = true;
        %         cfg.glm.standardise = 1; %this only demeans design matrix at the moment
        
        %betas(v,:) = statfun_glm_sa(cfg,Mx(sel),design(:,sel));
        s1 = regstats(M(sel)',design1(sel,:),'linear',{'beta','fstat'});
        s2 = regstats(M(sel)',design2(sel,:),'linear',{'beta','fstat'});
        
        f = ((s1.fstat.sse - s2.fstat.sse)/(s1.fstat.dfe - s2.fstat.dfe))/(s2.fstat.sse/s2.fstat.dfe);
        pval=1-fcdf(f,s1.fstat.dfe - s2.fstat.dfe,s2.fstat.dfe);
        stat.f(v) = f;
        stat.p(v) = pval;
        stat.mask(v) = pval<0.05 ;
        betas(v,:) = [s1.beta;s2.beta];
        
        %         H = [1 0 1 0 0 0];
        %         c = 0;
        %
        %         [p,F] = linhyptest(s.beta,s.covb,c,H,s.fstat.dfe);
        
        %     cfg.glm.statistic = 'compareF';
        %     cfg.glm.ivar0 = 1:6;
        %     cfg.glm.ivar1 = 1:5;
        %     cfg.computeprob = 'yes';
        %     stat(v,:) = statfun_glm_sa(cfg,Mx(sel),design(:,sel));
    end
end



end
