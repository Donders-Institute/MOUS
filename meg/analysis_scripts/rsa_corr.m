function [mv_corr,ma_corr,ms_corr,ma2_corr,mv2_corr] = rsa_corr(voxelstart,voxelend,latewindow,windowsize)

% Variables

tstep = windowsize;%+maxlag; % in samples
interval = [1 121 latewindow];% start interval in samples
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);

end
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
count = 1;
for k = voxelstart:voxelend
%% Load mne_source reconstruction for all subjects for one voxel
load(strcat('/project/3011020.09/sopara/mne_pervoxel/baseline/v',num2str(k)))
outbsl = out;
load(strcat('/project/3011020.09/sopara/mne_pervoxel/postonset/v',num2str(k)))


%% Compute baseline correlation
pb = zeros(Nsubj*2,Nsubj*2);
sel = zeros(Nsubj*2,size(outbsl,2));
sel = squeeze(outbsl(:,(end-tstep):end));
n= size(sel,2);
sel = bsxfun(@minus,sel,sum(sel,2)/n);  % Remove mean
coef = sel * sel';
d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
% coef = corr(sel');
pb(:,:)=coef;
clear sel coef d

% average
% pbx(:,:)=P*abs(pb(:,:))*P';
% pbx=pbx./(Nsubj^2);
% val = max(pbx(:));


%% Compute correlation across subjects

p = zeros(Nsubj*2,Nsubj*2,length(interval));

for i = 1:length(interval)
    sel = squeeze(out(:,interval(i):interval(i)+tstep));
    n = size(sel,2);
    sel = bsxfun(@minus,sel,sum(sel,2)/n);  % Remove mean
    coef = sel * sel';
    d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
    coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
%    coef = corr(sel');
    p(:,:,i) = coef;
end
clear sel coef
  
% average
% px = zeros(2,2,length(interval));
% for i = 1:length(interval)
%     px(:,:,i)=P*abs(p(:,:,i))*P';
% end
% px=px./(Nsubj^2);
% val = max(px(:));

%% Subtract baseline correlation
newp = zeros(Nsubj*2,Nsubj*2,length(interval));
for l = 1:length(interval)
    newp(:,:,l)=abs(p(:,:,l))-abs(pb(:,:));
end


%average
% newpx = zeros(2,2,length(interval));
% for i = 1:length(interval)
%     newpx(:,:,i)=P*newp(:,:,i)*P';
% end
% newpx=newpx./(Nsubj^2);
% val = max(newpx(:));

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
% are unspecified & set to Nan 
fill = NaN( 10404,1);
%% For each vertex create complex similarity matrix and compare against model

%divide quadrants of similarity matrix into columns for each time point
%size(quads) =   10404           4           1           3
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
mv_corr(count) = corr(squareform(M,'tovector')',mv','type','spearman','rows','complete');
ma_corr(count) = corr(squareform(M,'tovector')',ma','type','spearman','rows','complete');
ms_corr(count) = corr(squareform(M,'tovector')',ms','type','spearman','rows','complete');
ma2_corr(count) = corr(squareform(M,'tovector')',ma2','type','spearman','rows','complete');
mv2_corr(count) = corr(squareform(M,'tovector')',mv2','type','spearman','rows','complete');
count = count+1;

end
%save(strcat('/project/3011020.09/sopara/mne_pervoxel/modelcorr/v',num2str(voxelnum)),'mv_corr','ma_corr','ms_corr','ma2_corr','mv2_corr')

