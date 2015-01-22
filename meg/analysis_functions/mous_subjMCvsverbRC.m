function [subjMC_RC, verbRC_RC, subjMC_MX, verbRC_MX, subjMC_RCWL, verbRC_RCWL]= mous_subjMCvsverbRC(data, rseed)
         
% In all sentences with a relative clause this function selects
% i)  subjMC_RC:  subject in the main clause (senRCsubjmc), 
% ii) verbRC_RC:  verb in the relative clause that refers to the subject (senRCverbrc).
% Subsequently, words at equivalent word positions to the aforementioned are then selected (perfect/pseudo
% match) from
% sentences with relative clauses (aka 'MX' for MIX sentences)
%  iii) subjMC_MX
%  iv)  verbRC_MX
% word lists formed from relative clause sentences (aka 'RC+ word list' (WL = word list))
%  v) subjMC_RCWL
%  vi) verbRC_RCWL

% sentences are retained if they have a subjMC and verbRC after artifact
% detection, and are not a special sentence (i.e. sentencetype = [0 0 0 0];
% A perfect match means: same word position and sentence/Wordlist length
% A psuedo match means:  same word postiion, and closest sentence/wordlist
% length

% If a perfect match (in the MX and RCWL cannot be found, a pseudomatch is
% used in order to retain as many trials as possible (across all conditions).
% a pseudo match is reasonable because subjects do know #sent/wordlist length

% These 6 types of trials can then be contrasted as follows:
% subjMC_RC - verbRC_RC  vs.  subjMC_RCWL - verbRC_RCWL  vs.  subjMC_MX - verbRC_MX
% NL; 10 November 2014

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


%% extract subjMC_RC trials
% select all subjMC_RC: use stimID-subjpstn pair
uq      = unique(expRC(:,6));
for k = 1:numel(uq)
  sent_subjpstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).subjMC;
end
idx    = find(ismember(expRC(:,7),sent_subjpstn)); % some of allsubjRC may not be in expRC due to artifact rejection
subjMC_RC = expRC(idx,:);

%% extract verbRC_RC trials
uq      = unique(expRC(:,6));
for k = 1:numel(uq)
  sent_subjpstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).verb2subjMC;
end
idx    = find(ismember(expRC(:,7),sent_subjpstn)); % some of allsubjRC may not be in expRC due to artifact rejection
verb2subjMC_RC = expRC(idx,:);

%% remove RC sentences that do not have a subj-verb pair
[~,iverb, isubj] = intersect(verb2subjMC_RC(:,6),subjMC_RC(:,6));
verb2subjMC_RC = verb2subjMC_RC(iverb,:);
subjMC_RC      = subjMC_RC(isubj,:);

%% remove RC sentences that ~senttype = [0 0 0 0] 

senttype = [stimuli(subjMC_RC(:,6)).sentencetype];   % get senttype for remaining RC sentences
senttype = reshape(senttype,[4,size(subjMC_RC,1)])'; 
i = any(senttype,2);                                 % identify special senttype
verb2subjMC_RC = verb2subjMC_RC(~i,:);               % remove special senttype
subjMC_RC      = subjMC_RC(~i,:);
 

%% Find MX matches
% create subjMC-verb2subjMC pairs for RC
RCpair      = zeros(size(subjMC_RC,1),2);
RCpair(:,1) =      subjMC_RC(:,8)*100 +      subjMC_RC(:,2);  % sentencelength-wordpstn pair
RCpair(:,2) = verb2subjMC_RC(:,8)*100 + verb2subjMC_RC(:,2);
RCpair(:,3) = false  % flag as true when match has been found

% if multiple match options; permute and select first one
% sort RCpair in order of sentencelength-wordposition

% FIXME: how to ensure that 1105-1108 are chosen from same MXsentence?

% 1 create sentencelength-wordpstn pairs in MX
expMX(:,9) = expMX(:,8)*100 + expMX(:,2);

% 2 pairup subjMC_MX and verb2subjMC_MX from the same sentence
% 3 sort, so that shorter sentences are used first.



% perfect match
for k = 1:size(subjMC_RC,1)
  % get trial with matching senlength-wordpstn pair
  if ~isempty(find(subjMC_RC(:,X) == subjMC_MX(:,X)));
    if k == 1
      chosen = zeros(0,size(senRCsubjmc,2));
      senadd = 0;
    end
    [chosen, senRCsubjmc, ]  = getmatch(senRCsubjmc,senMXsubjmc,k,senadd,chosen,rseed);
  end
end
% pseudo match


%% Find RCWL matches
% perfect match
% pseudo match

%% get indices that match up to original (full) dataset
  % index of each trial from each condition in original (full) dataset
  [c,i1] = intersect(data.trialinfo(:,8),       subjMC_RC(:,8));       
  [c,i2] = intersect(data.trialinfo(:,8),  verb2subjMC_RC(:,8));
  [c,i3] = intersect(data.trialinfo(:,8),       subjMC_MX(:,8)); 
  [c,i4] = intersect(data.trialinfo(:,8),  verb2subjMC_MX(:,8)); 
  [c,i5] = intersect(data.trialinfo(:,8),     subjMC_RCWL(:,8)); 
  [c,i6] = intersect(data.trialinfo(:,8),verb2subjMC_RCWL(:,8)); 

  [c,subjMC_RC]        = intersect(data.trialinfo(:,8),       subjMC_RC(:,8));       
  [c,verb2subjMC_RC]   = intersect(data.trialinfo(:,8),  verb2subjMC_RC(:,8));
  [c,subjMC_MX]        = intersect(data.trialinfo(:,8),       subjMC_MX(:,8)); 
  [c,verb2subjMC_MX]   = intersect(data.trialinfo(:,8),  verb2subjMC_MX(:,8)); 
  [c,subjMC_RCWL]      = intersect(data.trialinfo(:,8),     subjMC_RCWL(:,8)); 
  [c,verb2subjMC_RCWL] = intersect(data.trialinfo(:,8),verb2subjMC_RCWL(:,8)); 
  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction for matching %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [chosenMX, mx, rc] = getmatch(mx,rc,cnt,addlen,chosenMX,rseed)
    randomseed(rseed);
    tmp2 = find(mx(:,8) == rc(cnt,8)+addlen);  % get options
    tmp2 = tmp2(randperm(size(tmp2,1)),:);     % randomly select one of possible options
    if cnt == 1 && isempty(chosenMX)                                    
      chosenMX  = [mx(tmp2(1),:) rc(cnt,11)]; % select MXtrial
    else
      chosenMX  = [chosenMX; mx(tmp2(1),:) rc(cnt,11)];  
    end 
    irm       = find(mx(:,10) == chosenMX(end,10));  % find used MX trial
    mx(irm,:) = [];                                  % toss out  MX trial         
    rc(cnt,9)  = true;                               % mark RC trial as having found match
end 