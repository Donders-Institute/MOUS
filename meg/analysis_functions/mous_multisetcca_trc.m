function trc = mous_multisetcca_trc(data, stimuli)

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
    selaudio{m} = find(contains(data.label, 'sub-2') & contains(data.label, up{m}));
    selvis{m}   = find(contains(data.label, 'sub-1') & contains(data.label, up{m}));
  end
else
  selaudio{1} = find(contains(data.label, 'sub-2'));
  selvis{1}   = find(contains(data.label, 'sub-1'));
end
[tlck, X, V, ivar, statsall, words] = mous_multisetcca_regress(data, stimuli);

% % identify the nouns, adjectives and verbs
% sel =       double(strncmp([words.POS], 'N',   1))*1;
% sel = sel + double(strncmp([words.POS], 'WW',  2))*2;
% sel = sel + double(strncmp([words.POS], 'ADJ', 3))*3;
% 
% % select these from the data
% words.POS      = words.POS(sel>0);
% words.duration = words.duration(sel>0);
% words.word     = words.word(sel>0);

% don't do a subselection on words, otherwise the randomization cca does
% not make sense too much
%cfg        = [];
%cfg.trials = find(sel);
%tlck        = ft_selectdata(cfg, tlck);

tlck_smooth = tlck;
for m = 1:size(tlck.trial,1)
  tlck_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
end


tmp = permute(tlck_smooth.trial(:,4:end,:),[2 1 3]); % channel 1-3 contain averages
tmp = tmp-nanmean(tmp,2); % subtract the mean across trials.

for k = 1:numel(tlck.time)
  tmpx=tmp(:,:,k);
  tmpc=tmpx*tmpx';
  c(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
end

for k = 1:numel(selaudio)
  for m = 1:numel(selaudio)
    if k==m
      % correction term assumes identity
      trc.rho(:,1,k,m) = squeeze(mean(mean(c(selvis{k},selvis{m},:))))-1./numel(selvis{m});
      trc.rho(:,2,k,m) = squeeze(mean(mean(c(selaudio{k},selaudio{m},:))))-1./numel(selaudio{m});
    else
      % correction term is diagonal of across parcel correlations, but
      % assumes the matrices to be square
      tmpn = numel(selvis{m});
      tmp = c(selvis{k},selvis{m},:);
      for j = 1:size(tmp,3), tmp(:,:,j) = tmp(:,:,j)-diag(diag(tmp(:,:,j))); end
      trc.rho(:,1,k,m) = squeeze(sum(sum(tmp)))./(tmpn.*(tmpn-1));
      tmpn = numel(selaudio{m});
      tmp = c(selaudio{k},selaudio{m},:);
      for j = 1:size(tmp,3), tmp(:,:,j) = tmp(:,:,j)-diag(diag(tmp(:,:,j))); end
      trc.rho(:,2,k,m) = squeeze(sum(sum(tmp)))./(tmpn.*(tmpn-1));
    end
    trc.rho(:,3,k,m) = squeeze(mean(mean(c(selvis{k},selaudio{m},:))));
  end
end
trc.label    = {'visual';'audio';'both'};
if exist('up', 'var'), trc.parcellabel = up(:); end
trc.dimord   = 'chan_time';
trc.time     = tlck_smooth.time;
