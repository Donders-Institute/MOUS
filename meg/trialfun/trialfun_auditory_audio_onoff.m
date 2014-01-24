function [trl, event] = trialfun_auditory_audio_onoff(cfg)

% [trl] = trialfun_auditory_audio_onoff(cfg) creates the trl-matrix based on
% the onset and offset of the audio files
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% timepoint zero is the speech onset of the first word!
% 
% the trl-matrix has 6 columns:
%   column 1: begin sample: onset of audiofile
%   column 2: end sample, offset of audiofile + 50 ms
%   column 3: offset of first sample with respect to time point 0
%
% $Id: trialfun_auditory_sentence.m 

% read in event information
event = mous_read_event_audio(cfg.subjectname);

% select the UPPT001 events
type = {event.type};
fp   = strncmp('UPPT001', type, 7);

% create a vector with the event values and sample numbers
val  = [event(fp).value];
smp  = [event(fp).sample];

% parse it into the constituent trials; 14 == audio onset
selfix = find(val==20);

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);
end

trl    = zeros(0,3);
for k = 1:numel(selfix)-1
  
  sel = selfix(k):selfix(k+1);
    
  % create a sequence of triggers within the trial
  tmpval = val(sel);
  tmpsmp = smp(sel);
  
  % get FIRST WORD onset  
  for kk = 1:numel(tmpval)
    trg1 = tmpval(kk);
    if kk==1
      begsmp = nan;
      endsmp = nan;
    end
    if trg1 == 14
      begsmp = tmpsmp(kk);
    end
    if trg1 == 15 && tmpsmp(kk)-begsmp>2400 % audio offset should be at least 2 seconds after onset
      % that is to deal with an occasionally wrongly detected trigger when
      % trying to reconstruct level-mode triggering.
      endsmp = tmpsmp(kk);
      break;    
    end    
  end
  offset = 0;
  
  tmp = [begsmp endsmp offset];
  trl = cat(1,trl,tmp);
end

trl(~isfinite(trl(:,1)),:) = [];
trl(~isfinite(trl(:,2)),:) = [];

