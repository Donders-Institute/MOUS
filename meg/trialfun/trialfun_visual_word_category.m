function [outtrl] = trialfun_visual_word_category(subjectname)
% trialfun_visual_word_category
% This function codes the category of each word from each
% trial(sentence/sequence). It does not need the trl (trlA) from
% trialfun_visual_word as an argument as trlA is called from within
% this function. % trlA has 8 columns (see trialfun_visual_word for details), and this
% function makes a 9th column indicate the categories.
% 
% There are 9 categories:
% 1 adjective
% 2 adverb
% 3 noun
% 4 verb
% 11 conjunctions
% 12 determiners
% 13 preposition
% 14 pronouns
% 15 telword

% Details of the code:
% The logfile specific to each participant is read in, the excess
% information is removed, and only the words from each trial are preserved,
% concatenated within each trial, and then matched to the sentences/sequences in catdata.
%    N.B. logfile is iterated twice and we use the 1st interation.
% catdata is the matrix representation of the excel file containing the words and their
% respective categories (coded by hand)

%% Read in logfile
filename = mous_db_getfilename(subjectname,'meg_raw_log');
intxt   =  filename{1};
fid     = fopen(intxt);
fseek(fid,0,'eof');  % at eof to get number of elements in text
numelm  = ftell(fid);
fseek(fid,0,'bof');  % at bof to start reading
alltxt  = fread(fid,numelm,'uint8=>char');  % whole logfile 
fclose(fid); 

%% remove excessive information i.e. lines without words (preceded by a trigger)
% need to use regexp as there is not a consistent format in the logfile
% finaltext{1} = X xx
% finaltext{101} = Xxx
% finaltext{360} = X xx.  (end of sentence)

idx = strfind(alltxt(:)', subjectname); % skip over the line of logfile that codes the extra 'empty word' 
add = idx(end)+80;  
idx = [idx add];
alltxt = alltxt';
newtext = cell(numel(idx)-1,1);
for k = 1:numel(idx)-1
    newtext{k} = alltxt(idx(k):idx(k+1)-1);  % easier to find relevant entry lines in txtfile
end
 
wordpresent = zeros(size(newtext));
for m = 1:size(newtext,1)
    check   = regexp(newtext{m},'Picture\s\d');       % trigger WITH word
    fix     = regexp(newtext{m},'Picture\s\F');       % fixation cross marks start of trial
    space   = regexp(newtext{m},'Picture\s\d\s\s\s'); % trigger WITHOUT word
    if ~isempty(check) && isempty(space) || ~isempty(fix)
        wordpresent(m) = 1;
    end        
end 
idxword = find(wordpresent == 1);
finaltext = newtext(idxword);  % all words in logfile, in chronological order

%% Concatenate words of the same sentence
expwords = cell(240,1);
cnt = 0;
for q = 1:size(finaltext,1)
    wordbeg = regexp(finaltext{q},'Picture\s\d\s?\w','end');  % end = return index of last character specified i.e. '\w'
    wordend = regexp(finaltext{q},'Picture\s\d\s?\w*','end');
    word    = finaltext{q}(wordbeg:wordend);
    if isempty(word)
        cnt = cnt+1;
        expwords{cnt,1} = '';
        continue;
    end
    expwords{cnt,1} = lower(cat(2,expwords{cnt,1},word));
end 
% remove empty cells (some participants did not complete all 240 trials)
% code assumes that no trials are missing in between, but only consecutive
% trials, counting backwards from 240, e.g., participant didn't do last
% block, so last 5 trials are empty
expwords = expwords(~cellfun('isempty',expwords));
%% match trials (usually 240) to excel file with all stimuli (800)
[catnum,~,catdata] = xlsread('home/language/nielam/MOUS_AnalysisNotes/Mous_categories.xls','','','basic'); 

% % Clean cat: shift 1st column down by one, then remove Nans and first row
tmp = catnum(:,1);
tmp = [false;tmp(1:end-1)];
catnum(:,1) = tmp;
catnum(1,:) = [];
catnum(all(isnan(catnum),2),:) = [];

% concatenate all words in a trial, remove empty spaces
% use lower case to get a perfect match (because logfiles across participants are inconsistent e.g., india" and "India" both exist).
catdata = catdata(1:2:end,:);      % remove every other line holding category numbers
catwords = cell(size(catdata,1)/2, 1);
for qq = 1:size(catdata,1)
    %FIXME:(1) suppress warning from using strcat about truncating values
    %      (2) how to remove square box appearing before sentence (eventho it doesn't affect results?)
    catwords{qq} = lower(strcat(2,catdata{qq,2:end})); 
end 

% 2. match the set of experiment trials to entire set of trials
% idx4expword is the index of the sent/seq in catwords, not the (audiofile) name of
% the actual sentence/sequence
idx4expword = [];  % prefer this than zeros(240,1) since some participants have <240 trials
for qq = 1:size(expwords,1)
    itmp     = strfind(catwords,expwords{qq});
    idxsent  = find(not(cellfun('isempty',itmp)));
    if isempty(idxsent)
        warning('%d has no index',qq);  % indices of sentences in expword that don't have a match in catdata
    end 
    idx4expword = [idx4expword; idxsent];  
end

%% load trialfun_visual_word and add to it's trialinfo
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');
prestim     = 0.5; 
poststim    = 3.0;
wordType    = 'all';
trialfun    = 'visual_word';
[trl]       = mous_defineTrial(filename{1}, prestim, poststim, wordType, trialfun); 

fileid = catnum(idx4expword);

% length of each sentence/sequence based on trl matrix
triallen = [];
dumtrl = [trl; ones(size(trl,2),1)'];
for kk = 2:size(dumtrl,1)
    if dumtrl(kk,8) == 1;
        tmplen = dumtrl(kk-1,8);
        triallen = [triallen; tmplen];
    end
end

catvec = [];
for mm = 1:size(idx4expword,1)
    row = find(catnum(:,1) == fileid(mm));
    assignvec = catnum(row,2:end)';
    assignvec(all(isnan(assignvec),2),:) = [];
    assignvec = assignvec(1:triallen(mm));
    catvec = [catvec; assignvec];
end 
outtrl = [trl, catvec];  % catvec is the 9th column in the trl matrix


%% if trialfun is fixed to
% 1) include the last word from the sequence
% 2) made note on which participants the sentences got cut off (Because
% stimuli was incomplete)
% then we can use the code below:

% Here, the code doesn't need to assign category values for each sentence one by
% one, just create the ENTIRE column of category values and then attach
% them as one whole column
%
% catvec = [];
% checker = [];
% for mm = 1:size(idx4expword,1)
%     row = find(cat(:,1) == fileid(mm));
%     assignvec = cat(row,2:end)';
%     assignvec(all(isnan(assignvec),2),:) = []; % remove NaNs from being assigned to trialfun   
%     if fileid(mm) < 500  % sentence trials
%        catvec = [catvec; assignvec];      
%        length = numel(assignvec);
%        tmpc = zeros(length,1);
%        checkvec = [true; tmpc(1:end-1)];
%        checker = [checker; checkvec];
%     elseif fileid(mm) % sequence trials
%        catvec = [catvec; assignvec(1:end-1)];
%        length = numel(assignvec(1:end-1));
%        tmpc = zeros(length,1);
%        checkvec = [true; tmpc(1:end-1)];
%        checker = [checker; checkvec];
%     end    
% end
%
%% useful when checking accuracy of trl and cat.
% % mark start of sentences based on file category values
% for k = 1:size(trl,1)
%     if trl(k,10) == 1 && trl(k,8) ~= 1
%         trl(k,11) = 1;
%     end
% end


