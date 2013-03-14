% trialfun_visual_word_category
% indicates the word category of each word in the sentence
% there are 9 categories
% 1 adjective
% 2 adverb
% 3 noun
% 4 verb
% 11 conjunctions
% 12 determiners
% 13 preposition
% 14 pronouns
% 15 telword
% (1) read in logfile to get words for each trial (sent/seq) = A
% (2) read in excel file where each word's category has been coded = B
% (3) match words in A to those in B to get the appropriate categories
% ** as A (i.e. logfile) doesn't indicate the number for each sent/seq,
% that means we need to match stimuli between A and B (ARGG.. silly logfile)

%% read in logfile of stimuli and matfile of sent/seq length
% N.B. logfile is iterated twice, but we only read the first iteration (that's good!)
% load senlen  % C1 = sentence number, C2 = sentence length 

%% Read in logfile
intxt  = '/home/language/annhul/MOUS/meg/V1010/RAW/V1010-4-MEG-MOUS-Vis.log';
fid = fopen(intxt);
fseek(fid,0,'eof');  % at eof to get number of elements in text
numelm = ftell(fid);
fseek(fid,0,'bof');  % at bof to start reading
alltxt = fread(fid,numelm,'uint8=>char');  % whole logfile 
fclose(fid); 

%% remove excessive information i.e. lines without words (preceded by a trigger)
idx = strfind(alltxt(:)','V1010'); % skip over the line of logfile that codes the extra 'empty word' 
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
% finaltext{1} = X xx
% finaltext{101} = Xxx
% finaltext{360} = X xx.  (end of sentence)
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


%% match trials (240) to excel file (800)
% 1. read in excel file with range: A1 - Q1599
% this excel file removes all the <'s> from all words in order to match the words in catwords  (strcat remove 's in words)
[cat,text,catdata] = xlsread('home/language/nielam/MOUS_AnalysisNotes/Mous_categories.xls','','A1:Q1599','basic'); 

% put categorisation into a separate matrix, removing first NaN column
% each row is one sentence/sequence
% FIXME: how to remove trailing NaNs of each row without automatic reshaping matrix
% into vector 
catnum = cat(2:2:end,:);
catnum = catnum(:,2:end);

% turn trials into concatenated words
% use lower case for everything to get a perfect match (since logfiles have both "india"  and "India").
catdata = catdata(1:2:end,:);      % remove every other line holding category numbers
catwords = cell(size(catdata,1)/2, 1);
for qq = 1:size(catdata,1)
    catwords{qq} = lower(strcat(2,catdata{qq,2:end})); %%FIXME:there's a funny square box before the sent/seq   
end 

% 2. match sentences/sequences
% N.B. check if matlab will flipout for ptp's with <240 trials

% idx4expword is the index of the sent/seq in catwords, not the (audiofile) name of
% the actual sentence/sequence
idx4expword = [];  % prefer this than assigning space because some participants have <240 trials
%idx4expword = zeros(240,1)
for qq = 1:size(expwords,1)
    % catwords is first arguement cuz it is a cellstr (the one to check thru)
    itmp     = strfind(catwords,expwords{qq}); % going for 100% match, but there possessive s, and capitals causing issues
    idxsent  = find(not(cellfun('isempty',itmp)));
    if isempty(idxsent)
        warning('%d has no index',qq);  % indices of sentences in expword that don't have a match in catdata
    end 
    idx4expword = [idx4expword; idxsent];  
    %idx4expword(qq,1) = idxsent;          % this one stops after expword{17}, why?
end

%% load trialfun_visual_word and add to it's trialinfo
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');
prestim     = 0.5; 
poststim = 3.0;
wordType    = 'all';
trialfun    = 'visual_word';
[trl] = mous_defineTrial(filename{1}, prestim, poststim, wordType, trialfun); 

% Clean cat: shift 1st column down by one, and remove NaNs 
tmp = cat(:,1);
tmp = [false;tmp(1:end-1)];
cat(:,1) = tmp;
cat(1,:) = [];
cat(all(isnan(cat),2),:) = [];

fileid = cat(idx4expword);
% CHANGE:  don't need to assign category values for each sentence one by
% one, just create the ENTIRE column of category values and then attach
% them as one whole column
% NOPE, can´t do that cuz stimuli in presentation (hence logfile) is wrong (one word short) in
% some sentences. 

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
% % mark start of sentences based on file category values
% for k = 1:size(trl,1)
%     if trl(k,10) == 1 && trl(k,8) ~= 1
%         trl(k,11) = 1;
%     end
% end

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
    row = find(cat(:,1) == fileid(mm));
    assignvec = cat(row,2:end)';
    assignvec(all(isnan(assignvec),2),:) = [];
    assignvec = assignvec(1:triallen(mm));
    catvec = [catvec; assignvec];
end 


% catvec = 2631 values.  extra 5...
% trl = 2625 values
% catvec = [catvec(1:end-6)];
% checker = [checker(1:end-6)];
%trl = [trl, catvec, checker];
trl = [trl, catvec];


%% doesn't work
% 
% dlmread(intxt, '\t', 6, 1);
% 
% fid = fopen(intxt);
% A = fscanf(fid, '%s');
% fclose(fid);

% [input,pos] = textscan(fid,'%*s %*d    %*s   %s   %*d %*d %*d %*d %*d %*s %*s %*s %*s',...
%                  'Delimiter','\t', 'HeaderLines',4);  
% try restarting textscan after skipping "empty word" 
% y = textscan(fid(pos:end),'%*s %*d    %*s   %s   %*d %*d %*d %*d %*d %*s %*s %*s %*s',...
%                  'Delimiter','\t','HeaderLines',4);  
% input2 = y{:};

%% don't need

% fid = fopen([subjectname,'_vislog.txt'],'w');
% fwrite(fid, nectxt, 'uint8');
% fclose(fid);

