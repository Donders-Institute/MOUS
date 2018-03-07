function [reorder, stimid] = mous_multisetcca_createshuffle(groupinfo)

% create a reordering vector that shuffles the trials, trying to limit the
% shuffles between sentences with the same word count (approx.)

rng('shuffle');

% get the number of words per trial
n = zeros(numel(groupinfo.stiminfo),1);
for k = 1:numel(groupinfo.stiminfo)
  n(k) = numel(groupinfo.stiminfo(k).words);
end

% sentence count of word counts 
nwords  = unique(n);
n_count = zeros(numel(nwords),1);
for k = 1:numel(nwords)
  n_count(k,1) = sum(n==nwords(k));
end

% adjust if the sentence count <5, move up if word count is low, move down if word
% count is high
n_adjust = nwords(n_count<5);
for k = 1:numel(n_adjust)
  if n_adjust(k)<=median(nwords)
    update = +1;
  else
    update = -1;
  end
  n(n==n_adjust(k)) = n(n==n_adjust(k)) + update;
end

% reorder within the blocks of same word counts to minimize data loss
nwords  = unique(n);
reorder = zeros(size(n));
reorder_n = reorder;
for k = 1:numel(nwords)
  sel = find(n==nwords(k));
  shuf = randperm(numel(sel));
  reorder(n==nwords(k))   = sel(shuf);
  reorder_n(n==nwords(k)) = n(sel(shuf)); % allows for checking 
end
stimid = groupinfo.trialid;
