function [sent, seq] = mous_bfica_freq_contrast(freq1, freq2)

% freq1 is preword
% freq2 is postword

if ~isempty(freq1)
  
  % do planar gradient transformation
  cfg = [];
  cfg.neighbourdist = 4;
  cfg.method        = 'distance';
  cfg.grad          = freq1.grad;
  n                 = ft_prepare_neighbours(cfg);
  
  cfg =[];
  cfg.planarmethod  = 'sincos';
  cfg.neighbours    = n;
  freq1 = ft_megplanar(cfg, freq1);
  freq2 = ft_megplanar(cfg, freq2);
  
  % select conditions
  sel1sent = find(ismember(freq1.trialinfo(:,2), [1 2 5 6])); % sent
  sel2sent = find(ismember(freq2.trialinfo(:,2), [1 2 5 6])); % sent
  sel1seq = find(ismember(freq1.trialinfo(:,2), [3 4 7 8])); % sent
  sel2seq = find(ismember(freq2.trialinfo(:,2), [3 4 7 8])); % sent
  
  ntrials = min([numel(sel1sent) numel(sel1seq) numel(sel2sent) numel(sel2seq)]);
  tmp     = randperm(numel(sel1sent));
  sel1sent = sort(sel1sent(tmp(1:ntrials)));
  tmp     = randperm(numel(sel1seq));
  sel1seq = sort(sel1seq(tmp(1:ntrials)));
  tmp     = randperm(numel(sel2sent));
  sel2sent = sort(sel2sent(tmp(1:ntrials)));
  tmp     = randperm(numel(sel2seq));
  sel2seq = sort(sel2seq(tmp(1:ntrials)));
  
  % average across trials
  cfg = [];
  cfg.trials = sel1sent;
  fd1sent = ft_freqdescriptives(cfg, freq1);
  cfg.trials = sel1seq;
  fd1seq  = ft_freqdescriptives(cfg, freq1);
  cfg.trials = sel2sent;
  fd2sent = ft_freqdescriptives(cfg, freq2);
  cfg.trials = sel2seq;
  fd2seq = ft_freqdescriptives(cfg, freq2);
  
  % combine gradients
  cfg = [];
  fd1sent = ft_combineplanar([], fd1sent);
  fd1seq  = ft_combineplanar([], fd1seq);
  fd2sent = ft_combineplanar([], fd2sent);
  fd2seq  = ft_combineplanar([], fd2seq);
  
  % baseline correct
  sent = fd1sent;
  seq  = fd1seq;
  sent.powspctrm = fd2sent.powspctrm-fd1sent.powspctrm;
  seq.powspctrm  = fd2seq.powspctrm-fd1seq.powspctrm;
  
else
  
  % do planar gradient transformation
  cfg = [];
  cfg.neighbourdist = 4;
  cfg.method        = 'distance';
  cfg.grad          = freq2.grad;
  n                 = ft_prepare_neighbours(cfg);
  
  cfg =[];
  cfg.planarmethod  = 'sincos';
  cfg.neighbours    = n;
  freq2 = ft_megplanar(cfg, freq2);
  
  % select conditions
  sel2sent = find(ismember(freq2.trialinfo(:,2), [1 2 5 6])); % sent
  sel2seq = find(ismember(freq2.trialinfo(:,2), [3 4 7 8])); % sent
  
  ntrials = min([numel(sel2sent) numel(sel2seq)]);
  tmp     = randperm(numel(sel2sent));
  sel2sent = sort(sel2sent(tmp(1:ntrials)));
  tmp     = randperm(numel(sel2seq));
  sel2seq = sort(sel2seq(tmp(1:ntrials)));
  
  % average across trials
  cfg = [];
  cfg.trials = sel2sent;
  fd2sent = ft_freqdescriptives(cfg, freq2);
  cfg.trials = sel2seq;
  fd2seq = ft_freqdescriptives(cfg, freq2);
  
  % combine gradients
  cfg = [];
  fd2sent = ft_combineplanar([], fd2sent);
  fd2seq  = ft_combineplanar([], fd2seq);
  
  % baseline correct
  sent = fd2sent;
  seq  = fd2seq;
 
end
