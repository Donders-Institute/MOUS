function [trl] = trialfun_visual_sentence(cfg)

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
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

prestim  = ft_getopt(cfg.trialdef, 'prestim',  'fixonset');

% select the UPPT001 events 
type = {event.type};
fp   = strcmp('UPPT001', type);

% create a vector with the event values and sample numbers
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

% parse it into the constituent trials
selfix = find(val==20);

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);
end

trl    = zeros(0,6);
for k = 1:numel(selfix)-1
  % keep track of the '20' trigger
  fixsmp = smp(selfix(k));
  
  sel = selfix(k):selfix(k+1);
    
  % create a sequence of triggers within the trial
  tmpval = val(sel);
  tmpsmp = smp(sel);
  
  % get the target word on/off sequence
  % The following assumes there is always a even-numbered (<=8) trigger directly
  % followed by a '15'. This is not the case e.g. in one of the sentences
  % of subject V1047 (sentence 43). 
  condition = [];
  critsmp   = [];
  for kk = 1:numel(tmpval)-1
    trg1 = tmpval(kk);
    trg2 = tmpval(kk+1);
    if trg1<=8 && mod(trg1,2)==0 && trg2==15
      condition = trg1;
      critsmp   = tmpsmp(kk);
      break;
    end
  end
  if isempty(condition)
    warning('the condition of sentence %d could not be determined due to an issue with the trigger sequences: skipping trial\n', k);
    continue;
  end
  
  % get the first word on/off sequence
  for kk = 1:numel(tmpval)
    trg1 = tmpval(kk);
    trg2 = tmpval(kk+1);
    if trg1<=8 && trg2==15
      firstwordonset = tmpsmp(kk);
      break;    
    end    
  end
  
  if ischar(prestim) && strcmp(prestim, 'fixonset')
    begsmp = fixsmp;
    offset = firstwordonset - fixsmp;
  else
    begsmp = firstwordonset - round(hdr.Fs.*prestim);
    offset = -round(hdr.Fs.*prestim);
  end
  
  % get the last word on/off sequence
  for kk = numel(tmpval):-1:1
    trg1 = tmpval(kk);
    trg2 = tmpval(kk-1);
    if trg1==15 && trg2<=8
      lastwordindx = kk-1;
      break;
    end
  end

  % get the penultimate word on/off sequence -> the last on/off pair does not correspond to
  % a word presented (just an empty space)
  for kk = lastwordindx:-1:1
    trg1 = tmpval(kk);
    trg2 = tmpval(kk-1);
    if trg1==15 && (trg2 ==1 || trg2 ==2 || trg2 ==5 || trg2 ==6)
      endsmp = min([tmpsmp(end), tmpsmp(kk+1), begsmp+20.*1200]);
      break;
    elseif trg1==15 && (trg2 ==8 || trg2 ==7 || trg2 ==3 || trg2 ==4)
      %endsmp = tmpsmp(end);
      endsmp = min(tmpsmp(end), begsmp+20.*1200); % maximize the length to 20 seconds, due to some logical flaw, the block-breaks occasionally add to the last sequence of the block: jms 20170821
      break;
    end
  end
  if begsmp>endsmp, keyboard; end
  
  tmp = [begsmp endsmp -offset k condition critsmp-offset-fixsmp];
  trl = cat(1,trl,tmp);

end

%% get stimuliID (wavfile ID)
%try,
  [p,f,e]             = fileparts(cfg.dataset);
  f                   = strrep(f, 'V1', 'sub-1'); % needed for new naming convention, Oct 2017
  subjectname         = f(1:8);
  [newtext, sentence, wordduration, start] = read_logfile_visual(subjectname);
%end

%try
  load mous_stimuli;
  %load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli');
%catch
%  try
%   warning('could not deal with the mous_simuli file, probably because you don''t have it: ask Jan-Mathijs');;
%  catch 
%  end
%end

if exist('stimuli', 'var') && exist('sentence', 'var')
  id = mous_getstimulusid(sentence, stimuli);
else
  id = nan+zeros(size(trl,1),1);
end

if max(trl(:,4))==numel(id)
  % there is assumed to be a one-to-one match with the stimulus counter and
  % the number of elements in the stimulus material extracted from the
  % logfile
  trl(:,7) = id(trl(:,4));
else
  % there is some logic in trialfun_visual_word that matches the stuff from
  % the logfile to the trl matrix -> take advantage of this
  fprintf('there is some issue with matching the logfile to the trl-matrix, computing the trl-matrix for the single words as well\n');
  tmptrl = trialfun_visual_word(cfg);
  [u, i1, i2] = unique(tmptrl(:,4));
  trl(:,7) = tmptrl(i1(1:size(trl,1)),9);
end
