function [early, late] = extract_earlylate(trialinfo)

% EXTRACT_EARLYLATE extracts the lists of indices torows in the trialinfo 
% matrix, corresponding to the 'early' 2-4, and 'late' n-3 - n-1 word
% positions


% load in the stimuli and fix the dependencies.
stimuli = fix_dependency; % dependency fixing is not necessary, but does not hurt

% assign for each of the sentence words
early = false(size(trialinfo,1),1);
late  = false(size(trialinfo,1),1);
for k = 1:size(trialinfo,1)
  tmp    = trialinfo(k,:);
  sentid = tmp(6);
  wordid = tmp(5);
  nw     = stimuli(sentid).numwords;
  
  if wordid==2||wordid==3||wordid==4
    early(k) = true;
  elseif wordid==nw-1||wordid==nw-2||wordid==nw-3
    late(k) = true;
  end
end

early = find(early);
late  = find(late);