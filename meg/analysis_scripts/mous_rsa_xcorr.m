
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
maxlag = 60;
tstep = 120+maxlag; % in samples
n = 1;
interval = [n n+tstep n+tstep+60];% start interval in samples
nparcel = numel(atlas.parcellationlabel);
maxlag = 60;

%% get filenames 
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);

end

%% Load single subject sourcedata

for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_seq');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    sA{k} = tmp;
    tmp = mous_db_getdata(subjV{k},'meg_mne_conjunction_seq');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    sV{k} = tmp;
end

%% Append all subjects into one matrix
cfg=[];
cfg.appenddim='rpt';
cfg.parameter = 'pow';
outV=ft_appendsource(cfg,sV{:});
outA=ft_appendsource(cfg,sA{:});
out = outV;
out.pow=cat(1,outV.pow,outA.pow);

%% Same for pre-sentence baseline
clear sA sV outA outV

for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_bsl');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    sA{k} = tmp;
    tmp = mous_db_getdata(subjV{k},'meg_mne_conjunction_bsl');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    sV{k} = tmp;
end

%% Append all subjects into one matrix
cfg=[];
cfg.appenddim='rpt';
cfg.parameter = 'pow';
outV=ft_appendsource(cfg,sV{:});
outA=ft_appendsource(cfg,sA{:});
clear sA sV
outbsl = outV;
outbsl.pow=cat(1,outV.pow,outA.pow);
clear outA outV
clear tmp


%% Compute correlation across subjects

% for each vertex position find optimal delay using xcorr for all subject-combinations, 
% for bsl condition

pb = zeros(Nsubj*2,Nsubj*2,nVtx);
sel = zeros(Nsubj*2,size(out.pow,3));
for k = 1:nVtx
    sel = squeeze(outbsl.pow(:,k,:));

    cfg = [];
    cfg.lag = -maxlag:maxlag;
    [r,lag] = statfun_xcorr2(cfg,sel,sel); 
    
    
     pb(:,:,k) = max(abs(r),[],3);
end

pbx = zeros(2,2,nVtx);
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
    for k = 1:size(pb,3)
        pbx(:,:,k)=P*pb(:,:,k)*P';
    end

pbx=pbx./(Nsubj^2);
val = max(pbx(:));

% Compute lag for each subject-combination and vertex
tmp = zeros((Nsubj*2)*(Nsubj*2),1);
lag = zeros(Nsubj*2,Nsubj*2,nVtx);   
sel = zeros(Nsubj*2,size(out.pow,3));
for k = 1:nVtx
    tic
    sel = squeeze(out.pow(:,k,:));
 if all(all(isnan(sel)))
     lag(:,:,k) = nan(Nsubj*2);
 else
    cfg = [];
    cfg.lag = -maxlag:maxlag;
    [r,l] = statfun_xcorr2(cfg,sel,sel); 

    % bring cross-correlation functions into form that can be read in by
    % peakdetect
    r = reshape(r,size(r,1)*size(r,2),size(r,3));

    % find throughs and peaks of xcorr lag-function
    [pindx pval] = peakdetect2(r);

    % adjust lag information to be centered around zero.
    pindx = pindx - ((size(r,2)+1)/2);

    % find lags corresponding to peaks closest to 0;
    [~,index] = nanmin(abs(pindx),[],2);
    linearInd = sub2ind(size(pindx), [1:41616]', index);
    tmp = pindx(linearInd);
    % if no peak is within maxlag range take 0;
    tmp(isnan(tmp)) = 0;

    %backwards reshape
    lag(:,:,k) = reshape(tmp,Nsubj*2,Nsubj*2);
 end
 toc
end

% average lag per condition:
lagx = zeros(4,2,nVtx);
for k = 1:nVtx
tmp=abs(lag(:,:,k));
tmp=reshape(permute(reshape(tmp,[102 2 102 2]),[1 3 2 4]),102^2,4);
lagx(:,1,k) = mean(tmp);
lagx(:,2,k) = std(tmp);
end

%% load in correlation coefficients per interval ( as computed using mous_rsa_xcorr_parallel.m)matyl

allFiles = dir( '/project/3011020.09/sopara/lags/*_lags.mat' );
allNames = { allFiles.name };
C = regexp(allNames, '_', 'split');
for i = 1:length(C)
end
intv = intv(:,1:2,:)

pl = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
tic
for i = 1:length(intv)
     load([allNames{i}])
for  k = intv(:,1,i):intv(:,2,i)
     for l = 1:length(interval)
         pl(:,:,k,l) = squareform(squeeze(ptmp(:,k,l)));
     end
end

end
toc

% average
px = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:length(interval)
    for k = 1:size(pl,3)
        px(:,:,k,i)=P*pl(:,:,k,i)*P';
    end
end
px=px./(Nsubj^2);
val = max(px(:));

%% Create model matrix
% visual-specific model
mv=ones(204);
mv(1:102,103:end)=0;
mv(103:end,:)=0;
mv = mv-diag(diag(mv));
mv=squareform(mv,'tovector');
% auditory-specific model
ma=zeros(204);
ma(103:end,103:end)=1;
ma = ma-diag(diag(ma));
ma=squareform(ma,'tovector');
% supramodal model
ms=ones(204);
ms(103:end,1:102)=0;
ms(1:102,103:end)=0;
ms = ms-diag(diag(ms));
ms=squareform(ms,'tovector');
% 
% 
% % Correlate dissimilarity matrix with models
% 
for k = 1:nVtx
    for i = 1:size(newp,4)
        tmp = squeeze(newp(:,:,k,i));
        tmp(logical(eye(size(tmp)))) = 0;
        cV(k,i) = corr(squareform(tmp,'tovector')',mv','type','spearman');
        cA(k,i) = corr(squareform(tmp,'tovector')',ma','type','spearman');
        cS(k,i) = corr(squareform(tmp,'tovector')',ms','type','spearman');
    end
end
clear tmp