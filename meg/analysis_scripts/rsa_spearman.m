
% Variables
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
maxlag = 60;
tstep = 120; % in samples
n = 1;
interval = [n n+tstep n+tstep+360];% start interval in samples
nparcel = length(atlas.parcellationlabel);

%% get filenames 
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);

end

%% load in lag-corrected corr coefficients for baseline

%% subtract absolute bsl values form absolute post-onset values

newp = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
for l = 1:length(interval)
    for k = 1:size(p,3)
        newp(:,:,k,l)=abs(p(:,:,k,l))-abs(pb(:,:,k));
    end
end

%average vor visualization
%bsl
pbx = zeros(2,2,nVtx);
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
    for k = 1:size(pb,3)
        pbx(:,:,k)=P*abs(pb(:,:,k))*P';
    end

pbx=pbx./(Nsubj^2);
val = max(pbx(:));

%act
px = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:length(interval)
    for k = 1:size(p,3)
        px(:,:,k,i)=P*abs(p(:,:,k,i))*P';
    end
end
px=px./(Nsubj^2);
val = max(px(:));

%diffactbsl
newpx = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:length(interval)
    for k = 1:size(newp,3)
        newpx(:,:,k,i)=P*newp(:,:,k,i)*P';
    end
end
newpx=newpx./(Nsubj^2);
val = max(newpx(:));

% integrate early and late timewindow into similarity matrix
% create dummy for earlyXlate similarity matrices

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
% are unspecified & set to 0 at the moment
fill = NaN( 10404,1);
%% For each vertex create complex similarity matrix and compare against model
cV = zeros(1,nVtx);
cA = zeros(1,nVtx);
cS = zeros(1,nVtx);
for k = 1:nVtx
    %divide quadrants of similarity matrix into columns for each time point
    %size(quads) =   10404           4           1           3
    quads=reshape(permute(reshape(newp(:,:,k,:),[Nsubj 2 Nsubj 2 1 3]),[1 3 2 4 5 6]),Nsubj^2,4,1,3);
    quads = squeeze(quads(:,:,1,:));

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
        cV(k) = corr(squareform(M,'tovector')',mv','type','spearman','rows','complete');
        cA(k) = corr(squareform(M,'tovector')',ma','type','spearman','rows','complete');
        cS(k) = corr(squareform(M,'tovector')',ms','type','spearman','rows','complete');
        cA2(k) = corr(squareform(M,'tovector')',ma2','type','spearman','rows','complete');
        cV2(k) = corr(squareform(M,'tovector')',mv2','type','spearman','rows','complete');
    k
end
