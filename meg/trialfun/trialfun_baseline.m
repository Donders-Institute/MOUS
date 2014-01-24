function [trl] = trialfun_baseline(cfg)

% [trl] = trialfun_visual_sentence(cfg) creates the trl-matrix for the
% pre-sentence/pre-sequence (depending on condition) baseline window. 
% For details of individual words in each sentence/sequence see
% trialfun_auditory_word.m or trialfun_visual_word.m
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% timepoint zero is the speech onset of the first word!
% 
% the trl-matrix has 6 columns:
%   column 1: begin sample of baseline: first word speech onset - 1000ms
%   column 2: end sample, onset of first word
%   column 3: offset of first sample with respect to time point 0 
%   column 4: trial number
%   column 5: first word trigger
%   column 6: target word trigger
%
% $Id: trialfun_visual_sentence.m 39 2012-05-08 11:12:46Z jansch $

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

trl    = zeros(0,6);
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
    if trg1 == 1 || trg1 == 3 || trg1 == 5 || trg1 == 7  % && trg2==15
      offset = 1200;
      begsmp = tmpsmp(kk) - offset;  % first word speech onset == time point 0  
      endsmp = tmpsmp(kk);
      fstwrd = trg1;
      break;    
    end    
  end
  
  % get TARGET WORD onset (offset not possible because not marked by triggers)
  for kk = 1:numel(tmpval)-1  % need -1 otherwise it counts the following fixation-cross' trigger
    trg1 = tmpval(kk);
    if trg1<=8 && mod(trg1,2)==0 
      target = trg1;
      break;
    end
  end
  if isempty(target)
    warning('the condition of sentence %d could not be determined due to an issue with the trigger sequences: skipping trial\n', k);
    continue;
  end
  
  tmp = [begsmp endsmp -offset k fstwrd target];
  trl = cat(1,trl,tmp);

end
