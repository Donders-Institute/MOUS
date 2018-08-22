function [trc, tlck] = mous_multisetcca_trc(data, stimuli, varargin)

output            = ft_getopt(varargin, 'output', 'rho');
contentwords_only = ft_getopt(varargin, 'contentwords_only', false);
longwords_only    = ft_getopt(varargin, 'longwords_only', false);
dosmooth          = ft_getopt(varargin, 'dosmooth', 0);
partialize_avg    = ft_getopt(varargin, 'partialize_avg', 0);
shift             = ft_getopt(varargin, 'shift', []);
condition         = ft_getopt(varargin, 'condition', 'all');
untilnextword     = ft_getopt(varargin, 'untilnextword', false);
untilnextword_visual = ft_getopt(varargin, 'untilnextword_visual', false);

switch output
  case 'rho'
    outputflag = 0;
  case 'Z'
    outputflag = 1;
  case 'Z_scaled'
    outputflag = 2;
end


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
  if ~strcmp(condition, 'all')
    if strcmp(condition, 'sent')
      tmpcfg.trials = find(data.trialinfo(:,end)<500); % assume the stimulus ID in the last column of trialinfo
    elseif strcmp(condition, 'seq')
      tmpcfg.trials = find(data.trialinfo(:,end)>500);
    elseif strcmp(condition, 'sent_rc')
      tmpcfg.trials = find(data.trialinfo(:,end)<205);
    elseif strcmp(condition, 'sent_mix')
      tmpcfg.trials = find(data.trialinfo(:,end)<500&data.trialinfo(:,end)>204);
    elseif strcmp(condition, 'seq_rc')
      tmpcfg.trials = find(data.trialinfo(:,end)>500&data.trialinfo(:,end)<705);
    elseif strcmp(condition, 'seq_mix')
      tmpcfg.trials = find(data.trialinfo(:,end)>704);
    end
    data = ft_selectdata(tmpcfg, data);
  end
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


if longwords_only
  sel = [];
  for i = 1:length(tlck.trialinfo.word) 
      if length(tlck.trialinfo.word{i})>5
      sel = [sel i];
      end
  end
  cfg        = [];
  cfg.trials = sel;
  tlck       = ft_selectdata(cfg, tlck);
end

if outputflag>0
  % temporarily replace 0 with their original nans, in order to properly
  % compute a d.f.
  tlck.trial(tlck.trial==0) = nan;
end

if dosmooth>0
  % do a boxcar smoothing of the time series
  for m = 1:size(tlck.trial,1)
    tlck.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),dosmooth); % use a smoothing kernel of odd number of samples
  end
end

if untilnextword
  % this effectively does not take the data into account that has a latency
  % > the modality specific duration of the word.
  selv = find(contains(tlck.label,'sub-1')|contains(tlck.label,'V1'));
  sela = find(contains(tlck.label,'sub-2')|contains(tlck.label,'A2'));
  for m = 1:size(tlck.trial,1)
    ix1 = nearest(tlck.time,tlck.trialinfo.duration2(m,1));
    ix2 = 1;
    try ix2 = nearest(tlck.time,tlck.trialinfo.duration2(m,2)); end
    tlck.trial(m,sela,ix1:end) = nan;
    tlck.trial(m,selv,ix2:end) = nan;
  end
end
if untilnextword_visual
  % this effectively does not take the data into account that has a latency
  % > the visual modality specific duration of the word (so no discontinuities in the auditory data, due to the remapping.
  selv = find(contains(tlck.label,'sub-1')|contains(tlck.label,'V1'));
  sela = find(contains(tlck.label,'sub-2')|contains(tlck.label,'A2'));
  for m = 1:size(tlck.trial,1)
    ix1 = nearest(tlck.time,tlck.trialinfo.duration2(m,1));
    ix2 = 1;
    try ix2 = nearest(tlck.time,tlck.trialinfo.duration2(m,2)); end
    tlck.trial(m,sela,ix2:end) = nan;
    tlck.trial(m,selv,ix2:end) = nan;
  end
end

% permute and reshape the data into a nchan x nobs x ntime
dat = permute(tlck.trial(:,4:end,:),[2 1 3]); % channel 1-3 contain averages

% subtract the mean across trials
dat = dat-nanmean(dat,2);
dat(~isfinite(dat)) = 0;

if ~isempty(shift) && numel(shift)==size(dat,1)
  maxshift = max(shift);
  n = size(dat,3);
  datnew = nan(size(dat,1),size(dat,2),n-maxshift);
  for m = 1:numel(shift)
    datnew(m,:,:) = dat(m,:,(shift(m)+1):(n+shift(m)-maxshift));
  end
  dat = datnew;
  tlck.time = tlck.time(1:size(datnew,3));
end

if outputflag>0
  % convert back to 0
  dof = squeeze(sum(isfinite(dat),2));
  dat(~isfinite(dat)) = 0;
end

c = nan+zeros(size(dat,1),size(dat,1),size(dat,3));
for k = 1:numel(tlck.time)
  if partialize_avg
    for m = 1:numel(tlck.time)
      dat1 = dat(:,:,k);
      dat2 = dat(:,:,m);
      if m==1
        datc = [dat1;dat2]*[dat1;dat2]';
      else
        datc = datc+[dat1;dat2]*[dat1;dat2]';
      end
    end
    datc = datc./numel(tlck.time);
    
    ix1 = 1:size(dat,1);
    ix2 = ix1+size(dat,1);
    datc = datc(ix1,ix1)-datc(ix1,ix2)*inv(datc(ix2,ix2))*datc(ix2,ix1);
  else
    datx=dat(:,:,k);
    datc=datx*datx';
  end
  c(:,:,k) = datc./sqrt(diag(datc)*diag(datc)');
  if outputflag>0
    % Fisher Z transform with standardization
    n = min(dof(:,k),dof(:,k)');
    c(:,:,k) = atanh(c(:,:,k))./sqrt(1./(n-3));
    c(~isfinite(c)) = 1; % replace the fisher z transformed infinity values with 1
  end
end

for k = 1:numel(selaudio)
  for m = 1:numel(selaudio)
    if k==m
      % correction term assumes identity
      if outputflag<2
        trc.rho(:,1,k,m) = squeeze(mean(mean(c(selvis{k},selvis{m},:))))-1./numel(selvis{m});
        trc.rho(:,2,k,m) = squeeze(mean(mean(c(selaudio{k},selaudio{m},:))))-1./numel(selaudio{m});
      else
        dat = c(selvis{k},selvis{m},:)+repmat(diag(nan(numel(selvis{k}),1)),[1 1 size(dat,3)]);
        dat = reshape(dat,[],size(dat,3));
        %dat(~isfinite(dat)) = [];
        trc.rho(:,1,k,m) = nanmean(dat,1)./nanstd(dat,[],1);
        dat = c(selaudio{k},selaudio{m},:)+repmat(diag(nan(numel(selaudio{k}),1)),[1 1 size(dat,3)]);
        dat = reshape(dat,[], size(dat,3));
        %dat(~isfinite(dat)) = [];
        trc.rho(:,2,k,m) = nanmean(dat,1)./nanstd(dat,[],1);
      end
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
    
    if outputflag<2
      trc.rho(:,3,k,m) = squeeze(mean(mean(c(selvis{k},selaudio{m},:))));
    else
      dat = c(selvis{k},selaudio{m},:);
      dat = reshape(dat,[],size(dat,3));
      trc.rho(:,3,k,m) = nanmean(dat,1)./nanstd(dat,[],1);
    end
  end
end
trc.label    = {'visual';'audio';'both'};
if exist('up', 'var'), trc.parcellabel = up(:); end
trc.dimord   = 'chan_time';
trc.time     = tlck.time;
