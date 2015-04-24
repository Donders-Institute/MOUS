function [wordlength] = extract_wordlength(trialinfo)

% EXTRACT_LEXFREQ extracts the lexical frequencies of the items presented,
% as represented in the input trialinfo matrix.


% load in the stimuli and fix the dependencies.
stimuli = fix_dependency; % dependency fixing is not necessary, but does not hurt
lexfreq = nan+zeros(size(trialinfo,1),1);

% assign for each of the sentence words
for k = 1:size(trialinfo,1)
 tmp    = trialinfo(k,:);
  sentid = tmp(6);
  wordid = tmp(5);
  
  wordlength(k) = numel(stimuli(sentid).words(wordid).word{1});
end
