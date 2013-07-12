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
%   column 1: begin sample of word: speech word onset trigger - 500ms.
%    Offset allows for pre-sent/seq baseline
%   column 2: end sample of word + 800 ms, or next word onset
%             trigger, whichever occurs first.
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number (X out of 240; 120 sentences, 120 sequences)
%   column 5: trigger corresponding to the word
%   column 6: sample number of trial relative to the onset of the first word
%   column 7: number of samples between word on and offset
%   column 8: wordcount 
%
%   2012 | NL

prestim  = ft_getopt(cfg.trialdef, 'prestim', 0.5);
poststim = ft_getopt(cfg.trialdef, 'poststim', 0.8-1./1200); 

% read in event information
hdr   = ft_read_header(cfg.dataset);   % if running code locally, change to "cfg.dataset{1}"
event = ft_read_event(cfg.dataset);

% select the UPPT001 events
type = {event.type};
fp   = strcmp('UPPT001', type);

% create a vector with the event values and their respective sample numbers
val  = [event(fp).value];
smp  = [event(fp).sample];

val = [val 20]; % add a 20 to the val to avoid problems with the last sentence (able to identify boundaries for last sentence)
smp = [smp smp(end)];

% parse it into the constituent trials.  indices in val vector representing start of a sentence/sequence
selfix = find(val==20);   

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);  %  
end                            

trl    = zeros(0,8);
for k = 1:numel(selfix)-1      % (1)for EACH CONSTITUENT TRIAL: sentence/sequence; % -1 because last trigger is a dummy
  
  sel = selfix(k):selfix(k+1); % (2) start and end of a trial defined by two consecutive 20 triggers.
                            
  tmpval = val(sel);
  tmpsmp = smp(sel);           
  
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

      %         1         2         3       4 5          6                   7                       8
      tmp    = [begsample endsample -offset k tmpval(kk) begsample-firstword tmpsmp(kk+1)-tmpsmp(kk) wordcount];
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
