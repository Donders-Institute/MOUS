function [T] = extract_wordtype(trialinfo)

% EXTRACT_WORDTYPE
%
% Loads in the stimuli struct-array

% load in the stimuli and fix.
load('mous_stimuli');

T = nan+zeros(size(trialinfo,1),1);

% assign for each of the sentence words
sel = 1:size(trialinfo,1);
for k = 1:numel(sel)
  tmp    = trialinfo(sel(k),:);
  sentid = tmp(6);
  wordid = tmp(5);
  
  T(k) = stimuli(sentid).wordtype(wordid);
end
