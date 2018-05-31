% Variables
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
maxlag = 60;
tstep = 120;%+maxlag; % in samples
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


%% Compute cross-correlation across subjects for baseline

% for each vertex position find optimal delay using xcorr for all subject-combinations, 
% for bsl condition

pb = zeros(Nsubj*2,Nsubj*2,nVtx);
sel = zeros(Nsubj*2,tstep+maxlag);
lagb = zeros(Nsubj*2,Nsubj*2,nVtx);
for k = 1:nVtx
    sel = squeeze(outbsl.pow(:,k,end-tstep:end));
    
    if all(all(isnan(sel)))
        lagb(:,:,k) = nan(Nsubj*2);
        pb(:,:,k) = nan(Nsubj*2);
    else
        
        cfg = [];
        cfg.lag = -maxlag:maxlag;
        [r,lag] = statfun_xcorr2(cfg,sel,sel);
        r = reshape(r,size(r,1)*size(r,2),size(r,3));
        
       % find throughs and peaks of xcorr lag-function
        [pindx pval] = peakdetect2(r);
        
        % adjust lag information to be centered around zero.
        pindx = pindx - ((size(r,2)+1)/2);
        
        % find lags corresponding to peaks closest to 0 (nanmin) or maximum correlation (nanmax);
        [~,index] = nanmax(abs(pval),[],2);
        linearInd = sub2ind(size(pindx), [1:41616]', index);
        tmp = pindx(linearInd);
        % if no peak is within maxlag range take 0;
        tmp(isnan(tmp)) = 0;
        
        %backwards reshape
        lagb(:,:,k) = reshape(tmp,Nsubj*2,Nsubj*2);
        tmp = pval(linearInd);
        tmp(isnan(tmp)) = 0;
        pb(:,:,k) = reshape(tmp,Nsubj*2,Nsubj*2);
    end
end
save('/project/3011020.09/sopara/lags/xcorr_lagmaxvalbsl','lagb','pb','-v7.3')
clear lagb outbsl pb

%% Compute lag for each subject-combination and vertex
tmp = zeros((Nsubj*2)*(Nsubj*2),1);
lag = zeros(Nsubj*2,Nsubj*2,nVtx);   
sel = zeros(Nsubj*2,size(out.pow,3));
for k = 1:nVtx
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
    [~,index] = nanmax(abs(pindx),[],2);
    linearInd = sub2ind(size(pindx), [1:41616]', index);
    tmp = pindx(linearInd);
    % if no peak is within maxlag range take 0;
    tmp(isnan(tmp)) = 0;

    %backwards reshape
    lag(:,:,k) = reshape(tmp,Nsubj*2,Nsubj*2);
 end
end
clear linearInd pindx pval r

% Compute correlation coefficients for each interval in active condition
ptmp = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
tmp1 = zeros(Nsubj*2,size(out.pow,3)+maxlag*2);
tmp2 = zeros(Nsubj*2,size(out.pow,3)+maxlag*2);
for k = 1:nVtx
    sel = squeeze(out.pow(:,k,:));
    if all(all(isnan(sel)))
        ptmp(:,:,k,:) = nan(Nsubj*2,Nsubj*2,3);
    else
        for j = 1:size(sel,1)
            tmp2 = shiftdat3(sel(j,:), lag(:,j,k),maxlag);
            tmp1 = [zeros(Nsubj*2,maxlag) sel zeros(Nsubj*2,maxlag)];
            for l = 1:length(interval)
                coef = corr_percolumn(tmp1(:,interval(l):interval(l)+tstep)',tmp2(:,interval(l):interval(l)+tstep)');
                ptmp(:,j,k,l) = coef';
            end
        end
    end
end
clear coef tmp1 tmp2 sel


% take average of paired values (slight variation because of slightly
% different interval): make matrix symmetric again.

for k = 1:nVtx
    for l = 1:length(interval)
        ptmp(:,:,k,l) = (ptmp(:,:,k,l)+ptmp(:,:,k,l)')./2;
    end
end

save('/project/3011020.09/sopara/lags/xcorr_lagmaxvalstim','lag','ptmp','-v7.3')

