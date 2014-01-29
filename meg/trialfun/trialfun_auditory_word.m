function [trl] = trialfun_auditory_word(cfg)

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
%   column 8: wordcount based on triggers
%   column 9: wordcount based on word position across sentence/sequence
%   2012 | NL
% 

%% load target location info (word position of target for each sentence/sequence)
idx = regexp(cfg.dataset,'A2');
subjectname = cfg.dataset(idx:idx+4);
tarloc = mous_audio_gettarloc(subjectname);

%% create trl matrix
prestim  = ft_getopt(cfg.trialdef, 'prestim', 0.5);
poststim = ft_getopt(cfg.trialdef, 'poststim', 0.8-1./1200); 
 
 
% read in event information
hdr   = ft_read_header(cfg.dataset);   % if running code locally, change to "cfg.dataset{1}"
% event = ft_read_event(cfg.dataset);

event = mous_read_event_audio(cfg.dataset);  % this line is necessary to fix the trigger problems we have (which applies only after subject A2029, except for A2014).

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

trl    = zeros(0,9);
for k = 1:numel(selfix)-1      % (1)for EACH CONSTITUENT TRIAL: sentence/sequence; % -1 because last trigger is a dummy
  
  sel = selfix(k):selfix(k+1); % (2) start and end of a trial defined by two consecutive 20 triggers.
                            
  tmpval = val(sel);
  tmpsmp = smp(sel);           
  
  % get the each word's on-,offset, trigger and sample info
  firstword = [];
  tmptrl    = zeros(0,9);
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
      
      wavfileid = str2double(type{selfix(k)+1}(1:3)); % get soundfile filename of current trial
     
      wordcount = wordcount + 1;
      
      % get target position (based on logfile, not triggers)
      if wordcount ~= 1  
      % if trial = sequence, find matching sentence (that shares same
      % target location) because tarloc only holds sentence filenames
        if wavfileid > 409
            wavfileid2 = wavfileid - 500;  % create second wavfileid2 so as not to overwrite the real one
        end 
          idxwav = find(tarloc(:,1) == wavfileid2);
          wordcount = tarloc(idxwav,2);          
      end 
      
      %         1         2         3       4 5          6                    7                      8         9
      tmp    = [begsample endsample -offset k tmpval(kk) begsample-firstword tmpsmp(kk+1)-tmpsmp(kk) wordcount wavfileid];
      
      tmptrl = cat(1,tmptrl,tmp);
    end  
  end

  
%   % for each sentence/sequence truncate the epochs' length of words 
%   % so that they do not go beyond the end of a
%   % sentence/sequence, taking into account that the last word on/off
%   % trigger pair did not actually contain a visually presented word.
%   % i.e. the end of the last actual word is here marked by the onset of the
%   % last word.
%   smplast     = tmptrl(end,1)+offset;
%   tmptrl(:,2) = min(tmptrl(:,2), smplast);
%   tmptrl      = tmptrl(1:end-1,:);
%   
   trl = cat(1, trl, tmptrl);
end

%% exception cases in trl (due to trigger issues)
% FIX ME
% if strcmp(subjectname,'A2013')
%     trl(459,:) = [];
% end
% 
% % account for not having data for the first 20 trials for A2002
% if strcmp(subjectname,'A2002')
%     diff = 240-(size(selfix,2)-1);
%     tarloc = tarloc(diff+1:end,:);
%     firstloc = ones(numel(selfix)-1,1);
% end


