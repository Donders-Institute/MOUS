function [event] = mous_read_event_audio(dataset, bits)

% this function tries to deal with triggers recorded in level-mode. The
% bitsi box can be configured to do so. This function behaves as
% ft_read_event, but tries to fix the levelmode issue. It works reasonably
% well, in that the downstream code manages to reconstruct a large part of
% the trials correctly.

if nargin==1
  bits = [];
end

if numel(dataset)<6
  % assume it's the name of a subject
  subjname = dataset;
  dataset = mous_db_getfilename(dataset, 'meg_raw_task');
  dataset = dataset{1};
else
  tmp = strfind(dataset, 'V');
  tmp2 = strfind(dataset, 'A');
  if ~isempty(tmp)
    subjname = dataset(tmp(1)+(0:4));
  else
    subjname = dataset(tmp2(1)+(0:4));
  end
end

% get logfilename, if scenario was 1-MEG or 3-MEG, then 093.wav exists. 
% This wave file has an overlap between trigger-14 (audiofile onset) 
% and trigger-1 (first word onset). This is fixed at line 122.
logfname = mous_db_getfilename(subjname,'meg_raw_log');
eventlog = read_logfile_audio(subjname);
if numel(eventlog) == 1;
  eventlog = eventlog{1};
elseif numel(eventlog) == 2 && isequal(eventlog{1}, eventlog{2})
  % this is OK, take either one of them
  eventlog = eventlog{1};
elseif numel(eventlog) == 2 && ~isequal(eventlog{1}, eventlog{2})
  % this is probably weird, but concatenate the two
  eventlog = [eventlog{1} eventlog{2}];
elseif numel(eventlog) > 2
  error('eventlog has >1 element because subject has >1 logfile and this problem has not been fixed yet');
end
[p,f,e]  = fileparts(logfname{1});
scenario = str2double(f(7));

% ideally we should use ft_read_data here
cfg            = [];
cfg.dataset    = dataset;
cfg.continuous = 'yes';
cfg.channel    = 'UPPT001';
data           = ft_preprocessing(cfg);
trigger        = data.trial{1}(1,:);

bitvalue = [1 2 4 8 16 32]; % only the first 6 bits are used, so need to be checked
for k = 1:numel(bitvalue)
  n(k) = sum(bitand(trigger,bitvalue(k))>0);
end

% try to guess which bits have been recorded in level-mode
if any(n>60000)
  % do a double round of zscoring, should detect the bad ones
  tmpn  = (n-mean(n))./std(n);
  sel   = find(tmpn<0);
  tmpn2 = (n(sel)-mean(n(sel)))./std(n(sel));
  sel2  = find(tmpn2<0);
  if numel(sel)<numel(n) && numel(sel2)<numel(sel)
    bits = 2.^(setdiff(1:6,sel(sel2))-1);
  elseif numel(sel)<numel(n)
    bits = 2.^(setdiff(1:6,sel)-1);
  else
    bits = [];
  end
  
  str = '';
  for k = 1:numel(bits)
    str = [str ' ' num2str(bits(k))];
  end
  if ~isempty(str)
    fprintf('assuming levelmode for bits %s\n', str);
  end
end

% if we know which bits were in level mode we could do something clever
% with these bits. this leaves us to guess the average length of the pulses

dtrigger             = diff(find(diff(trigger)));
dtrigger(dtrigger<3) = []; % triggers less than 5 samples wide probably don't mean anything
pulselength          = mode(dtrigger);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the levelmode issue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newtrigger = trigger;
if ~isempty(bits)
  %pulselength = min(pulselength, 15); % make new pulses at most 10 samples wide.
  
  for k = 1:numel(bits)
    tmp  = bitand(trigger, bits(k));
    
    % all upflanks occurring within the upstate of a bit, are trigger codes
    % that contain this bit, so for the following part of the code to work,
    % it should be detectable as a 'new' upstate.
    allup   = diff([trigger(1) trigger])>0;
    upup  = tmp>0 & allup;
    %tmp([upup(2:end) false]) = 0;
    tmp(upup) = 0;
    
    alldown = diff([trigger 0])<0;
    seldown = find(alldown);
    
    down = find(diff([tmp 0])      <0);
    up   = find(diff([bits(k) tmp])>0);
    if numel(up)<numel(down) && up(1)>down(1)
      up = [1-pulselength up];
    elseif numel(up)<numel(down)
      error('don''t know what to do here');
    end
      
    for m = 1:numel(down)
      newtrigger((up(m)+pulselength):(down(m)+1)) = newtrigger((up(m)+pulselength):(down(m)+1))-bits(k); %+(1:pulselength)) = -bits(k);
     if up(m)>0 %&& k==numel(bits),
        newtrigger(up(m)+(0:9)) = mode(newtrigger(up(m)+(0:9)));
      end
    end
  end
  newtrigger(newtrigger<0) = 0;
  
  dtrigger             = diff(find(diff(newtrigger)));
  dtrigger(dtrigger<3) = []; % triggers less than 5 samples wide probably don't mean anything
  pulselength          = mode(dtrigger);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the datasets that have a long pulselength, i.e. on the order of
% 30 ms or so.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% the following part is modified from ft_read_event
channel     = 'UPPT001';
event       = [];
begsample   = 1;
pad         = 0;

if ~isempty(bits)
  trigshift = 3;
else
  trigshift = 0;
end

% assign pulselength threshold depending on MEG scenario
% there are sound files specific to scenario 1 and 3 where the onset
% between the auditory soundfile and first word are extremely close
subjval = str2double(subjname(2:end));
if scenario == 1 || scenario == 3 || (scenario == 2 && subjval >= 2080) %A2080, A2086, A2092, A2098, A2102, A2106
    pulselengththreshold = 5;
else 
    pulselengththreshold = 30;
end 
    
if pulselength > pulselengththreshold
  
  % convert the trigger into an event with a value at a specific sample
  % getting both the up and downflanks
  for j=find(diff([pad newtrigger(:)'])>0)
    event(end+1).type   = [channel '_up'];        % distinguish between up and down flank
    event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
    event(end  ).value  = newtrigger(j+trigshift);      % assign the trigger value just _after_ going up
  end
  % convert the trigger into an event with a value at a specific sample
  for j=find(diff([pad newtrigger(:)'])<0)
    event(end+1).type   = [channel '_down'];      % distinguish between up and down flank
    event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
    event(end  ).value  = newtrigger(j-1-trigshift);    % assign the trigger value just _before_ going down
  end
  
  smp       = [event.sample];
  [srt,sel] = sort(smp);
  event     = event(sel);
  updown    = zeros(1,numel(event));
  updown(strcmp({event.type}, 'UPPT001_up')) = 1;
  
  val       = [event.value];
  smp       = [event.sample];
  
  % the following tries to deal with overlapping triggers. only works if at
  % most 2 triggers are overlapping. also, if two upflanks occur one sample
  % apart, it could have been a sluggish trigger, merge into 1
  keep = false(size(updown));
  for k = 1:(numel(updown)-2)
    if updown(k)==1 && updown(k+1)==0 && updown(k+2)==1
      keep(k) = 1;
    elseif updown(k)==1 && updown(k+1)==1 && val(k)==val(k+1) && smp(k)==smp(k+1)-1
      keep(k) = 0; % don't keep
      event(k+1).sample = event(k+1).sample-1; % correct the sample
    elseif updown(k)==1 && updown(k+1)==1 && updown(k+2)==0
      keep(k) = 1;
    elseif updown(k)==1 && updown(k+1)==0 && updown(k+2)==0
      keep(k) = 1;
      
      if k>1 && updown(k-1)==0
        % this is needed to fix the 'missing' trigger issue.
        % it seems a perfectly synchronized switching on and off of two
        % triggers, causing an 'incomplete staircase', i.e. a pattern in the
        % updown vector of 0_100_1, rather than 0_1100_1
        keep(k+1) = 1;
        event(k+1).value = event(k+2).value;
        
      else
        % adjust the value
        event(k).value = event(k+2).value;
      end
    else
      % don't keep
    end
  end
  event = event(keep);
  
  % revert event type to UPPT001
  for k = 1:numel(event)
    event(k).type = 'UPPT001';
  end
else
  for j=find(diff([pad newtrigger(:)'])>0)
    event(end+1).type   = channel;        % distinguish between up and down flank
    event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
    event(end  ).value  = newtrigger(j+trigshift);      % assign the trigger value just _after_ going up
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now try to map the events from the logfile onto the events from the
% datafile, expressed in datafile-samples.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% issues:
% -datafile sample unit is 1/1200 second
% -logfile sample unit is 1/10000 second
% -offset logfile versus datafile is unknown
% -when presentation was paused, the logfile clock stopped ticking
%
% for now first solve the case where each of the event structures contains
% all trials, i.e. 240
%
% the thing we will do, is to extract from each sequence of triggers in
% the logfile, the identity of the wavfile, and add this as an extra event,
% where the sample is identical to the onset of the audio file, but the
% type reflects the identity of the wavfile.

sel1     = find(strcmp({event.type}', 'UPPT001'));
tmpevent = event(sel1);
fixdat   = find([tmpevent.value]==20);
fixlog   = find(strcmp({eventlog.type}', 'fixation'));

fixdatsmp = [tmpevent(fixdat).sample];
fixlogsmp = [eventlog(fixlog).sample];

if numel(fixdatsmp)==numel(fixlogsmp) && numel(fixdatsmp)==240
  % this is the easy case
  wavfiles = {eventlog(fixlog+1).type}';
  for k = 1:numel(wavfiles)
    event(end+1).type   = wavfiles{k};
    event(end  ).sample = event(fixdat(k)).sample;
    event(end  ).value  = 14;
  end
  smp = [event.sample];
  [srt,ix] = sort(smp);
  event = event(ix);
elseif numel(fixdatsmp)<numel(fixlogsmp)
  % express both in milliseconds and find a match, based on the assumption
  % that the data contains a continuous sequence of the trials 
  fixdatsmp = fixdatsmp./1.2;
  fixlogsmp = fixlogsmp./10;
  match_id  = nan+zeros(numel(fixlogsmp)-numel(fixdatsmp)+1,1);
  for m = 1:numel(match_id)
    tmp      = abs(diff(fixdatsmp)-diff(fixlogsmp(m-1+(1:numel(fixdatsmp)))));
    match_id(m,1) = median(tmp);
  end
  [m,ix] = min(match_id(:,1));
  fprintf('matching trial %d to %d in the logfile with the data, median of timing difference is %d ms\n', ix, ix-1+numel(fixdatsmp), m);
  wavfiles = {eventlog(fixlog+1).type}';
  for k = 1:numel(fixdatsmp)
    event(end+1).type   = wavfiles{k+ix-1};
    event(end  ).sample = event(fixdat(k)).sample;
    event(end  ).value  = 14;
  end
else
  warning('did not manage to merge event information from log file with the event information from the triggers, returning only triggers'); 
end
