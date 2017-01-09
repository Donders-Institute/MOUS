
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
tstep = [500]; % in samples
interval = [120];% start interval in samples
nparcel = numel(atlas.parcellationlabel);
maxlag = 50;

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

% for each vertex position find optimal delay using xcorr for all subject-combinations, then for each combination adjust time-course according to lag and compute
% correlation

pl = zeros(Nsubj*2,Nsubj*2,nVtx);
sel = zeros(Nsubj*2,max(tstep));
for k = 1:nVtx
    for l = 1:length(interval)
     
    sel = squeeze(out.pow(:,k,interval(l):interval(l)+tstep(l)));
      
    [r,lag] = xcorr(sel',maxlag); % results in a output r which contains 201(lags) * 204^2, where the first 204 columns contain the delays and cross-correlations using the first subject as a reference 
                           %the next N columns the delays and cross-correlations using the second subject and so on
    % find lag of maximal correlation for each column of r (each combination of
    % subjects)
    [~,index] = max(abs(r));
    lag = lag(index);
    lag = reshape(lag,[Nsubj*2,Nsubj*2]);
    lag = squareform(lag,'tovector');
    count = 1;
    for j = 1:Nsubj*2-1 % loop over columns
        for i = j+1:Nsubj*2 % loop over rows(only lower triangle)
            %zero pad both signals for same size and adjust lag
            tmp1 = zeros(1,size(sel,2)+maxlag*2);
            tmp1(1,(maxlag+1:size(sel,2)+maxlag)) = sel(j,:);
            tmp2 = zeros(1,size(sel,2)+maxlag*2);
            tmp2(1,(maxlag+1+lag(count)):(size(sel,2)+maxlag+lag(count))) = sel(i,:);
            %correlate
            coef = corr(tmp1',tmp2');
            pt(count)= abs(coef);
            count = count+1;
        end
    end
            pl(:,:,k,l) = squareform(pt);
    end
end
clear tmp1 tmp2 coef r index lag
% average
px = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for i = 1:length(interval)
    for k = 1:size(p,3)
        px(:,:,k,i)=P*p(:,:,k,i)*P';
    end
end
px=px./(Nsubj^2);
val = max(px(:));