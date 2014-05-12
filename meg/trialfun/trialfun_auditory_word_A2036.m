function [trl] = trialfun_auditory_word_A2036(cfg)

% [trl] = trialfun_visual_word(cfg) creates the trl-matrix for the single words
% each row represents the information for the first word or the target word
% of each sentence/sequence
% 
% for a trl where each row represents an entire sentence/sequence, see
% trialfun_auditory_sentence
%
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% the trl-matrix has 6 columns:
%   column 1: begin sample of word: speech word onset trigger - 500 ms).
%             Offset allows for pre-sent/seq baseline
%   column 2: end sample = beg sample + 800 ms, or next word onset
%             trigger, whichever occurs first. (or change it on line 68)
%   column 3: Number of samples between begsample and trigger of intrest. Given as offset
%             and therefore a negative value. 
%   column 4: trial number (X out of 240)
%   column 5: trigger corresponding to the word
%   column 6: Number of samples between the trigger and the  onset of the first word
%   column 7: number of samples between word on and offset
%   column 8: wordcount based on logfile (presentation triggers don't hold word position info
%   2012 | NL
 
prestim  = ft_getopt(cfg.trialdef, 'prestim', 0.5);
poststim = ft_getopt(cfg.trialdef, 'poststim', 0.8-1./1200); 

% read in event information
hdr   = ft_read_header(cfg.dataset);   % if running code locally, change to "cfg.dataset{1}"
% event = ft_read_event(cfg.dataset);

event = mous_read_event_audio_A2036(cfg.dataset);  % this line is necessary to fix the trigger problems we have (which applies only after subject A2029, except for A2014).

% select the UPPT001 events
type = {event.type};
fp   = strcmp('UPPT001', type) | ~cellfun('isempty', strfind(type, 'wav'));

% create a vector with the event values and their respective sample numbers
val  = [event(fp).value];
smp  = [event(fp).sample];
type = type(fp);

val = [val 20]; % add a 20 to the val to avoid problems with the last sentence (able to identify boundaries for last sentence)
smp = [smp smp(end)];

% parse it into the constituent trials.  indices in val vector representing start of a sentence/sequence
selfix = find(val==20);   

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);  %  
end                            

% load target location info (word position of target for each sentence/sequence)
idx         = regexp(cfg.dataset,'A2');
subjectname = cfg.dataset(idx:idx+4);
tarloc      = mous_audio_gettarloc(subjectname);

% create trl
trl    = zeros(0,8);
for k = 1:numel(selfix)-1      % (1)for EACH CONSTITUENT TRIAL: sentence/sequence; % -1 because last trigger is a dummy
  
  sel = selfix(k):selfix(k+1); % (2) start and end of a trial defined by two consecutive 20 triggers.
                            
  tmpval = val(sel);
  tmpsmp = smp(sel);
  
  % only go up until a question, which has a trigger value of 40
  if any(tmpval==40)
    sel = 1:(find(tmpval==40,1,'first')-1);
    tmpval = tmpval(sel);
    tmpsmp = tmpsmp(sel);
  end
  
  % get the each word's on-,offset, trigger and sample info
  firstword = [];
  tmptrl    = zeros(0,8);
  for kk = 1:numel(tmpval)-1     % triggers for audio on- and offset, 1st and target word onset
    trg1 = tmpval(kk);         % loop through the triggers
    trg2 = tmpval(kk+1);
    if trg1 <= 8 && trg2 ~=10  % trg2 is specific for p006 (changes prior to 24 Jan 2013) where a [30 3  10] sequence occurs (30 = pause, 3 = spacebar, 10 = block title)
      if isempty(firstword)    % firstword defined by sample of first trigger
        firstword = tmpsmp(kk);
        wordcount = 0;
      end
      offset    = round(hdr.Fs*prestim);
      begsample = tmpsmp(kk) - offset;                
      
      if ischar(poststim) && strcmp(poststim, 'nextword')
        endsample = tmpsmp(kk+1); % epoch lasts until next word onset
      else
        endsample = min(tmpsmp(kk) + round(hdr.Fs*poststim), inf); % offset of word: word's onset sample + poststim (3s);  
      end
      
      wordcount = wordcount + 1;
      
      if isempty(wordcount)
        % something fishy is going on
        wordcount = nan;
      elseif wordcount == 1
        % I don't know what to do here, so don't change it
        wordcount = 1;
      elseif wordcount > 1  % get target position (info from logfile)
        % get soundfile filename of current trial
        wavfileid = str2double(type{selfix(k)+1}(1:3)); 
        if isnan(wavfileid)
          error('unable to find target position for subject %s in trial %d', subjectname,k)
        end   
      
        % if current trial is a sequence, find corresponding sentence (same word pstn)
        if wavfileid > 409
          wavfileid2 = wavfileid - 500;  
          idxwav = find(tarloc(:,1) == wavfileid2); % original wavfileid preserved but not entered into trialinfo
        else % wavfileid < 409
          idxwav = find(tarloc(:,1) == wavfileid);
        end
        wordcount = tarloc(idxwav,2);  
      end    
      
      if isempty(wordcount)
        wordcount = nan;
      end
                 
      %         1         2         3       4 5          6                    7                      8        
      tmp    = [begsample endsample -offset k tmpval(kk) begsample-firstword tmpsmp(kk+1)-tmpsmp(kk) wordcount(1)];
      
      tmptrl = cat(1,tmptrl,tmp);
    end  
  end
   
   trl = cat(1, trl, tmptrl);
end


% do a final quality check on the trl-matrix, to catch an exception
% (currently the only known exception is A2062, but in the future, with
% single word triggers possibly present, there may be more 'exceptions')
% where due to overlapping triggers the correct identity of the first word
% in the sentence is not caught, mistakingly indexing a target word as the
% first word in the sentence. For now these rows will be just removed from
% the trl-matrix, too bad.
sel = find(mod(trl(:,5),2)==0 & trl(:,8)==1);
if numel(sel)>0
  fprintf('inconsistency detected in %d trials, removing them\n',numel(sel));
  trl(sel,:) = [];
end

% here's another too bad situation: for A2036 (and possibly others) there
% may be three words per sentence, this can at the moment not occur
% ##### to be revisited if single words are coded ######
% for now remove those rows, too
t  = trl(:,4);
ut = unique(t);
for k = 1:numel(ut)
  n(k) = sum(t==ut(k));
end
trl(ismember(trl(:,4),ut(n>2)),:) = [];

