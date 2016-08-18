function [early, late] = mous_compate_wordlength_earlylate(trialinfo)

% MOUS_COMPARE_WORDLENGTH_EARLYLATE compares the wordlength of the 'early'
% versus the 'late' words. Early and late words are defined according to
% extract_earlylate. 
%
% Use as:
% 
% [early, late] = mous_compare_wordlength_earlylate(trialinfo)

wl    = extract_wordlength(trialinfo);
[e,l] = extract_earlylate(trialinfo);

early = wl(e);
late  = wl(l);