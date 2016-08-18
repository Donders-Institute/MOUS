function [trial, time, trialinfo] = trial2sentences(trialin, trialinfoin, toi)

% [trial,time,trialinfo] = trial2sentences(trialin, trialinfoin, toi)
%
% Converts single trial matrix into cell-array of trials based on 
% the trialinfo. Trialinfo is assumed to contain:
%  - column 1: sentence index
%  - column 2: time window index

% assume the number of sentences<1000, and the following yield unique identifiers for the trials
trialid  = trialinfoin(:,1);
utrialid = unique(trialid);
ntrial   = numel(utrialid);

trial = cell(1,ntrial);
time  = cell(1,ntrial);
cnt   = 0;
for k = 1:ntrial
  sel  = trialid==utrialid(k);
  tmp  = trialin(:,sel);
  indx = trialinfoin(sel,2);
  
  % check whether there are discontinuities (i.e. partially rejected
  % artifacts)
  dindx = diff([indx;inf]);
  nsnip = sum(dindx>1);
  idx   = find(dindx>1);
  idx   = [0;idx];
  for m = 1:nsnip
    cnt        = cnt + 1;
    trial{cnt} = tmp(:,(idx(m)+1):idx(m+1));
    time{cnt}  = toi(indx((idx(m)+1):idx(m+1)));
    trialinfo(cnt,1) = utrialid(k);
  end
end
