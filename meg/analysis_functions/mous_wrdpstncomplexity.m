function varargout = mous_wrdpstncomplexity(trialinfo,condition,rseed)
% don't need to specify 'toilop' because will use randomseed when calling qsub
% [RCearly, RClate, MXearly, MXlate] = mous_RCearlylatevsMXearlylate

% this function selects
% 1: the onset of the RC and one word before and after  OR  2nd,3rd,4th word in sentence
% 2: the offset of the RC and one word before and after OR  n-1,n-2,n-3 word in sentence
% averaging across words in #1 forms the RCearly condition
% averaging across words in #2 forms the RClate conditions

% get stimulus information
load('/project/3011020.09/MEG/misc/mous_stimuli.mat');

% add unique ID column
% 1          2            3              4                           5                                % 6           7.
% sentcount  ordinalpstn  word trigger   #smp. relative to 1st word  #smps btw word onset and offset  .wavfile    uniqueID
trialinfo(:,7) = (trialinfo(:,1)*100)+trialinfo(:,2); % uniqueID for each word


%% sentences or word lists
switch condition
  case 'sent'
    rctrig = [1 2];
    mxtrig = [5 6];
  case 'wl'
    rctrig = [3 4];
    mxtrig = [7 8];
end 
sel1  = find(ismember(trialinfo(:,3),rctrig));  % column 3 = presentation triggers
RC = trialinfo(sel1,:);

sel2  = find(ismember(trialinfo(:,3),mxtrig));  
MX = trialinfo(sel2,:);


%% get unique ID for early and late words
pstnearly = [2, 3, 4];
pstnlate  = [1, 2, 3];

% RCearly, RClate
[wavID] = unique(RC(:,6));
for k = 1:numel(wavID)
  len     = stimuli(wavID(k)).numwords;
  idx     = find(RC(:,6) == wavID(k),1);
  sencnt  = RC(idx,1);  % get sentenceID in expmt that corresponds to wavID
  if k == 1
    eID   = (sencnt*100)+pstnearly';
    lID   = (sencnt*100)+(len - pstnlate)';
  else
    eID   = [eID; (sencnt*100)+pstnearly'];
    lID   = [lID; (sencnt*100)+(len - pstnlate)'];
  end
end

% extract early and late words from full dataset
eidx    = find(ismember(RC(:,7),eID));
RCearly = RC(eidx,:);

lidx    = find(ismember(RC(:,7),lID));
RClate  = RC(lidx,:);

clear eID lID

% MXearly, MXlate
[wavID] = unique(MX(:,6));
for k = 1:numel(wavID)
  len     = stimuli(wavID(k)).numwords;
  idx     = find(MX(:,6) == wavID(k),1);
  sencnt  = MX(idx,1);  % get sentenceID in expmt that corresponds to wavID
  if k == 1
    eID   = (sencnt*100)+pstnearly';
    lID   = (sencnt*100)+(len - pstnlate)';
  else
    eID   = [eID; (sencnt*100)+pstnearly'];
    lID   = [lID; (sencnt*100)+(len - pstnlate)'];
  end
end

% extract early and late words from full dataset
eidx    = find(ismember(MX(:,7),eID));
MXearly = MX(eidx,:);

lidx    = find(ismember(MX(:,7),lID));
MXlate  = MX(lidx,:);


%% balance trials between conditions
%  balancing per word position is difficult
%  positions 2,3,4 can be balanced between RCearly and MXearly
%  but how to find equivalent for positions n-1,n-2,n-3 for RClate and MXlate conditions 
  
%  Random removal of trials from each condition should avoid 
%  removing most trials from one word position in each condition
%  -> This goes on the assumption that there is an approximate 
%     uniform distribution across word positions in each condition

numRCearly = size(RCearly,1);
numRClate  = size(RClate,1);
numMXearly = size(MXearly,1);
numMXlate  = size(MXlate,1);

mintrial = min([numRCearly, numRClate, numMXearly, numMXlate]);
randomseed(rseed);
tmp      = randperm(numRCearly);
RCearly  = RCearly(tmp(1:mintrial),:);

randomseed(rseed);
tmp      = randperm(numRClate);
RClate   = RClate(tmp(1:mintrial),:);

randomseed(rseed);
tmp      = randperm(numMXearly);
MXearly  = MXearly(tmp(1:mintrial),:);

randomseed(rseed);
tmp      = randperm(numMXlate);
MXlate   = MXlate(tmp(1:mintrial),:);

%% recover original position of trials in full dataset
[c,i1] = intersect(trialinfo(:,7),RCearly(:,7));       
[c,i2] = intersect(trialinfo(:,7),RClate(:,7));
[c,i3] = intersect(trialinfo(:,7),MXearly(:,7)); 
[c,i4] = intersect(trialinfo(:,7),MXlate(:,7)); 

varargout{1} = i1;
varargout{2} = i2;
varargout{3} = i3;
varargout{4} = i4;

