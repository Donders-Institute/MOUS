function trc = mous_multisetcca_trc(data, stimuli)
  
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

selaudio = find(contains(data.label, 'sub-2'));
selvis   = find(contains(data.label, 'sub-1'));

tmp = permute(tlck_smooth.trial(:,4:end,:),[2 1 3]);
tmp = tmp-nanmean(tmp,2);

for k = 1:numel(tlck.time)
  tmpx=tmp(:,:,k);
  tmpc=tmpx*tmpx';
  c(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
end
trc.rho(:,1) = squeeze(mean(mean(c(selvis,selvis,:))))-1./numel(selvis);
trc.rho(:,2) = squeeze(mean(mean(c(selaudio,selaudio,:))))-1./numel(selaudio);
trc.rho(:,3) = squeeze(mean(mean(c(selvis,selaudio,:))));
trc.label    = {'visual';'audio';'both'};
trc.dimord   = 'chan_time';
trc.time     = tlck_smooth.time;
