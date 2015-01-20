function varargout = mous_RCMXbalanced_RConoffset(sourcedata,contrast, rseed)
% don't need to specify 'toilop' because will use randomseed when calling qsub
% [RCearly, RClate, MXearly, MXlate] = mous_RCearlylatevsMXearlylate
% [RConset  RCoffset]                = mous_RcearlylatevsMXearlylate

% this function selects
% 1: the onset of the RC and one word before and after  OR  2nd,3rd,4th word in sentence
% 2: the offset of the RC and one word before and after OR  n-1,n-2,n-3 word in sentence

% averaging across words in #1 forms the RCearly condition
% averaging across words in #2 forms the RClate conditions

% consider fixing other two RC scripts, so that there is more consistency
% and neatness


%% [trialinfo] add column 7 to reflect sentence length after artifact rejection
% 1          2            3              4                           5                                6          7 
% sentcount  ordinalpstn  word trigger   #smp. relative to 1st word  #smps btw word onset and offset  .wavfile   total num words
sentid = unique(sourcedata.trialinfo(:,1));       
nwords = zeros(size(sentid,1),size(sentid,2));
for kk = 1:numel(sentid)
  currlen = max(sourcedata.trialinfo(sourcedata.trialinfo(:,1)==sentid(kk),2));  % extract sentence length
  i = find(sourcedata.trialinfo(:,1) == sentid(kk));                  % get number of words in sentence
  sourcedata.trialinfo(i(1):i(end),7) = currlen*ones(numel(i),1);     % add senlen to these words
end

%% [trialinfo] - rearrange columns suitable as input to mous_makecontrast{early-late} 
% (2) reorder columns and remove column 6 (.wav filename)  %FIXME - keep this for e1:3, l1:3
% 1         2            3             4              5                                6                                7         8
% sentence, ordinalpstn, word trigger, total # words, smp# relative to 1st word onset, smp# btw word onset-word offset, .wavfile, uniqueID for each
% word
sourcedata.trialinfo = sourcedata.trialinfo(:,[1 2 3 7 4 5 6]);
sourcedata.trialinfo(:,8) = (sourcedata.trialinfo(:,1)*100)+sourcedata.trialinfo(:,2); % uniqueID for each word

%% extract trialinfo for easier manipulation
trialinfo = sourcedata.trialinfo;

%% [select data]
switch contrast
  case 'RCMX'
    sel1 = find(ismember(trialinfo(:,3),[1 2]));  %sent RC [sen: 1 2  seq: 3 4] 
    dat1 = ft_selectdata(sourcedata,'rpt',sel1);

    sel2 = find(ismember(trialinfo(:,3),[5 6]));  %sent MX [sen: 5 6  seq: 7 8]
    dat2 = ft_selectdata(sourcedata,'rpt',sel2);

  case 'RConoff' 
    %% WORK IN PROGRESS %%
    load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli.mat');
    % 001 - 204 = RC, but  file 107 and 164 do not exist (in experiment or in
    % this mat file) which leads to error when using square brackets
    % amend with the following
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
    
    % log unique identity for each trial
    trialinfo(:,9) = trialinfo(:,7)*100 + trialinfo(:,2);
    
    % get RC 
    sel1 = find(ismember(trialinfo(:,3),[1,2]));
    RC   = trialinfo(sel1,:);

    % extract info from stimuli.mat
    allID      = [stimuli.id];
    allRConset = [stimuli.RConsetword];        
    allMCcont  = [stimuli.MCcontinuationword];

    % select single words (trials) for RConset
    % ????? do we average across these three word position, would this dilute the effect?
    % dilute the effect ?????
    sentid = unique(RC(:,7));
    for k = 1:size(sentid,1)
      % FIXME: might have to save the tmp values to find MX matches
      early     = [allRConset(sentid(k))-1 allRConset(sentid(k)) allRConset(sentid(k))+1];  % word positions around RConset
      tmp       = allID(sentid(k))*100 + early;                                             % get these words' indices in dataset
      i         = find(ismember(RC(:,9),tmp));   
      RC(i,10)  = 1;
    end

    % select single word (trials) for RCoffset
    for k = 1:size(sentid,1)
      % FIXME: might have to save the tmp values to find MX matches
      early     = [allMCcont(sentid(k))-1 allMCcont(sentid(k)) allMCcont(sentid(k))+1];  % word positions around RConset
      tmp       = allID(sentid(k))*100 + early;                                             % get these words' indices in dataset
      i         = find(ismember(RC(:,9),tmp));   
      RC(i,11)  = 2;  % make in separate column, see if there is overlap
    end
    
    i   = find(RC(:,10) == 1);  % relate these back to the full trialinfo
    i2  = RC(i,:);
    sel1  = find(ismember(trialinfo(:,9),i2(:,9)));
    dat1  = trialinfo(sel1,:);  % RC onset

    i     = find(RC(:,11) == 2); 
    i2    = RC(i,:);
    sel2  = find(ismember(trialinfo(:,9),i2(:,9)));
    dat2  = trialinfo(sel2,:);  % RC offset
end

%% balance the number of words for each word position (balance # trials  between RC and MIX)
% reasons to not balance:
% ~ maximise power given low trials per subject
% ~ for RConset/offset this would randomly remove word position, and this
% contrast relies on there being 3 positions for onset, and 3 for offset
% might be better to ignore sentences with <3 positions for onset, and
% offset
% balance assumes that word positions are consecutive (no gaps, e.g., 3 5 6)
tmp  = unique(dat1.trialinfo(:,2));  % word positions in RC cdtn
tmp2 = unique(dat2.trialinfo(:,2)); % word positions in MX cdtn
matchedpstn = min(numel(tmp),numel(tmp2));  


%% Balance the number of trials at each word position
% randomseed means more consistency for analyzing across frequencies
  % For each wordposition-timepoint pair the same trials are used for
  % all frequencies in the same range (low, medium, high)
  % Due to matching, there will be an equal number of trials per condition
  for q = 1:matchedpstn
    % equate number of trials for each condition
    sel1 = find(dat1.trialinfo(:,2) == q);  n1 = numel(sel1);
    sel2 = find(dat2.trialinfo(:,2) == q);  n2 = numel(sel2);
    n = min(n1,n2);
    
    % randomise trials (because not selecting all, make a random subselection)
    randomseed(rseed);  % seed determined when calling qsub.
    tmp1 = randperm(n1);
    tmp2 = randperm(n2);

    % assign trials to condition
    idat1 = sel1(sort(tmp1(1:n)));
    idat2 = sel2(sort(tmp2(1:n)));

    % store trials for each word position
    % in mous_makecontrast, these words will be averaged
    if q == 1
      idat1all = idat1;  idat2all = idat2;
    else
      idat1all = [idat1all; idat1]; % RC
      idat2all = [idat2all; idat2]; % MX
    end
  end % loop for word position
  
  switch contrast  % assume averaging across trials for each condition (i.e. 3 word positions per cdtn)
    case 'RCMX'
      % dat1 = RC, dat2 = MX
      RCall = ft_selectdata(dat1,'rpt',idat1all);  
      MXall = ft_selectdata(dat2,'rpt',idat2all);
      
      endpstn = matchedpstn - [1 2 3];
      i   = find(ismember(RCall.trialinfo(:,2),[2 3 4]));
      RCe = ft_selectdata(RCall,'rpt',i);
      
      i   = find(ismember(RCall.trialinfo(:,2),endpstn));
      RCl = ft_selectdata(RCall,'rpt',i);
      
      i   = find(ismember(MXall.trialinfo(:,2),[2 3 4]));     
      MXe = ft_selectdata(MXall,'rpt',i);
      
      i   = find(ismember(MXall.trialinfo(:,2),endpstn));      
      MXl = ft_selectdata(MXall,'rpt',i);
      
      % index of each trial from each condition in original (full) dataset
      [c,i1] = intersect(sourcedata.trialinfo(:,8),RCe.trialinfo(:,8));       
      [c,i2] = intersect(sourcedata.trialinfo(:,8),RCl.trialinfo(:,8));
      [c,i3] = intersect(sourcedata.trialinfo(:,8),MXe.trialinfo(:,8)); 
      [c,i4] = intersect(sourcedata.trialinfo(:,8),MXl.trialinfo(:,8)); 
      
      varargout{1} = i1;
      varargout{2} = i2;
      varargout{3} = i3;
      varargout{4} = i4;

    case 'RConoff'
      % return indices to select trials
      varargout{1} = sel1;  % RConset
      varargout{2} = sel2;  % RCoffset
  %     varargout{3} = sel3;  % MXonset  (or word list?)
  %     varargout{4} = sel4;  % MXoffset (or word list?)
  end 
