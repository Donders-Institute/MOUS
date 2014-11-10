function [senRCsubjmc, senRCverbrc, senMXsubjmc, senMXverbrc, seqRCsubjmc, seqRCverbrc] = mous_subjMCvsverbRC(data)
         

% In all sentences with a relative clause this function selects
% i)  subject in the main clause (senRCsubjmc), 
% ii) verb in the relative clause that refers to the subject (senRCverbrc).
% Subsequently, words at equivalent word positions to the aforementioned are then selected (perfect/pseudo
% match) from
% ~  sentences with relative clauses (aka 'RC-', aka 'MIX' sentences (MX = MIX)): to produce
%     iii) senMXsubjmc 
%     iv)  senMXverbrc
% ~  word lists formed from relative clause sentences (aka 'RC+ word list' (WL = word list))
%       v) seqRCsubjmc
%      vi) seqRCverbrc

% These 6 types of trials can then be contrasted in the following manner in
% mous_makecontrast:
% senRCsubjmc-senRCverbmc  vs.  senMXsubjmc-senMXverbmc    vs.  seqRCsubjmc-seqRCverbmc
% senRCsubjmc              vs.  senMXsubjmc                vs.  seqRCsubjmc
% senRCverbrc              vs.  senMXverbrc                vs.  seqRCverbrc  

% To ensure that the same trials are selected for all frequencies at the
% same timepoint, randomseed() is made use when calling the analysis at the
% level of mous_bfica_pipeline, using qsub.

% nielam 10 November 2014

% get trialinfo and create unique ID for each trial
trialinfo = data.trialinfo;
trialinfo(:,7) = trialinfo(:,6)*100 + trialinfo(:,2);

% stimuli details:
load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli.mat');
s = [107 164];
  for k = 1:2 % stupid, but couldn't get multiple fields option to work 
    stimuli(s(k)) = setfield(stimuli(s(k)),'id',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'string',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'numwords',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'RConsetword',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'MCcontinuationword',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'numadditionalclauses',NaN);
    stimuli(s(k)) = setfield(stimuli(s(k)),'additionalclauseinfo',NaN);
  end
% FIXME: add fields to stimuli which will mark the RCsubjMC word position,
% and RCverbRC word position, as well as categories additional
% characteristics of the sentence: setfield()

% stimuli(1:numel(stimuli).subjMC) = ??
  % adverbial phrase = [startpstn endpstn]; else []
  % subjORobjRC      = ['s'] or ['o']
  % rightbranching   = [startpstn endpstn];
  % To determine whether or not RC is embedded, just see if there if the 
  % 'MCcontinuation' field has a word position or not.

% % extract info from stimuli.mat
% allID   = [stimuli.id];
% allsubj = [stimuli.subjMC];        
% allverb = [stimuli.verbRC4subj];

%% select trials
% RC, MX and WL
% senRC[1 2], seqRC[3 4], sentMX[5 6], seqMX[7 8]
sel  = find(ismember(trialinfo(:,3),[1 2]));  
senRCtrl = trialinfo(sel,:);

sel  = find(ismember(trialinfo(:,3),[5 6]));  
senMXtrl = trialinfo(sel,:);

sel  = find(ismember(trialinfo(:,3),[3 4]));  
seqRCtrl = trialinfo(sel,:);

% number of RC in dataset
[f,i] = unique(senRCtrl(:,6),'first'); 
fname = senRCtrl(sort(i),6);
numrc    = numel((find(ismember(fname,1:204))));

% senRCsubjmc
for k = 1:numrc
%   id             = stimuli(fname(k)).id*100 + stimuli(fname(k)).subjMC;    % actual 
  id             = stimuli(fname(k)).id*100 + stimuli(fname(k)).RConsetword; % test run
  tmp            = find(senRCtrl(:,7) == id);
  if ~isempty(tmp)
    idx(k) = tmp;
  else 
    idx(k) = NaN;  % trial removed during artifact rejection
  end
end
idx1 = idx;
senRCsubjmc = trialinfo(idx,:);

% senRCverbrc
for k = 1:numrc
%   id             = stimuli(fname(k)).id*100 + stimuli(fname(k)).verbRC;    % actual 
  id             = stimuli(fname(k)).id*100 + stimuli(fname(k)).RConsetword; % test run
  tmp            = find(senRCtrl(:,7) == id);
  if ~isempty(tmp)
    idx(k) = tmp;
  else 
    idx(k) = NaN;  % trial removed during artifact rejection
  end
end
idx2 = idx;
senRCverbrc= trialinfo(idx,:);

% remove trials that don't have a subjMC or verbRC counterpart
% crucial that i1 and i2 reflect original order of trialinfo
i1 = find(isnan(idx1));
i2 = find(isnan(idx2));

idx1 = 




