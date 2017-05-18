function  [corrS, corrM, stat] = rsa_permmodality(voxelstart,voxelend,latewindow,windowsize)
% This function will call rsa_m to create the data rsa-matrix for each voxel (group of voxels)
% it will then for each voxel determine statistical significance using a
% nonparametrical permutation approach, where modality labels are permuted across subjects.


% set variables
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
    
end

Nperm = 100;
alpha = 0.025;
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

for v = 1:j
    
    tmpp = squeeze(p(:,:,:,v));
    
    % compute actual difference and compare against permutation distribution
    
    fill = NaN( 10404,1);
    quads=reshape(permute(reshape(tmpp(:,:,:),[Nsubj 2 Nsubj 2 3]),[1 3 2 4 5]),Nsubj^2,4,3);
    M = cat(2,squeeze(quads(:,1,2)),fill,squeeze(quads(:,2,2)),fill,fill,squeeze(quads(:,1,3)),fill,squeeze(quads(:,2,3)),squeeze(quads(:,2,2)),fill,squeeze(quads(:,4,2)),fill,fill,squeeze(quads(:,2,3)),fill,squeeze(quads(:,4,3)));
    M = col2im(M,[Nsubj Nsubj],[Nsubj*4 Nsubj*4],'distinct');
    M(logical(eye(size(M)))) = 0;
%     mv_corr = corr(squareform(M,'tovector')',mv','type','spearman','rows','complete');
%     ma_corr = corr(squareform(M,'tovector')',ma','type','spearman','rows','complete');
%     ms_corr = corr(squareform(M,'tovector')',ms','type','spearman','rows','complete');
%     ma2_corr = corr(squareform(M,'tovector')',ma2','type','spearman','rows','complete');
%     mv2_corr = corr(squareform(M,'tovector')',mv2','type','spearman','rows','complete');
%     ms2_corr = corr(squareform(M,'tovector')',ms2','type','spearman','rows','complete');
%     ms3_corr = corr(squareform(M,'tovector')',ms3','type','spearman','rows','complete');

                cfg = [];
                cfg.ivar = 1;
                Mx = squareform(M, 'tovector');
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-mv); mv_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ma); ma_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms); ms_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ma2); ma2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-mv2); mv2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms2); ms2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms3); ms3_corr = tmp.stat;
                
    corrS(v) = max(max(ms_corr,ms2_corr),ms3_corr);
    corrM(v) = max(max(ma_corr,ma2_corr),max(mv_corr,mv2_corr));
    
end

statobs = corrS - corrM;

if nargout > 2
    

    
    resample = zeros(Nperm,Nsubj*2);
    for i=1:Nperm
        resample(i,:) = randperm(Nsubj*2);
    end
    
    
    prb_pos  = zeros(size(statobs));
    prb_neg   = zeros(size(statobs));
    newp = zeros(n,m,l);
    statrand = zeros(size(statobs,2),Nperm);
    
    for v = 1:j
        tmpp = squeeze(p(:,:,:,v));
        if any(tmpp(:))
            for i = 1:Nperm
                newp(:,:,:) = tmpp(resample(i,:),resample(i,:),:);
                
                %compute statistic
                % missing: compute complete rsa matrix using code in rsa_corr
                
                quads=reshape(permute(reshape(newp(:,:,:),[Nsubj 2 Nsubj 2 3]),[1 3 2 4 5]),Nsubj^2,4,3);
                %concat all columnvectors containing quadrants in order matching the
                %models:        V_early V_late A_early A_late
                %       V_early  ______|______|______|_______
                %       V_late   ______|______|______|_______
                %       A_early  ______|______|______|_______
                %       A_late   ______|______|______|_______
                M = cat(2,squeeze(quads(:,1,2)),fill,squeeze(quads(:,2,2)),fill,fill,squeeze(quads(:,1,3)),fill,squeeze(quads(:,2,3)),squeeze(quads(:,2,2)),fill,squeeze(quads(:,4,2)),fill,fill,squeeze(quads(:,2,3)),fill,squeeze(quads(:,4,3)));
                M = col2im(M,[Nsubj Nsubj],[Nsubj*4 Nsubj*4],'distinct');
                
                % % Correlate dissimilarity matrix with models
                
                M(logical(eye(size(M)))) = 0;
%                 mv_corr = corr(squareform(M,'tovector')',mv','type','spearman','rows','complete');
%                 ma_corr = corr(squareform(M,'tovector')',ma','type','spearman','rows','complete');
%                 ms_corr = corr(squareform(M,'tovector')',ms','type','spearman','rows','complete');
%                 ma2_corr = corr(squareform(M,'tovector')',ma2','type','spearman','rows','complete');
%                 mv2_corr = corr(squareform(M,'tovector')',mv2','type','spearman','rows','complete');
%                 ms2_corr = corr(squareform(M,'tovector')',ms2','type','spearman','rows','complete');
%                 ms3_corr = corr(squareform(M,'tovector')',ms3','type','spearman','rows','complete');
%                 
                cfg = [];
                cfg.ivar = 1;
                Mx = squareform(M, 'tovector');
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-mv); mv_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ma); ma_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms); ms_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ma2); ma2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-mv2); mv2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms2); ms2_corr = tmp.stat;
                tmp = ft_statfun_indepsamplesT(cfg,Mx,2-ms3); ms3_corr = tmp.stat;
                
                
                
                % combine models with max
                % compute difference between coef for supra and for within
                tmpS = max(max(ms_corr,ms2_corr),ms3_corr);
                tmpM = max(max(ma_corr,ma2_corr),max(mv_corr,mv2_corr));
                % save difference to permutation distribution
                statrand(v,i) = tmpS - tmpM;
                prb_pos(v) = prb_pos(v) + (statobs(v)<statrand(v,i));
                prb_neg(v) = prb_neg(v) + (statobs(v)>statrand(v,i));
            end
        else
            prb_pos(v) = nan;
            prb_neg(v) = nan;
        end
    end
    prb_pos = prb_pos + 1;
    prb_neg = prb_neg + 1;
    Nperm = Nperm + 1;
    prb_neg = prb_neg./Nperm;
    prb_pos = prb_pos./Nperm;
    stat.prob = prb_pos; %ignore negative stats, as in these cases within-modality coeffs are higher
    
    stddev = sqrt(stat.prob.*(1-stat.prob)/Nperm);
    stat.cirange= 1.96*stddev;
    stat.mask = stat.prob<=alpha;
    
    % return the observed statistic
    stat.stat = statobs;
    stat.ref = statrand;
end
end
