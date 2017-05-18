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

p = rsa_m(voxelstart,voxelend,latewindow,windowsize);
[n,m,l,j] = size(p);

%design matrices
n = size(mv,2);
design1 = [mv;mv2;ma;ma2];
design2 = [mv;mv2;ma;ma2;ms];

betas = nan(j,size([design1; design2],1)+2);
stat.p = nan(j,1);
stat.f = nan(j,1);
stat.mask = nan(j,1);
for v = 1:j
    
    tmpp = squeeze(p(:,:,:,v));
    
    if ~all(isnan(tmpp(:)))
        
        fill = NaN( 10404,1);
        quads=reshape(permute(reshape(tmpp(:,:,:),[Nsubj 2 Nsubj 2 3]),[1 3 2 4 5]),Nsubj^2,4,3);
        M = cat(2,squeeze(quads(:,1,2)),fill,squeeze(quads(:,2,2)),fill,fill,squeeze(quads(:,1,3)),fill,squeeze(quads(:,2,3)),squeeze(quads(:,2,2)),fill,squeeze(quads(:,4,2)),fill,fill,squeeze(quads(:,2,3)),fill,squeeze(quads(:,4,3)));
        M = col2im(M,[Nsubj Nsubj],[Nsubj*4 Nsubj*4],'distinct');
        M(logical(eye(size(M)))) = 0;
        Mx = squareform(M, 'tovector');
        sel = isfinite(Mx);
        
        %regression
        n = size(mv,2);
        design1 = [mv;mv2;ma;ma2];
        design2 = [mv;mv2;ma;ma2;ms];
        
%         design1(:,sel) = design1(:,sel)-repmat(mean(design1(:,sel),2),[1 sum(sel)]);
%         design2(:,sel) = design2(:,sel)-repmat(mean(design2(:,sel),2),[1 sum(sel)]);
        
        %
        %         cfg = [];
        %         cfg.glm.statistic = 'beta';
        %         cfg.glm.demean = true;
        %         cfg.glm.standardise = 1; %this only demeans design matrix at the moment
        
        %betas(v,:) = statfun_glm_sa(cfg,Mx(sel),design(:,sel));
        s1 = regstats(Mx(sel)',design1(:,sel)','linear',{'beta','fstat','r','rsquare'});
        s2 = regstats(Mx(sel)',design2(:,sel)','linear',{'beta','fstat','r','rsquare'});
        
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
