function [verbshrtdep, verblongdep]= mous_dependencyshortvslong(data, rseed)

% This function extracts the verb inside the embedded clause of the
% sentence and divides the verbs depending on their distance to the subject
% (to which the verb refers) in the main clause.
% The split between short and long dependency was first determined by
% calculating the frequency of each word position difference available
% across all (102) subjects following artifact rejection.

% Note: In the MOUS stimuli are sentences containing a relative clause.
% Most of these sentences, the relative clause is *also* an embedded clause

% nielam 03 Feb 2014

% get stimuli
load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli');

%% create unique ID for each trial
data.trialinfo(:,7) = data.trialinfo(:,6)*100 + data.trialinfo(:,2); 

%% get original sentence length (from original stimuli, not after artifact rejection)
%  will need to match RCsentences, MXsentences and RCwordlists to be of
%  same length
for k = 1:size(data.trialinfo,1)
  data.trialinfo(k,8) = stimuli(data.trialinfo(k,6)).numwords;  
end

% get trialinfo 
trialinfo = data.trialinfo;   

%% select trials from current experiment (expRC, expMX, expRCWL)
% RC, MX and WL (senRC[1 2], seqRC[3 4], sentMX[5 6], seqMX[7 8])
sel  = find(ismember(trialinfo(:,3),[1 2]));  
expRC = trialinfo(sel,:);
sel  = find(ismember(trialinfo(:,3),[5 6]));  
expMX = trialinfo(sel,:);
sel  = find(ismember(trialinfo(:,3),[3 4]));  
expRCWL = trialinfo(sel,:);

%% extract verbRC_RC trials
uq      = unique(expRC(:,6));
for k = 1:numel(uq)
  sent_subjpstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).verb2subjMC;
end
idx    = find(ismember(expRC(:,7),sent_subjpstn)); % some of allsubjRC may not be in expRC due to artifact rejection
verb   = expRC(idx,:);

%% remove RC sentences that ~senttype = [0 0 0 0] 
senttype = [stimuli(verb(:,6)).sentencetype];   % get senttype for remaining RC sentences
senttype = reshape(senttype,[4,size(verb,1)])'; 
i        = any(senttype,2);                                 % identify special senttype
verb     = verb(~i,:);               % remove special senttype

%% verb's subject position is entered as a 9th column
for k = 1:size(verb,1)
  senid  = verb(k,6);
  verb(k,9) = stimuli(senid).subjMC;  
end

%% divide between short and long dependency verbs
i           = find(verb(:,9) < 3);  % dependency of 1 or 2 word positions
verbshrtdep = verb(i,:);

i           = find(verb(:,9) > 2);  % dependency of >= 3 word positions
verblongdep = verb(i,:);


%% match to original dataset
% index of each trial from each condition in original (full) dataset
[c,verbshrtdep] = intersect(data.trialinfo(:,7),  verbshrtdep(:,7));       
[c,verblongdep] = intersect(data.trialinfo(:,7),  verblongdep(:,7));


 