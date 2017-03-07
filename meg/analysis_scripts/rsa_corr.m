% Variables
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
maxlag = 60;
tstep = 180;%+maxlag; % in samples
n = 1;
interval = [n n+tstep n+tstep+360];% start interval in samples
nparcel = length(atlas.parcellationlabel);
nperm = 1000; %number of parcellations
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
pb = zeros(Nsubj*2,Nsubj*2,nVtx);
sel = zeros(Nsubj*2,length(outbsl.time));
for k = 1:nVtx
    sel = squeeze(outbsl.pow(:,k,(end-tstep):end));
    coef = corr(sel');
    pb(:,:,k)=coef;
end
clear sel coef d

% average
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];

for k = 1:size(pb,3)
    pbx(:,:,k)=P*abs(pb(:,:,k))*P';
end

pbx=pbx./(Nsubj^2);
val = max(pbx(:));


%% Compute correlation across subjects

p = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
sel = zeros(Nsubj*2,max(tstep));
for k = 1:nVtx
    sel = squeeze(out.pow(:,k,:));
   for i = 1:length(interval)
   %       coef = sel(:,interval(i):interval(i)+tstep(i)) * sel(:,interval(i):interval(i)+tstep(i))';
   %      d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
    %     coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
     coef = corr(sel(:,interval(i):interval(i)+tstep)');
    p(:,:,k,i) = coef;
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

