% Variables
nVtx = 8196;
tstep = 120; % in samples
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
load cortex_inflated_8196reg %template surface model

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

%% Compute correlation across subjects
C = zeros(Nsubj*2,Nsubj*2,nVtx,round(numel(out.time)/tstep));
interval = 1;
for i = 1:round(numel(out.time)/tstep)
sel =     squeeze(out.pow(:,:,interval:interval+tstep));
for k = 1:nVtx
    tmp = squeeze(sel(:,1,:));
% coef = sel * sel'; 
% d = sqrt(diag(coef));
% coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
% C(:,:,k,i)=abs(coef);

end
interval = interval + tstep;
end

% compute average correlation across each condition (Visual/Auditory)
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:round(numel(out.time)/tstep)
    for k = 1:size(C,3)
        Cx(:,:,k,i)=P*C(:,:,k,i)*P';
    end
end
Cx=Cx./(Nsubj^2);
val = max(Cx(:));

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
pow = reshape(Cx,4,nVtx,round(numel(out.time)/tstep));
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(1,:,3)');
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(2,:,3)');
figure;h = ft_plot_mesh(sourcemodel,'vertexcolor',pow(4,:,3)');