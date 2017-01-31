% Variables
load cortex_inflated_8196reg %template surface model
load atlas_conte69_8196reg_LR_brodmann_subparc
nVtx = 8196;
maxlag = 60;
tstep = 120+maxlag; % in samples
n = 1;
interval = [n n+tstep n+tstep+360];% start interval in samples
nparcel = length(atlas.parcellationlabel);
nperm = 500; %number of parcellations
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
for k = 1:nVtx
    sel = squeeze(outbsl.pow(:,k,end-(tstep+maxlag):end));

    cfg = [];
    cfg.lag = -maxlag:maxlag;
    [r,lag] = statfun_xcorr2(cfg,sel,sel); 
    
    
     pb(:,:,k) = max(abs(r),[],3);
end

% pbx = zeros(2,2,nVtx);
% P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
%     for k = 1:size(pb,3)
%         pbx(:,:,k)=P*pb(:,:,k)*P';
%     end
% 
% pbx=pbx./(Nsubj^2);
% val = max(pbx(:));

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
    [~,index] = nanmin(abs(pindx),[],2);
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
p = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
for k = 1:nVtx
    for l = 1:length(interval)
        p(:,:,k,l) = (ptmp(:,:,k,l)+ptmp(:,:,k,l)')./2;
    end
end

% average
px = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for l = 1:length(interval)
    for k = 1:size(p,3)
        px(:,:,k,l)=P*p(:,:,k,l)*P';
    end
end
px=px./(Nsubj^2);
val = max(px(:));

%% Subtract bsl 
newp = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
for l = 1:length(interval)
    for k = 1:size(p,3)
        newp(:,:,k,l)=abs(p(:,:,k,l))-pb(:,:,k);
    end
end

newpx = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for l = 1:length(interval)
    for k = 1:size(newp,3)
        newpx(:,:,k,l)=P*newp(:,:,k,l)*P';
    end
end
newpx=newpx./(Nsubj^2);



%% Permutation test
% permute baseline and active time window correlations per subject under
% the null-hypothesis that they come from the same distributions.

% create permutation vector with indexes for flipping sign

r = randi([0 1],1,20706,nperm);
rindx= zeros(Nsubj*2,Nsubj*2,nperm);
for l = 1:nperm
    rindx(:,:,l) = squareform(r(:,:,l));
end


tmp = zeros(Nsubj*2,Nsubj*2);
perm = zeros(2,2,nVtx,length(interval),nperm);
for i = 1:length(interval)
    for k = 1:nVtx
        for l = 1:nperm
           tic
           tmp = squeeze(newp(:,:,k,i));
%            if all(all(isnan(tmp)))
%            else
            % permute signs of correlation (under the null hypothesis, it
            % would not matter whether bsl is subtracted from activity or
            % other way around
            %
            % find indexes to be shuffled
            flip = find(rindx(:,:,l)==1);
            % apply permutation 
            tmp(flip) = -tmp(flip);
            % save to permutation distribution
            tmp2=P*tmp*P';
            tmp2=tmp2./(Nsubj^2);
            perm(:,:,k,i,l) = tmp2;
            toc
        end
    end
end
clear r flip tmp rindx

% stats
x = squeeze(newpx(1,1,:,:));
 permx = squeeze(perm(1,1,:,:,:));
for k = 1:nVtx
    for i = 1:length(interval)
        if x(k,i) >= permx(k,i,end-  )
            sig(k,i) = 1;
        else
            sig(k,i) = 0;
        end
    end
end
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

