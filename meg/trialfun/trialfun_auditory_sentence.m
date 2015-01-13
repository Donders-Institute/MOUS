function [trl,val] = trialfun_auditory_sentence(cfg)

% [trl] = trialfun_visual_sentence(cfg) creates the trl-matrix for the 
% whole sentence: notes onset of trial and target word. For speech onset of
% first word (and other words) see trialfun_auditory_word
% time point zero = start of trial (sent/seq) i.e. speech onset of first
% word
% 
% the cfg needs to contain the following option:
%   cfg.dataset = string, name of the dataset
%
% timepoint zero is the speech onset of the first word!
% 
% the trl-matrix has 8 columns:
%   column 1: begin sample: speech onset of first word - offset of 1s
%             this is the auditory version of the begsmp in the visual
%             version
%             Offset allows for pre-sent/seq baseline
%   column 2: end sample, offset of audiofile 
%             Can change to: (1) offset of last speech word, (2) onset of
%             fixation cross
%   column 3: offset of first sample with respect to time point 0
%   column 4: trial number
%   column 5: trigger corresponding to first word
%   column 6: trigger corresponding to target word
%   column 7: sample number of critical word onset, relative to time point 0
%   column 8: name of .wav file
% 
% $Id: trialfun_auditory_sentence.m  | NL 2013

cfg.trialdef         = ft_getopt(cfg, 'trialdef');
cfg.trialdef.prestim = ft_getopt(cfg.trialdef, 'prestim', 1);
adjustdelay          = istrue(ft_getopt(cfg.trialdef, 'adjustdelay', 'yes'));

% read in event information
if isempty(strfind(cfg.dataset, 'A2036'))
  event = mous_read_event_audio(cfg.dataset);
else
  event = mous_read_event_audio_A2036(cfg.dataset);
end

% select the UPPT001 events
type = {event.type};
%fp   = strcmp('UPPT001', type);
fp   = strcmp('UPPT001', type) | ~cellfun('isempty', strfind(type, 'wav'));
wavid = type(~cellfun('isempty',strfind(type,'wav')));
 
% create a vector with the event values and sample numbers
val  = [event(fp).value];
smp  = [event(fp).sample];

% parse it into the constituent trials; 20 == fixation cross
selfix = find(val==20);

% add a dummy to the end for the for-loop to work
if selfix(end)<numel(val)
  selfix(end+1) = numel(val);
end

trl    = zeros(0,8);
for k = 1:numel(selfix)-1
  
  sel = selfix(k):selfix(k+1);
    
  % create a sequence of triggers within the trial
  tmpval = val(sel);
  tmpsmp = smp(sel);  
  
  % check whether it should start at audio onset
  if ischar(cfg.trialdef.prestim) && strcmp(cfg.trialdef.prestim, 'audioonset')
    doaudioonset = true;
  else
    doaudioonset = false;
  end
  
  % get FIRST WORD onset, there are a few occasions where this is missed,
  % in which case it could be that there's a sequence of triggers which are
  % -both even valued
  % -where the first of the pair should be one higher
  
  for kk = 1:numel(tmpval)
    trg1 = tmpval(kk);
    if kk<numel(tmpval)
      trg2 = tmpval(kk+1);
    else 
      trg2 = nan;
    end
    
    begsmp = nan;
    if trg1 == 14
      onset = tmpsmp(kk);
    end
  
    if isfinite(trg2) && mod(trg1,2)==0 && mod(trg2,2)==0 && trg1<=8 && trg2<=8 && trg2-trg1==2
      % NOTE: this is extremely fishy, added on 20141111: keep eyes open
      % for side effects
      trg1 = trg1+1;
    end
    
    if trg1 == 1 || trg1 == 3 || trg1 == 5 || trg1 == 7  % Don't need to a second cdtn to check because first word's trigger don't overlap with target's trigger
      if doaudioonset,
        % depends on the audio file
        offset = tmpsmp(kk) - onset;
      else
        % depends on the user
        offset = round(1200*cfg.trialdef.prestim); %HARDCODED @ 1200HZ
      end
      begsmp = tmpsmp(kk) - offset;  % first word speech onset == time point 0  
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
  endsmp = nan;
  for kk = numel(tmpval):-1:1
    trg1 = tmpval(kk);
    if trg1==15 
      %lastwordindx = kk-1;
      endsmp = tmpsmp(kk);
      break;
    end
  end
  
  % get wav file ID
  currwav = str2double(wavid{k}(1:3));
%   unlike trialfun_auditory_word, there is no need to find sentence
%   equivalent of sequences because we do not need to locate the target
%   word.
%   if currwav > 409  
%     currwav = currwav - 500;
%   end 
%   
  
  
  %%
  %tmp = [fixsmp endsmp -offset k condition critsmp-offset-fixsmp]; % visual stimuli
  %begsmp = first onset - 1s.
  if isfinite(begsmp) && isfinite(endsmp)
    tmp = [begsmp endsmp -offset k fstwrd condition critsmp-offset-begsmp currwav];
    trl = cat(1,trl,tmp);
  end

end

% do NOT add wavid after trl matrix has been formed because numel(wavid)
% and size(trl,1) do not always match up.  This inequality is because when
% the DSQ error occurs - there is no data (i.e. no row in trl) but the
% triggers in event.type still collect the trigger (with the wavid
% attached).
% if size(trl,1)==numel(wavid)
%   for k = 1:size(trl,1)
%     trl(k, 8) = str2double(wavid{k}(1:3));
%   end
% end

% the following has been added on 20150106
if adjustdelay,
  % adjust the timing for the delay between the trigger and the actual
  % presentation of the sound, added (as default) on 20141111
  fprintf('adjusting the timing for the audio delay\n');
  [p,f,e] = fileparts(cfg.dataset);
  f       = mous_db_getfilename(f(1:5), 'meg_qualitycheck_audiodelay');
  tmp     = load(f{1});
  for k = 1:size(trl,1)
    indx = find(tmp.stimid==trl(k,8));
    if ~isempty(indx)
      D    = round(tmp.delay(indx(1)).*0.001.*1200); % in samples
      trl(k,1:2) = trl(k,1:2)+D;
    else
      % apparently something went wrong with the decoding of the triggers
    end
  end
end

