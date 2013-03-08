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
    expwords{cnt,1} = cat(2,expwords{cnt,1},word);
end 


%% match trials (240) to excel file (800)
% 1. read in excel file with range: A1 - Q1599
[cat,text,catdata] = xlsread('home/language/nielam/MOUS_AnalysisNotes/Mous_codedCategorieswords.xls','','A1:Q1599','basic'); 

% put categorisation into a separate matrix, removing NaNs
% each row is one sentence/sequence
catnum = cat(2:2:end,:);
catnum = catnum(:,2:end);

% turn trials into concatenated words
catdata = catdata(1:2:end,:);      % remove every other line holding category numbers
catwords = cell(size(catdata,1)/2, 1);
for qq = 1:size(catdata,1)
    catwords{qq} = strcat(2,catdata{qq,2:end}); %%FIXME:there's a funny square box before the sent
end 

% 2. match sentences/sequences
% note that the sequences are missing the last word (but not the sentences)
% N.B. check if matlab will flipout for ptp's with <240 trials

idx4expword = [];
%idx4expword = zeros(240,1)
for qq = 1:size(expwords,1)
    % catwords is first arguement cuz it is a cellstr (the one to check thru)
    itmp     = strfind(catwords,expwords{qq});
    idxsent  = find(not(cellfun('isempty',itmp)));
    idx4expword = [idx4expword; idxsent];  % this only gives idx for 232/240 sentences.
    %idx4expword(qq,1) = idxsent;          % this one stops after expword{17}, why?
end

%% load trialfun_visual_word and add to it's trialinfo
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');
prestim     = 0.5; 
poststim = 3.0;
wordType    = 'all';
trialfun    = 'visual_word';
[trl] = mous_defineTrial(filename{1}, prestim, poststim, wordType, trialfun); 

% trialfun is missing the LAST word for sequences, make sure I code for
% that!

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

