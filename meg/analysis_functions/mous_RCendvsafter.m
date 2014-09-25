function [RCend, RCafter, chosenMX] = mous_RCendvsafter(data, T)

% This function selects four words from the sentence stimuli 
% sentence stimuli has two types: Relative Clauses (RC) and non-relative
% clauses (RC-).
% 1. the word at the end of the RC
% 2. the word following the end of the RC 
% 3. The equivalent of #1 in the RC- sentences
% 4. The equivalent of #2 in the RC- sentences
% In this way 1 is matched for word position with 3, and 2 with 4, in
% sentences of the same length ('perfect match')
% Under the circumstances that the same word position and same sentence
% length match cannot be found in the RC- sentences, an iterative procedure
% will be used where the word position remains constant while the sentence
% length increases by one ('pseudo-perfect match')


% data.trialinfo:
% 1.  sentence count
% 2.  word pstn 
% 3.  trigger code (RC/MX word/target)
% 4.  sample number relative to the onset of the first word
% 5.  number of samples between word on and offset
% 6.  stimulus id (auditory filename)
% 7.  sentence length
% 8.  sen length + word position
% 9. 

% NL  22 Sept 2014

% stimuli properties (location of RC clause)
load('/home/language/nielam/MOUS_Stimuli/mous_stimuli.mat'); 

% sentence length = column 7
for k = 1:size(data.trialinfo,1)
  data.trialinfo(k,7) = stimuli(data.trialinfo(k,6)).numwords;
end

% select all words from MX sentences
sel = find(ismember(T,[5 6]));  
cfg2 = [];
cfg2.trials = sel;
dataMX = ft_selectdata(cfg2,data); 

% select *all* words from RC sentences
sel = find(ismember(T,[1 2]));  
cfg2 = [];
cfg2.trials = sel;
data = ft_selectdata(cfg2,data);    

% select only words from RCend and RCafter positions
% get indices of words 
for k = 1:size(data.trialinfo,1) 
  RCafter = stimuli(data.trialinfo(k,6)).MCcontinuationword;
  RCend = RCafter-1;

  if data.trialinfo(k,2) == RCend
    sel1(k) = true; 
    selall(k) = true;
  elseif data.trialinfo(k,2) == RCafter
    sel2(k) = true;
    selall(k) = true;
  end          
end 
% select words 
cfg2 = [];
cfg2.trials = find(sel1);  % RCend
dataRCend   = ft_selectdata(cfg2, data);

cfg2.trials = find(sel2);  % RCafter
dataRCafter = ft_selectdata(cfg2, data);

cfg2.trials = find(selall);
dataRCall   = ft_selectdata(cfg2, data);

% number of shared RC sentences between RCend words and RCafter words
% all sentences - shared sentence = X
% X sentences, each contains either RCend, RCafter, or none (due to
% artifact rejection)
% [c,i1,i2] = union(dataRCend.trialinfo(:,6),dataRCafter.trialinfo(:,6));
% numRCsen = numel(c); 


% Get MX match for each RC 
% "Perfect": match as many trials for word position and sentence length
% "Pseudo-perfect": iterative procedure, maintain same word position but
% search in longer sentences (each iteration +1 word in sentence length)

% in dataRCall, dataMX: column8 has a unique code which combines 
% sentence length and word position
dataRCall.trialinfo(:,8) = (dataRCall.trialinfo(:,7)*10) + dataRCall.trialinfo(:,2);
dataMX.trialinfo(:,8) = (dataMX.trialinfo(:,7)*10) + dataMX.trialinfo(:,2);

% MX and RC are copies of dataMX and dataRCall, respectively
% sort MX and RC by sentence length, then word position
RC = dataRCall.trialinfo;
RC(:,9) = false;         % make true when match has been found (below)

MX = dataMX.trialinfo;
MX(:,9) = 1:size(MX,1);  % index rows in MX (used as reference below)

% PERFECT MATCH
for k = 1:size(RC,1)
  if ~isempty(find(MX(:,8) == RC(k,8)));
    if k == 1
      chosenMX  =  zeros(0,size(MX,2));
      senadd    = 0;  % senadd only need for pseudo-match (below)
    end
    [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
  end
end

% Get pseudo-perfect match (iterate from RC minlength + 1 to MX max length)
idx = find(RC(:,9) == 0);
impRC  = RC(idx,:);       % get remaining words
len = min(impRC(:,7));   % 
MXmaxlen = max(MX(:,7)); % note: not all lengths between min and max may be available
lenrange = MXmaxlen - len; 
for k = 1:size(impRC,1)
  if ~exist('chosenMX','var')
    % only ~exist if no perfect matches available
    chosenMX = zeros(0,size(MX,2));
  end
  
  % find same word position in a longer sentence (incremental search)
  for q = 1:lenrange
    senadd = q*10;  % limit iteration to maxlen.
    if ~isempty(find(MX(:,8) == impRC(k,8)+senadd)); 
      [chosenMX, MX, impRC]  = getmatch(MX,impRC,k,senadd,chosenMX);
      break;  % exit iteration across sentence lengths once match is found
    end
  end
end
  
end % mousRCendvsafter 

%%%%%%% subfunction %%%%%%
function [chosenMX, mx, rc] = getmatch(mx,rc,cnt,addlen,chosenMX)

    tmp2 = find(mx(:,8) == rc(cnt,8)+addlen);  % get options
    tmp2 = tmp2(randperm(size(tmp2,1)),:);     % permute
    if cnt == 1 && isempty(chosenMX)                                    
      chosenMX  = mx(tmp2(1),:);               % select MXtrial
    else
      chosenMX  = [chosenMX; mx(tmp2(1),:)];  
    end 
    irm       = find(mx(:,9) == chosenMX(end,9));  % find used MX trial
    mx(irm,:) = [];                            % toss out  MX trial         
    rc(cnt,9)  = true;                          % mark RC trial as having found match
end

%% repeated for-loop for perfect-match
%   if ~isempty(tmp)
%     tmp    = tmp(randperm(size(tmp,1)),:);  % randomize options
%     if k == 1
%       chosenMX  = MX(tmp(1),:);  % create new matrix of relevant trials 
%     else
%       chosenMX  = [chosenMX; MX(tmp(1),:)]; 
%     end
%     irm = find(MX(:,9) == chosenMX(end,9));% get used MX trial
%     MX(irm,:) = [];                          % toss out used MX trial         
%     RC(k,9) = true;                         % mark RC trial as having found match

%% repeat for pseudo-match
%   elseif ~isempty(find(MX(:,8) == impRC(k,8)+20))
%     senadd = 20;
%     [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
%     
%   elseif ~isempty(find(MX(:,8) == impRC(k,8)+30))
%     senadd = 30;
%     [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
%     
%   elseif ~isempty(find(MX(:,8) == impRC(k,8)+40))
%     senadd = 40;
%     [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
%     
%   elseif ~isempty(find(MX(:,8) == impRC(k,8)+50))
%     senadd = 50;
%     [chosenMX, MX, RC]  = getmatch(MX,RC,k,senadd,chosenMX);
