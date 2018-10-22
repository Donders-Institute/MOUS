function [trl] = trialfun_visual_word(cfg)

% TRIALFUN_VISUAL_WORD creates the trl-matrix for the single words for the
% visual subjects.
% 
% Use as
%
% [trl] = trialfun_visual_word(cfg)
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
%%  Terms
% 1) time point 0: onset of trigger (in val variable, line 35)
%                  in this case, it represents onset of each word (but more
%                  generally refers to onset of a trial)
%              
% 2) prestim: duration before time point 0, (default = 0.3)
%
%             in this case it is also the baseline (but this is not definitive)
% 3) poststim: duration from time point 0. (default = 0.8), can be
%             'nextword'
%
%%  The trl-matrix has 8 columns:
%   column 1: begin sample: word onset trigger - prestim s.
%   column 2: end sample, onset of word + poststim s
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number (X out of 240; 120 sentences, 120 sequences)
%   column 5: trigger corresponding to the word
%   column 6: sample number relative to the onset of the first word
%   column 7: number of samples between word onset trigger (e.g.,1) and word offset trigger (15)
%   column 8: ordinal number of word position
%   column 9: stimulus id, linking the sentence/sequence to the total
%             stimulus set

cfg.trialdef = ft_getopt(cfg, 'trialdef');
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

% delete button-press related triggers from val [fix: 28.11.2016 sopara]
fp2   = strcmp('UPPT002', type);
smp2  = [event(fp2).sample];
val2  = [event(fp2).value];

tmpidx = zeros(1,length(smp2));
for i = 1:length(smp2)
    tmp = find(smp >= smp2(i),1,'first');
    if ~isempty(tmp) && ((val2(i) == 32 && val(tmp) == 2) || (val2(i) == 16 && val(tmp) == 1) || (val2(i) == 48 && val(tmp) == 3))
        tmpidx(i) = tmp;
    end
end
tmpidx(tmpidx == 0) = [];

val(tmpidx) = [];
smp(tmpidx) = [];

val = [val 20]; % add a 20 to the val to avoid problems with the last sentence (able to identify boundaries for last sentence)
smp = [smp smp(end)];

% parse it into the constituent trials.  indices in val vector representing start of a sentence/sequence
selfix = find(val==20);   

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);  %  
end                            

trl    = zeros(0,8);trl    = zeros(0,8);
for k = 1:numel(selfix)-1      % (1)for EACH CONSTITUENT TRIAL: sentence/sequence; duration of k = duration of a sent/seql; # of k's = # of words in the current trial
                               % -1 because last trigger is a dummy
  sel = selfix(k):selfix(k+1); % (2) create a sequence of triggers marking words within a trial. Trial boundary: one 20 (fixationcross) to another 20.
                            
  tmpval = val(sel);
  tmpsmp = smp(sel);           % last sample of tmpsmp is sample of the last word (which is an empty word) in the trial
  
  
  % get the first word on/off sequence
  firstword = [];
  tmptrl    = zeros(0,8);
  for kk = 1:numel(tmpval)-1%-2   % (3) gets triggers representing on/off of each word in the trial except last 2 triggers which are an 'empty word'
    
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
          if endsample-begsample>2400
            endsample = tmpsmp(kk+1)+round(hdr.Fs.*0.3);
          end
      else
          endsample = min(tmpsmp(kk) + round(hdr.Fs*poststim), inf);%smplast);   % offset of word: sample value of Xth word within the current trial + poststim (3s);
      end
      
      wordcount = wordcount + 1;
      
      %         1         2         3       4 5          6                   7
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

  if ismember(tmptrl(1,5), [1 2 5 6])
    % for the sentences the last 'word' did not contain a word
    tmptrl      = tmptrl(1:end-1,:);
  end
  
  trl = cat(1, trl, tmptrl);
end

try,
  [p,f,e]             = fileparts(cfg.dataset);
  f                   = strrep(f, 'V1', 'sub-1'); % needed for new naming convention, Oct 2017
  subjectname         = f(1:8);
  [newtext, sentence, wordduration] = read_logfile_visual(subjectname);
end


try
  load mous_stimuli;
%  load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli');
catch
  try
   warning('could not deal with the mous_simuli file, probably because you don''t have it: ask Jan-Mathijs');;
  catch 
  end
end

if exist('stimuli', 'var') && exist('sentence', 'var')
  id = mous_getstimulusid(sentence, stimuli);
else
  id = nan+zeros(size(trl,1),1);
end

if max(trl(:,4))==numel(id)
  % there is assumed to be a one-to-one match with the stimulus counter and
  % the number of elements in the stimulus material extracted from the
  % logfile
  trl(:,9) = id(trl(:,4));
else
  % we have to somehow match it
  if exist('wordduration', 'var')
    % number of words estimated from log file
    nw1 = cellfun(@numel,wordduration);
    
    % column 8 contains the number of words, number of words estimated from
    % trl matrix
    tmp = trl(:,8);
    nw2 = tmp(find(diff(tmp)<0));
    
    [c,lags] = xcorr(nw1-mean(nw1),nw2-mean(nw2));
    [m,idx]  = max(c);
  else
    lags = 0;
    idx  = 1;
  end
  trl(:,9) = id(trl(:,4)+lags(idx));
end

