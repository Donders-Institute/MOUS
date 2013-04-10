function [trl] = trialfun_auditory_sentence(cfg)

% [trl] = trialfun_visual_sentence(cfg) creates the trl-matrix for the 
% whole sentence: notes onset of trial and target word. For speech onset of
% first word (and other words) see trialfun_auditory_word
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% timepoint zero is the speech onset of the first word!
% 
% the trl-matrix has 6 columns:
%   column 1: begin sample: speech onset of first word - offset of 1s
%             this is the auditory version of the begsmp in the visual
%             version
%             Offset allows for pre-sent/seq baseline
%   column 2: end sample, offset of audiofile 
%             Can change to: (1) offset of last speech word, (2) onset of
%             fixation cross
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number
%   column 5: trigger corresponding to target word
%   column 6: sample number of critical word onset, relative to time point 0
%
% $Id: trialfun_auditory_sentence.m  | NL 2013

% read in event information
hdr   = ft_read_header(cfg.dataset);  % ***remove {1} when done testing within function ***
event = ft_read_event(cfg.dataset);

% select the UPPT001 events
type = {event.type};
fp   = strcmp('UPPT001', type);

% create a vector with the event values and sample numbers
val  = [event(fp).value];
smp  = [event(fp).sample];

% parse it into the constituent trials; 20 == fixation cross
selfix = find(val==20);

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);
end

trl    = zeros(0,7);
for k = 1:numel(selfix)-1
  
  % FIXATION CROSS - keep track of the '20' trigger
  fixsmp = smp(selfix(k));
    
  sel = selfix(k):selfix(k+1);
    
  % create a sequence of triggers within the trial
  tmpval = val(sel);
  tmpsmp = smp(sel);
  
  % get FIRST WORD onset  
  for kk = 1:numel(tmpval)
    trg1 = tmpval(kk);
    if trg1 == 1 || trg1 == 3 || trg1 == 5 || trg1 == 7  % Don't need to a second cdtn to check because first word's trigger don't overlap with target's trigger
      offset = 1200;
      begsmp = tmpsmp(kk) - offset;  % first word speech onset == time point 0  
      %endsmp = tmpsmp(kk);
      fstwrd = trg1;
      break;    
    end    
  end
  
  % get TARGET WORD onset (offset not possible because not marked by triggers)
%   condition = [];
%   critsmp   = [];
  for kk = 1:numel(tmpval)-1  % need -1 otherwise it counts the following fixation-cross' trigger
    trg1 = tmpval(kk);
    if trg1<=8 && mod(trg1,2)==0 
      condition = trg1;
      critsmp   = tmpsmp(kk);
      break;
    end
  end
  if isempty(condition)
    warning('the condition of sentence %d could not be determined due to an issue with the trigger sequences: skipping trial\n', k);
    continue;
  end
  
%   % get AUDIOFILE OFFSET
  for kk = numel(tmpval):-1:1
    trg1 = tmpval(kk);
    if trg1==15 
      %lastwordindx = kk-1;
      endsmp = tmpsmp(kk);
      break;
    end
  end
  
  
  %%
  %tmp = [fixsmp endsmp -offset k condition critsmp-offset-fixsmp]; % visual stimuli
  %begsmp = first onset - 1s.
  tmp = [begsmp endsmp -offset k fstwrd condition critsmp-offset];
  trl = cat(1,trl,tmp);

end
