function [trl] = trialfun_auditory_sentence(cfg)

% [trl] = trialfun_visual_sentence(cfg) creates the trl-matrix for the 
% whole sentence
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% the trl-matrix has 6 columns:
%   column 1: begin sample, fix onset trigger
%   column 2: end sample, offset of last word + 600 ms, or next fix onset
%             trigger, whichever occurs first.
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number
%   column 5: condition (i.e. trigger corresponding to target word
%   column 6: sample number of critical word onset, relative to time point 0
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
  
  % get TARGET WORD onset (offset not possible because not marked by triggers)
  condition = [];
  critsmp   = [];
  for kk = 1:numel(tmpval)-1  % need -1 otherwise it counts the following fixation-cross' trigger
    trg1 = tmpval(kk);
    % trg2 = tmpval(kk+1);  % <- doesn't apply no single word offset present
    if trg1<=8 && mod(trg1,2)==0  %  && trg2==15 
      condition = trg1;
      critsmp   = tmpsmp(kk);
      break;
    end
  end
  if isempty(condition)
    warning('the condition of sentence %d could not be determined due to an issue with the trigger sequences: skipping trial\n', k);
    continue;
  end
  
  % get FIRST WORD onset 
  for kk = 1:numel(tmpval)
    trg1 = tmpval(kk);
    % trg2 = tmpval(kk+1);  no offset
    if trg1 == 1 || trg1 == 3 || trg1 == 5 || trg1 == 7  % && trg2==15
      offset = min(1200,tmpsmp(kk)-fixsmp);
      break;    
    end    
  end
  
  % get AUDIOFILE OFFSET
  for kk = numel(tmpval):-1:1
    trg1 = tmpval(kk);
    if trg1==15 
      lastwordindx = kk-1;
      endsmp = tmpsmp(kk);
      break;
    end
  end
  
  
  %%
  tmp = [fixsmp endsmp -offset k condition critsmp-offset-fixsmp];
  trl = cat(1,trl,tmp);

end
