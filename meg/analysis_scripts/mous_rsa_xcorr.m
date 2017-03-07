
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

load /project/3011020.09/sopara/lags/xcorr_lagmaxvalstim
clear lag
load /project/3011020.09/sopara/lags/xcorr_lagmaxvalbsl
clear lag

%make correlational matrix symmetric by averaging over the two diagonal
%entries

p = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
for k = 1:nVtx
    for l = 1:length(interval)
        p(:,:,k,l) = (ptmp(:,:,k,l)+ptmp(:,:,k,l)')./2;
    end
end


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
        pbx(:,:,k)=P*pb(:,:,k)*P';
    end

pbx=pbx./(Nsubj^2);
val = max(pbx(:));

%act
px = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:length(interval)
    for k = 1:size(p,3)
        px(:,:,k,i)=P*p(:,:,k,i)*P';
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
fill = zeros( 10404,8196);
quads=reshape(permute(reshape(newp,[Nsubj 2 Nsubj 2 8196 3]),[1 3 2 4 5 6]),Nsubj^2,4,8196,3);

M = cat(3,squeeze(quads(:,1,:,2)),fill,squeeze(quads(:,2,:,2)),fill,fill,squeeze(quads(:,1,:,3)),fill,squeeze(quads(:,2,:,3)),squeeze(quads(:,2,:,2)),fill,squeeze(quads(:,4,:,2)),fill,fill,squeeze(quads(:,2,:,3)),fill,squeeze(quads(:,4,:,3)));

for k = 1:nVtx
M = col2im(M,[Nsubj Nsubj],[Nsubj*4 Nsubj*4],'distinct')
end


%% Create model matrix
% visual-specific model
mv=ones(408);
mv(1:102,103:end)=0;
mv(103:end,:)=0;
mv = mv-diag(diag(mv));
mv=squareform(mv,'tovector');
% auditory-specific model
ma=zeros(408);
ma(205:306,205:306)=1;
ma = ma-diag(diag(ma));
ma=squareform(ma,'tovector');
% supramodal model
ms=zeros(408);
ms(103:204,103:204)=1;
ms(307:408,103:204)=1;
ms(103:204,307:408)=1;
ms(307:408,307:408)=1;
ms = ms-diag(diag(ms));
ms=squareform(ms,'tovector');
% mixed model supramodal + early visual
% mixed model supramodal + early auditory
% mixed model supramodal + early both
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