function [trc, tlck] = mous_multisetcca_trc(data, stimuli, varargin)

contentwords_only = ft_getopt(varargin, 'contentwords_only', false);
dosmooth          = ft_getopt(varargin, 'dosmooth', 0);
output2           = ft_getopt(varargin, 'output2', 'average_mod');
demeanflag        = ft_getopt(varargin, 'demeanflag', true);

if iscell(data)
    data = ft_appenddata([], data{:});
    
    p = cell(numel(data.label),1);
    for m = 1:numel(data.label)
        % assume evertything before the _ to denote a unique parcel
        tok = tokenize(data.label{m},'_');
        p{m} = tok{1};
    end
    up = unique(p);
    selaudio = cell(1,numel(up));
    selvis   = cell(1,numel(up));
    for m = 1:numel(up)
        selaudio{m} = find(contains(data.label, 'A') & contains(data.label, up{m}));
        selvis{m}   = find(contains(data.label, 'V') & contains(data.label, up{m}));
    end
else
    selaudio{1} = find(contains(data.label, 'A') | contains(data.label, 'sub-2'));
    selvis{1}   = find(contains(data.label, 'V') | contains(data.label, 'sub-1'));
end

if ft_datatype(data, 'raw')
    tlck = mous_multisetcca_extractwords(data, stimuli);
else
    tlck = data;
    if ~exist('selaudio', 'var')
        selaudio{1} = find(contains(tlck.label, 'A'));
        selvis{1}   = find(contains(tlck.label, 'V'));
    end
    % poor man's heuristic to adjust the indices, under the assumption that
    % if the requirement is met, the first 3 channels are to be neglected
    % (as per the hard-coded selection [4:end] downstairs
    if numel(selaudio{1})+numel(selvis{1})<numel(tlck.label)
        selaudio{1} = selaudio{1}-3;
        selvis{1} = selvis{1}-3;
    end
end

if contentwords_only
    % identify the nouns, adjectives and verbs
    sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
    sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
    sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
    
    cfg         = [];
    cfg.trials  = find(sel);
    tlck        = ft_selectdata(cfg, tlck);
end

if dosmooth>0
    % do a boxcar smoothing of the time series
    for m = 1:size(tlck.trial,1)
        tlck.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),dosmooth); % use a smoothing kernel of odd number of samples
    end
end

% permute and reshape the data into a nchan x nobs x ntime
if isequal(tlck.label(1:3),{'visual';'audio';'both'})
    start_idx = 4; % channel 1-3 contain averages
else
    start_idx = 1;
end
dat = permute(tlck.trial(:,start_idx:end,:),[2 1 3]);

% subtract the mean across trials
dat(dat==0) = nan;
if demeanflag
    dat = dat-nanmean(dat,2);
end
dat(~isfinite(dat)) = 0;

c = nan+zeros(size(dat,1),size(dat,1),size(dat,3));
for k = 1:numel(tlck.time)
    datx=dat(:,:,k);
    datc=datx*datx';
    c(:,:,k) = datc./sqrt(diag(datc)*diag(datc)');
end

switch output2
    case 'average_mod'
        for k = 1:numel(selaudio)
            for m = 1:numel(selaudio)
                if k==m
                    % correction term assumes identity
                    trc.rho(:,1,k,m) = squeeze(mean(mean(c(selvis{k},selvis{m},:))))-1./numel(selvis{m});
                    trc.rho(:,2,k,m) = squeeze(mean(mean(c(selaudio{k},selaudio{m},:))))-1./numel(selaudio{m});
                else
                    % correction term is diagonal of across parcel correlations, but
                    % assumes the matrices to be square
                    datn = numel(selvis{m});
                    dat = c(selvis{k},selvis{m},:);
                    for j = 1:size(dat,3), dat(:,:,j) = dat(:,:,j)-diag(diag(dat(:,:,j))); end
                    trc.rho(:,1,k,m) = squeeze(sum(sum(dat)))./(datn.*(datn-1));
                    datn = numel(selaudio{m});
                    dat = c(selaudio{k},selaudio{m},:);
                    for j = 1:size(dat,3), dat(:,:,j) = dat(:,:,j)-diag(diag(dat(:,:,j))); end
                    trc.rho(:,2,k,m) = squeeze(sum(sum(dat)))./(datn.*(datn-1));
                end
                trc.rho(:,3,k,m) = squeeze(mean(mean(c(selvis{k},selaudio{m},:))));
            end
            trc.label    = {'visual';'audio';'both'};
            
        end
    case 'single_cross'
        trc.rho = reshape(c(selvis{1},selaudio{1},:),[],numel(tlck.time));
        for k = 1:numel(selvis{1})
            for m = 1:numel(selaudio{1})
                label{k,m} = sprintf('%s_%s',tlck.label{start_idx-1+selvis{1}(k)}(10:end),tlck.label{start_idx-1+selaudio{1}(m)});
            end
        end
        trc.label = label(:);
end

if exist('up', 'var'), trc.parcellabel = up(:); end
trc.dimord   = 'chan_time';
trc.time     = tlck.time;
