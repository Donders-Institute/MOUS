% Variables
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
tstep = [500]; % in samples
interval = [120];% start interval in samples
nparcel = numel(atlas.parcellationlabel);
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

%% Compute baseline correlation
pbsl = zeros(Nsubj*2,Nsubj*2,nVtx);
sel = zeros(Nsubj*2,length(outbsl.time));
for k = 1:nVtx
    sel = squeeze(outbsl.pow(:,k,:));
    coef = corr(sel');
    pbsl(:,:,k)=coef;
end
clear sel coef d

% average
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];

for k = 1:size(pbsl,3)
    absl(:,:,k)=P*abs(pbsl(:,:,k))*P';
end

absl=absl./(Nsubj^2);
val = max(absl(:));


%% Compute correlation across subjects

p = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
sel = zeros(Nsubj*2,max(tstep));
for k = 1:nVtx
    sel = squeeze(out.pow(:,k,:));
   for i = 1:length(interval)
   %       coef = sel(:,interval(i):interval(i)+tstep(i)) * sel(:,interval(i):interval(i)+tstep(i))';
   %      d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
    %     coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
     coef = corr(sel(:,interval(i):interval(i)+tstep(i))');
    % coef = corr(sel');
    %coef = abs(coef)-abs(pbsl(:,:,k));
    p(:,:,k,i) = abs(coef);
   end
end
%p(p<0) = 0;
%p = 1-p; % distance !! change models if computing distance!!

% average
px = zeros(2,2,nVtx,length(interval));
for i = 1:length(interval)
    for k = 1:size(p,3)
        px(:,:,k,i)=P*p(:,:,k,i)*P';
    end
end
px=px./(Nsubj^2);
val = max(px(:));

%% fisher z-transform & t-test
% take lower triangle and compute mean
% z transform
% for k = 1:nparcel
%     for i = 1:length(interval)
%     tmp = p(:,:,k,i);
%     tmp = .5.*log((1+tmp)./(1-tmp));
%     px(:,:,k,i) = tmp;
%     end
% end
% t-test

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


% Correlate dissimilarity matrix with models

for k = 1:nVtx
    for i = 1:size(p,4)
        tmp = squeeze(p(:,:,k,i));
        tmp(logical(eye(size(tmp)))) = 0;
        cV(k,i) = corr(squareform(tmp,'tovector')',mv','type','spearman');
        cA(k,i) = corr(squareform(tmp,'tovector')',ma','type','spearman');
        cS(k,i) = corr(squareform(tmp,'tovector')',ms','type','spearman');
    end
end
clear tmp
%% Visualize correlation
load atlas_conte69_8196reg_LR_brodmann_subparc
for k = 1:270
figure;imagesc(C(:,:,k,1));caxis([0 1]);
%title(atlas.parcellationlabel(atlas.parcellation(k)));
pause;
end


for k = 1:size(C,3)
%  figure;imagesc(Cx(:,:,k,1));caxis([0 val]);
%  figure;imagesc(Cx(:,:,k,2));caxis([0 val]);
imagesc(Cx(:,:,k,5));caxis([0 val]);
%title(atlas.parcellationlabel(atlas.parcellation(k)));
k
pause;
end

% Plot on surface
pow = reshape(Cx,4,nVtx,length(interval));
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(1,:,3)');
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(2,:,3)');
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(4,:,3)');