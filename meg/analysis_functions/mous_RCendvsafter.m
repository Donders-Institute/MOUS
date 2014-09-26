function [RCend, RCafter, MXend, MXafter] = mous_RCendvsafter(data, T)

% This function selects four words from the sentence stimuli 
% sentence stimuli has two types: Relative Clauses (RC) and non-relative
% clauses (RC-).
% 1. the word at the end of the RC
% 2. the word following the end of the RC 
% 3. The equivalent of #1 in the RC- sentences
% 4. The equivalent of #2 in the RC- sentences
%    In this way 1 is matched for word position with 3, and 2 with 4, in
%    sentences of the same length ('perfect match').
%    Under the circumstances that the same word position and same sentence
%    length match cannot be found in the RC- sentences, an iterative procedure
%    will be used where the word position remains constant while the sentence
%    length increases by one ('pseudo-perfect match').
% Not all RCend words have a RCafter word from the same sentence (and vice versa)
%    this (1) maximises number of words for each word type and (2) is
%    acceptable because we aren't (yet) doing pair-wise (RCend vs. RCafter) comparisons 

% trialinfo columns
% 1.  sentence count
% 2.  word position
% 3.  trigger code (RC/MX word/target)
% 4.  sample number relative to the onset of the first word
% 5.  number of samples between word on and offset
% 6.  stimulus id (auditory filename)
% 7.  sentence length
% 8.  sentence length + word position
% 9.  1 = RCend, 2 = RCafter 
% 10. combined unique index: sentence counter*10000 | sentence length * 100 | word position 
% 11. 1 = match found, 0 = no match found

% NL  22 Sept 2014

% stimuli properties (location of RC clause)
load('/home/language/nielam/MOUS_Stimuli/mous_stimuli.mat'); 

% column 7: sentence length
for k = 1:size(data.trialinfo,1)
  data.trialinfo(k,7) = stimuli(data.trialinfo(k,6)).numwords;
end

% column 10: used to find corresponding trial between data and MXend RCend MXafter RCafter
data.trialinfo(:,10)      = data.trialinfo(:,1)*10000 + data.trialinfo(:,7)*100 + data.trialinfo(:,2);

% select all words from MX sentences
sel = find(ismember(T,[5 6]));  
cfg2 = [];
cfg2.trials = sel;
dataMX = ft_selectdata(cfg2,data); 

% select all words from RC sentences
sel = find(ismember(T,[1 2]));  
cfg2 = [];
cfg2.trials = sel;
dataRC = ft_selectdata(cfg2,data);    

% select only words from RCend and RCafter positions
% get indices of words 
for k = 1:size(dataRC.trialinfo,1) 
  RCafter = stimuli(dataRC.trialinfo(k,6)).MCcontinuationword;
  RCend = RCafter-1;

  if dataRC.trialinfo(k,2) == RCend
    sel1(k) = true; 
    selall(k) = true;
  elseif dataRC.trialinfo(k,2) == RCafter
    sel2(k) = true;
    selall(k) = true;
  end          
end 

% select words 
cfg2 = [];
cfg2.trials = find(sel1);  % RCend
dataRCend   = ft_selectdata(cfg2, dataRC);

cfg2.trials = find(sel2);  % RCafter
dataRCafter = ft_selectdata(cfg2, dataRC);
 
cfg2.trials = find(selall);  % N.B. dataRCall = allRCend/RCafter words (dataRC = allRCwords)
dataRCall   = ft_selectdata(cfg2, dataRC); 

% column 8: identifies match between RCend/RCafter and RCall (in proceeding for-loop)
dataRCend.trialinfo(:,8)   = dataRCend.trialinfo(:,6)*1000 + dataRCend.trialinfo(:,7)*10 + dataRCend.trialinfo(:,2);
dataRCafter.trialinfo(:,8) = dataRCafter.trialinfo(:,6)*1000 + dataRCafter.trialinfo(:,7)*10 + dataRCafter.trialinfo(:,2);
dataRCall.trialinfo(:,8)   = dataRCall.trialinfo(:,6)*1000 + dataRCall.trialinfo(:,7)*10 + dataRCall.trialinfo(:,2);

% column 9: RCend (1)  or  RCafter (2)
% log RCend and RCafter in RCall. Transfer info RCall -> MXchosen
% *note column 9 will be empty in MX and chosenMX (to keep columns constant between RC and MX)
for k = 1:size(dataRCall.trialinfo,1)
  tmp = find(dataRCend.trialinfo(:,8) == dataRCall.trialinfo(k,8));
  if ~isempty(tmp)
    dataRCall.trialinfo(k,11) = 1;
  else
    tmp = find(dataRCafter.trialinfo(:,8) == dataRCall.trialinfo(k,8));
    dataRCall.trialinfo(k,11) = 2;
  end
end

%%%%%% MATCHING RC with MX %%%%%%%
% "Perfect": match as many trials for word position and sentence length
% "Pseudo-perfect": iterative procedure, maintain same word position but
% search in longer sentences (each iteration +1 word in sentence length)

% column 8: used to search for match between RC and MX
data.trialinfo(:,8)   = (data.trialinfo(:,7)*100) + data.trialinfo(:,2);
dataRCall.trialinfo(:,8) = (dataRCall.trialinfo(:,7)*100) + dataRCall.trialinfo(:,2);
dataMX.trialinfo(:,8) = (dataMX.trialinfo(:,7)*100) + dataMX.trialinfo(:,2);

% column 11: match (true) / no match (false)
RC = dataRCall.trialinfo; % RC = copy of dataRCall
RC(:,9) = false;         % false, turns true when match is found (used to log trials for pseudo-match)

MX = dataMX.trialinfo;
% column 11 added when going through for-loop

% PERFECT MATCH
for k = 1:size(RC,1)
  if ~isempty(find(MX(:,8) == RC(k,8)));
    if k == 1
      chosenMX  =  zeros(0,size(MX,2)+1);  % extra column to code for RCend/RCafter match
      senadd    = 0;  % senadd only need for pseudo-match (below)
    end
    [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
  end
end

% PSEUDO MATCH (iterate from RC minlength + 1 to MX max length)
% assume: constant word position with increasing sentence length
% at each iteration will be sufficient to find a match.
% otherwise, use a different word position (not coded) 

idx      = find(RC(:,9) == 0);  % find failure from perfect match
impRC    = RC(idx,:);       
len      = min(impRC(:,7));     
MXmaxlen = max(MX(:,7));        % note: not all lengths between min and max may be available
lenrange = MXmaxlen - len;      % maximum number of iterations to search for pseudo-match 
for k = 1:size(impRC,1)
  if ~exist('chosenMX','var')   % if no perfect matches found
    chosenMX = zeros(0,size(MX,2));
  end
  
  % find same word position in a longer sentence (extend sentence length from min(impRC length) to max(MXlen))
  for q = 1:lenrange
    senadd = q*100;  
    if ~isempty(find(MX(:,8) == impRC(k,8)+senadd)); 
      [chosenMX, MX, impRC]  = getmatch(MX,impRC,k,senadd,chosenMX);
      break;  % once match is found: exit iteration across sentence lengths 
    end
  end
end

% output arguments
RCend   = find(ismember(data.trialinfo(:,10),dataRCend.trialinfo(:,10)));
RCafter = find(ismember(data.trialinfo(:,10),dataRCafter.trialinfo(:,10)));

idx     = find(chosenMX(:,11) == 1);
MXend   = chosenMX(idx,:);
MXend   = find(ismember(data.trialinfo(:,10),MXend(:,10)));

idx     = find(chosenMX(:,11) == 2);
MXafter = chosenMX(idx,:);
MXafter = find(ismember(data.trialinfo(:,10),MXafter(:,10)));
  
end % mousRCendvsafter 

%%%%%%% subfunction %%%%%%
function [chosenMX, mx, rc] = getmatch(mx,rc,cnt,addlen,chosenMX)

    tmp2 = find(mx(:,8) == rc(cnt,8)+addlen);  % get options
    tmp2 = tmp2(randperm(size(tmp2,1)),:);     % permute
    if cnt == 1 && isempty(chosenMX)                                    
      chosenMX  = [mx(tmp2(1),:) rc(cnt,11)]; % select MXtrial
    else
      chosenMX  = [chosenMX; mx(tmp2(1),:) rc(cnt,11)];  
    end 
    irm       = find(mx(:,10) == chosenMX(end,10));  % find used MX trial
    mx(irm,:) = [];                                  % toss out  MX trial         
    rc(cnt,9)  = true;                               % mark RC trial as having found match
end 

