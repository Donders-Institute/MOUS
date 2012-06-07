% mous_groupanalysis_tfr

% get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
for k = 1:numel(subjlist)
  %tmp = mous_db_getdata(subjlist{k}, 'meg_processed_...');
  load([basedir subjlist{k} '/TFR/' subjlist{k} '_ds_tfr_05-3pg']);
  freq1{k} = TFRHann_Diff_PG;              
  freq2{k} = TFRMult_Diff_PG;   
end

nsubj = numel(freq1);
freq1(nsubj+(1:nsubj)) = freq1;
freq2(nsubj+(1:nsubj)) = freq2;
for k = 9:16
  freq1{k}.powspctrm(:) = 0;
  freq2{k}.powspctrm(:) = 0;
end

cfg = [];
cfg.method = 'montecarlo';
cfg.numrandomization = 0;
cfg.parameter = 'powspctrm';
cfg.statistic = 'depsamplesT';
cfg.design    = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.ivar      = 1;
cfg.uvar      = 2;
stat1 = ft_freqstatistics(cfg, freq1{:});
stat2 = ft_freqstatistics(cfg, freq2{:});
