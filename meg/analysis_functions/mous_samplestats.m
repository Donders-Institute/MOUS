function [samplestat] = mous_samplestats(trl)

% function that compares the number of samples between the sentences and
% sequences. Outputs the absolute difference in numver of trials, t-test
% and sd.
%
% The output can be stored as part of the preprocessed data or this
% function can be run independetly for all subjects in a script that
% collects the stats for all subjects.

% get trl as input 

% FIXME, now reard to the visual word trial fun and trigger codes. If
% trigger codes are different this may cause problems


% sort the trl into sentences and sequences (Column 5 gives trigger number)

sentIndx = find(trl(:,5)==1 | trl(:,5)==2 | trl(:,5)==5 | trl(:,5)==6);
seqIndx = find(trl(:,5)==3 | trl(:,5)==4 | trl(:,5)==7 | trl(:,5)==8);

% RC sentWord = 1; sent target = 2; MIX sentWord = 5; sent target = 6; 
% RC seqWord = 3; seqTarget = 4; MIX seqWord = 7; seqTarget = 8 

       
% sum the number of samples for each category (col2-col1)

for n = 1 :length(sentIndx)
    sent(n,1) = trl(sentIndx(n),2)-trl(sentIndx(n),1);    
end

for m = 1:length(seqIndx)
    seq(m,1) = trl(seqIndx(m),2)-trl(seqIndx(m),1);    
end


% do stats
[H ,P,CI,samplestat] = ttest2(sent, seq);
samplestat.nullH = H;
samplestat.pValue = P;
samplestat.confInter = CI;

samplestat.diff = sum(sent)-sum(seq);

% report the outcome somehow