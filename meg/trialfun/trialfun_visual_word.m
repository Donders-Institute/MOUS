function [trl] = trialfun_visual_word(cfg)
% [trl] = trialfun_visual_word(cfg) creates the trl-matrix for the 
% single words
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
%%  Terms
% 1) time point 0: onset of trigger (in val variable, line 35)
%                  in this case, it represents onset of each word (but more
%                  generally refers to onset of a trial)
%              
% 2) prestim: duration before time point 0, also referred to as 'offset'
%             (not to be confused with "word offset")
%
%             in this case it is also the baseline (but this is not definitive)
% 3) poststim: duration from time point 0 until (a) next trial begins or 
%              (b) end of poststim value (as defined in cfg.poststim)
% 
%%  The trl-matrix has 8 columns:
%   column 1: begin sample: word onset trigger - 500 ms.
%   column 2: end sample, onset of word + 800 ms, or next word onset
%             trigger, whichever occurs first.
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number (X out of 240; 120 sentences, 120 sequences)
%   column 5: trigger corresponding to the word
%   column 6: sample number relative to the onset of the first word
%   column 7: number of samples between word on and offset
%   column 8: ordinal number of word position

prestim  = ft_getopt(cfg.trialdef, 'prestim', 0.3);
poststim = ft_getopt(cfg.trialdef, 'poststim', 0.8-1./1200); 

% read in event information
% if running code locally, change the arguments to "cfg.dataset{1}", if run
% as a function arguments should be "cfg.dataset"
hdr   = ft_read_header(cfg.dataset);   
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
for k = 1:numel(selfix)-1      % (1)for EACH CONSTITUENT TRIAL: sentence/sequence; duration of k = duration of a sent/seql; # of k's = # of words in the current trial
                               % -1 because last trigger is a dummy
  
  sel = selfix(k):selfix(k+1); % (2) create a sequence of triggers marking words within a trial. Trial boundary: one 20 (fixationcross) to another 20.
                            
  tmpval = val(sel);
  tmpsmp = smp(sel);           % last sample of tmpsmp is sample of the last word (which is an empty word) in the trial
  
  % get the first word on/off sequence
  firstword = [];
  tmptrl    = zeros(0,8);
  for kk = 1:numel(tmpval)-2   % (3) gets triggers representing on/off of each word in the trial except last 2 triggers which are an 'empty word'
    
    trg1 = tmpval(kk);         % loop through the triggers
    trg2 = tmpval(kk+1);
    if trg1<=8 && trg2==15
      if isempty(firstword)    % firstword defined by sample of first trigger
        firstword = tmpsmp(kk);
        wordcount = 0;
      end
      offset    = round(hdr.Fs*prestim);
      begsample = tmpsmp(kk) - offset;                   % onset of word: sample value of Xth word within the current trial 
      if ischar(poststim) && strcmp(poststim, 'nextword')
        endsample = tmpsmp(kk+2); % epoch lasts until next word onset
      else
        endsample = min(tmpsmp(kk) + round(hdr.Fs*poststim), inf);%smplast);   % offset of word: sample value of Xth word within the current trial + poststim (3s);  
      end

      wordcount = wordcount + 1;

      %         1         2         3       4 5          6                   7
      tmp    = [begsample endsample -offset k tmpval(kk) begsample-firstword tmpsmp(kk+1)-tmpsmp(kk) wordcount];
      tmptrl = cat(1,tmptrl,tmp);
    end
  end
  
  % for each sentence/sequence truncate the epochs' length of words 
  % so that they do not go beyond the end of a
  % sentence/sequence, taking into account that the last word on/off
  % trigger pair did not actually contain a visually presented word.
  % i.e. the end of the last actual word is here marked by the onset of the
  % last word.
  smplast     = tmptrl(end,1)+offset;
  tmptrl(:,2) = min(tmptrl(:,2), smplast);
  tmptrl      = tmptrl(1:end-1,:);
  
  trl = cat(1, trl, tmptrl);
end
