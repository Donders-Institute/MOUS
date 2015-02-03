function [verbshrtdep, verblongdep]= mous_subjMCvsverbRC(data, rseed)
         
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

%% extract verbRC_RC trials
uq      = unique(expRC(:,6));
for k = 1:numel(uq)
  sent_subjpstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).verb2subjMC;
end
idx    = find(ismember(expRC(:,7),sent_subjpstn)); % some of allsubjRC may not be in expRC due to artifact rejection
verb2subjMC_RC   = expRC(idx,:);

%% extract subjMC_RC trials
% select all subjMC_RC: use stimID-subjpstn pair
uq      = unique(expRC(:,6));
for k = 1:numel(uq)
  sent_subjpstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).subjMC;
end
idx    = find(ismember(expRC(:,7),sent_subjpstn)); % some of allsubjRC may not be in expRC due to artifact rejection
subjMC_RC = expRC(idx,:);

%% remove RC sentences that ~senttype = [0 0 0 0] 
senttype = [stimuli(verb2subjMC_RC(:,6)).sentencetype];   % get senttype for remaining RC sentences
senttype = reshape(senttype,[4,size(verb2subjMC_RC,1)])'; 
i        = any(senttype,2);                                 % identify special senttype
verb2subjMC_RC     = verb2subjMC_RC(~i,:);               % remove special senttype

senttype = [stimuli(subjMC_RC(:,6)).sentencetype];   % get senttype for remaining RC sentences
senttype = reshape(senttype,[4,size(subjMC_RC,1)])'; 
i = any(senttype,2);                                 % identify special senttype
subjMC_RC      = subjMC_RC(~i,:);

%% balance number of subjMC and verb2subjMC trials
%  This is different than removing sentences which don't have both subjM
%  and verb2subjMC

n1 = size(subjMC_RC,1);
n2 = size(verb2subjMC_RC,1);
nmin = min(n1,n2); % find lower number of trial
ndif = abs(n1-n2); % find excess number to remove

randomseed(rseed);
idx = randperm(nmin,ndif); % randomly select trials to remove
if n1>n2                   % subjMC has more trials
  subjMC_RC(idx,:) = [];  
elseif n1<n2               % verb2subjMC has more trials
  verb2subjMC_RC(idx,:) = [];
end

%% get subjMC_MX match
%  23.01 w/JM: subjMC and verb2subjMC from all sentences are included, not just
%  those that have a partner in the same sentence.

% create a sentencelength-wordposition column for easy matching
subjMC_RC(:,10)     = false;
subjMC_RC(:,9)      =     subjMC_RC(:,8)*100 + subjMC_RC(:,2);
verb2subjMC_RC(:,9) = verb2subjMC_RC(:,8)*100 + verb2subjMC_RC(:,2);
expMX(:,9)          = expMX(:,8)*100 + expMX(:,2);

% create copies for use in matching
% subjMC_RCtmp = subjMC_RC;
expMXtmp     = expMX;

% perfect match for subjMC_MX
senadd = 0;
for k = 1:size(subjMC_RC,1)
  if ~isempty(find(subjMC_RC(k,9) == expMXtmp(:,9))); % only perform match if there are options
    if k == 1
      chosen = []; % create subjMC_MX matrix
    end
    subjMC_RC(k,10) = true;
    [chosen, subjMC_RC,expMXtmp]  = getmatch(subjMC_RC,expMXtmp,k,senadd,chosen,rseed); % k = current trial
  end
end

% Enter Psuedomatch if using same sentence length for RC and MX produces no
% matches between conditions. This means lengthtry starts at +1 from
% shortest sentence length available
% subjMC_RC(end,10) = false; For Testing purpose only

if sum(subjMC_RC(:,10)) < size(subjMC_RC,1)
idx = find(subjMC_RC(:,10) == false); % create matrix of unmatched RC's
subjMC_RCtmp = subjMC_RC(idx,:);  
senlen = min(subjMC_RC(:,8))+1:max(expMXtmp(:,8)); % 2nd shortest to longest sentences
  
  for lengthtry = 1:senlen   
    for k = 1:size(subjMC_RCtmp,1)  % go through unmatched options
      if ~isempty(find(subjMC_RCtmp(k,9)+lengthtry*100 == expMXtmp(:,9))); % only perform match if there are options
        subjMC_RCtmp(k,10) = true;
        [chosen, subjMC_RCtmp,expMXtmp]  = getmatch(subjMC_RCtmp,expMXtmp,k,lengthtry,chosen,rseed); % k = current trial
        
        if sum(subjMC_RCtmp(:,10)) == size(subjMC_RCtmp,1)
          break;  % exit search when all matches have been found
        end
        
      end
    end
  end
end

subjMC_MX = chosen;
%% get match to find verb2subjMC_MX
verb2subjMC_RC(:,10)     = false;   % mark true for each completed match

% perfect match
senadd = 0;
for k = 1:size(verb2subjMC_RC,1)
  if ~isempty(find(verb2subjMC_RC(k,9) == expMXtmp(:,9))); % only perform match if there are options
    if k == 1
      chosen = []; % create subjMC_MX matrix
    end
    verb2subjMC_RC(k,10) = true;
    [chosen, verb2subjMC_RC,expMXtmp]  = getmatch(verb2subjMC_RC,expMXtmp,k,senadd,chosen,rseed); % k = current trial
  end
end

% pseudomatch
% verb2subjMC_RC(end,10) = false; % For Testing purpose only
% chosen(end,:) = [];

if sum(verb2subjMC_RC(:,10)) < size(verb2subjMC_RC,1)
idx = find(verb2subjMC_RC(:,10) == false); % create matrix of unmatched RC's
verb2subjMC_RCtmp = verb2subjMC_RC(idx,:);  
senlen = min(verb2subjMC_RC(:,8))+1:max(expMXtmp(:,8)); % 2nd shortest to longest sentences
  
  for lengthtry = 1:senlen   
    for k = 1:size(verb2subjMC_RCtmp,1)  % go through unmatched options
      if ~isempty(find(verb2subjMC_RCtmp(k,9)+lengthtry*100 == expMXtmp(:,9))); % only perform match if there are options
        verb2subjMC_RCtmp(k,10) = true;
        [chosen, verb2subjMC_RCtmp,expMXtmp]  = getmatch(verb2subjMC_RCtmp,expMXtmp,k,lengthtry,chosen,rseed); % k = current trial
        
        if sum(verb2subjMC_RCtmp(:,10)) == size(verb2subjMC_RCtmp,1)
          break;  % exit search when all matches have been found
        end
        
      end
    end
  end
  
end
verb2subjMC_MX = chosen;

%% get subjMC_RCWL match
% restart counter for RCWL matches 
subjMC_RC(:,10)     = false;
subjMC_RC(:,9)      =      subjMC_RC(:,8)*100 + subjMC_RC(:,2);
verb2subjMC_RC(:,9) = verb2subjMC_RC(:,8)*100 + verb2subjMC_RC(:,2);
expRCWL(:,9)        = expRCWL(:,8)*100 + expRCWL(:,2);

% create copies for use in matching
% subjMC_RCtmp = subjMC_RC;
expRCWLtmp     = expRCWL;

% perfect match for subjMC_MX
senadd = 0;
for k = 1:size(subjMC_RC,1)
  if ~isempty(find(subjMC_RC(k,9) == expRCWLtmp(:,9))); % only perform match if there are options
    if k == 1
      chosen = []; % create subjMC_MX matrix
    end
    subjMC_RC(k,10) = true;
    [chosen, subjMC_RC,expRCWLtmp]  = getmatch(subjMC_RC,expRCWLtmp,k,senadd,chosen,rseed); % k = current trial
  end
end

% Pseudomatch 
if sum(subjMC_RC(:,10)) < size(subjMC_RC,1)
idx = find(subjMC_RC(:,10) == false); % create matrix of unmatched RC's
subjMC_RCtmp = subjMC_RC(idx,:);  
senlen = min(subjMC_RC(:,8))+1:max(expRCWLtmp(:,8)); % 2nd shortest to longest sentences
  
  for lengthtry = 1:senlen   
    for k = 1:size(subjMC_RCtmp,1)  % go through unmatched options
      if ~isempty(find(subjMC_RCtmp(k,9)+lengthtry*100 == expRCWLtmp(:,9))); % only perform match if there are options
        subjMC_RCtmp(k,10) = true;
        [chosen, subjMC_RCtmp,expRCWLtmp]  = getmatch(subjMC_RCtmp,expRCWLtmp,k,lengthtry,chosen,rseed); % k = current trial
        
        if sum(subjMC_RCtmp(:,10)) == size(subjMC_RCtmp,1)
          break;  % exit search when all matches have been found
        end
        
      end
    end
  end
end

subjMC_RCWL = chosen;

%% get verb2subj_RCWL match
verb2subjMC_RC(:,10)     = false;   % mark true for each completed match

% perfect match
senadd = 0;
for k = 1:size(verb2subjMC_RC,1)
  if ~isempty(find(verb2subjMC_RC(k,9) == expRCWLtmp(:,9))); % only perform match if there are options
    if k == 1
      chosen = []; % create subjMC_MX matrix
    end
    verb2subjMC_RC(k,10) = true;
    [chosen, verb2subjMC_RC,expRCWLtmp]  = getmatch(verb2subjMC_RC,expRCWLtmp,k,senadd,chosen,rseed); % k = current trial
  end
end

% pseudomatch
% verb2subjMC_RC(end,10) = false; % For Testing purpose only
% chosen(end,:) = [];

if sum(verb2subjMC_RC(:,10)) < size(verb2subjMC_RC,1)
idx = find(verb2subjMC_RC(:,10) == false); % create matrix of unmatched RC's
verb2subjMC_RCtmp = verb2subjMC_RC(idx,:);  
senlen = min(verb2subjMC_RC(:,8))+1:max(expRCWLtmp(:,8)); % 2nd shortest to longest sentences
  
  for lengthtry = 1:senlen   
    for k = 1:size(verb2subjMC_RCtmp,1)  % go through unmatched options
      if ~isempty(find(verb2subjMC_RCtmp(k,9)+lengthtry*100 == expRCWLtmp(:,9))); % only perform match if there are options
        verb2subjMC_RCtmp(k,10) = true;
        [chosen, verb2subjMC_RCtmp,expRCWLtmp]  = getmatch(verb2subjMC_RCtmp,expRCWLtmp,k,lengthtry,chosen,rseed); % k = current trial
        
        if sum(verb2subjMC_RCtmp(:,10)) == size(verb2subjMC_RCtmp,1)
          break;  % exit search when all matches have been found
        end
        
      end
    end
  end
  
end
verb2subjMC_RCWL = chosen;

%% get indices that match up to original (full) dataset
  % index of each trial from each condition in original (full) dataset
  [c,subjMC_RC]        = intersect(data.trialinfo(:,7),       subjMC_RC(:,7));       
  [c,verb2subjMC_RC]   = intersect(data.trialinfo(:,7),  verb2subjMC_RC(:,7));
  [c,subjMC_MX]        = intersect(data.trialinfo(:,7),       subjMC_MX(:,7)); 
  [c,verb2subjMC_MX]   = intersect(data.trialinfo(:,7),  verb2subjMC_MX(:,7)); 
  [c,subjMC_RCWL]      = intersect(data.trialinfo(:,7),     subjMC_RCWL(:,7)); 
  [c,verb2subjMC_RCWL] = intersect(data.trialinfo(:,7),verb2subjMC_RCWL(:,7)); 
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction for matching %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [chosenlist, setlist, optionlist] = getmatch(setlist,optionlist,cnt,addlen,chosenlist,rseed)
    % try a longer sentence length (if length = 10, need to *100 for
    % correct format in column 9)
    tmp = find(optionlist(:,9) == setlist(cnt,9)+addlen*100); % get options
    randomseed(rseed);
    tmp = tmp(randperm(size(tmp,1)),:);     % randomly select one of possible options
    if cnt == 1 && isempty(chosenlist)      % cnt==1 == empty chosenlist, but empty chosen list ~= cnt ==1                                  
      chosenlist  = optionlist(tmp(1),:);   % select trials from optionlist
    else
      chosenlist  = [chosenlist; optionlist(tmp(1),:)];  
    end 
    optionlist(tmp(1),:) = [];    % toss out used trial from option list     
end 