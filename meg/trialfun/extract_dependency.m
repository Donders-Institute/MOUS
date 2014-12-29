function [trialinfo,binid,n,uT,ix] = extract_dependency(trialinfo)

% EXTRACT_DEPENDENCY decodes syntactic dependency in the stimulus material
% and assigns each epoch to one (or more) of the following conditions:
%
% 1. (8)  the word's syntactic head is later in the sentence
% 2. (16) the word's syntactic head is earlier in the sentence
% 4. (32) the word is a (local) syntactic head.
% nan. if non of the above.
%
% It loads in the dependency values from the computational model, but is
% followed by a manual fix, where JM checked the accuracy of the model,
% updating the dependency structure in a large majority of sentences.

% load in the stimuli and fix.
stimuli = fix_dependency;

T = nan+zeros(size(trialinfo,1),1);

% assign for each of the sentence words
sel = find(ismember(trialinfo(:,2), [1 2 5 6]));
for k = 1:numel(sel)
  tmp    = trialinfo(sel(k),:);
  sentid = tmp(6);
  wordid = tmp(5);
  
  dj = [stimuli(sentid).words.depjump];
  di = [stimuli(sentid).words.depind];
  nw = stimuli(sentid).numwords;
  
  dj(di>1:nw) = -dj(di>1:nw);
  
  di(find(di==0)) = find(di==0);
  
  T(sel(k)) = 0;
  if any(di==wordid), T(sel(k)) = 4;             end
  if dj(wordid) < 0,  T(sel(k)) = T(sel(k)) + 1; end
  if dj(wordid) > 0,  T(sel(k)) = T(sel(k)) + 2; end
  if T(sel(k))==0,    T(sel(k)) = nan;           end
end

% assign for each of the sequence words, 
% but classify the words according to the corresponding sentences
sel = find(ismember(trialinfo(:,2), [3 4 7 8]));
for k = 1:numel(sel)
  tmp    = trialinfo(sel(k),:);
  seqid  = tmp(6);
  sentid = tmp(6) - 500; % use the corresponding sentence
  wordid = tmp(5);
  if wordid>stimuli(seqid).numwords
    % This happened in 4 out of all subjects, at least with stimulus 891
    T(sel(k)) = nan;
    continue;
  end
  if sentid<0
    T(sel(k)) = nan;
    continue;
  end
  
  dj = [stimuli(sentid).words.depjump];
  di = [stimuli(sentid).words.depind];
  nw = stimuli(sentid).numwords;
  
  wordid_sent = find(strcmpi([stimuli(sentid).words.word],stimuli(seqid).words(wordid).word));
  if numel(wordid_sent)>1
    % this would happen when a word occurs more than once
    wordid_sent = wordid_sent(randperm(numel(wordid_sent)));
    wordid_sent = wordid_sent(1);
  end
  
  dj(di>1:nw)     = -dj(di>1:nw);
  di(find(di==0)) = find(di==0);
  
  T(sel(k)) = 0;
  if any(di==wordid_sent), T(sel(k)) = 32;             end
  if dj(wordid_sent) < 0,  T(sel(k)) = T(sel(k)) + 8;  end
  if dj(wordid_sent) > 0,  T(sel(k)) = T(sel(k)) + 16; end
  if T(sel(k))==0,         T(sel(k)) = nan;            end   
end

trialinfo = [trialinfo T(:)];

% make a histogram to get the distribution of the ordinal positions
% of the labeled words
uT     = unique(T(isfinite(T)));
wordid = trialinfo(:,5);
ix     = 0.5:1:max(wordid+0.5);
binid  = zeros(size(T,1),1)+nan;

for k = 1:numel(uT)
  [n(k,:), bin] = histc(wordid(T==uT(k)),ix);
  binid(T==uT(k)) = bin + (k-1)*max(wordid);
end
n  = n(:,1:end-1);
ix = ix(1:end-1)+0.5; 
