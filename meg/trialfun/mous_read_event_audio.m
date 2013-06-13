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
  dataset = mous_db_getfilename(dataset, 'meg_raw_task');
  dataset = dataset{1};
end

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
dtrigger(dtrigger<5) = []; % triggers less than 5 samples wide probably don't mean anything
pulselength          = mode(dtrigger);

newtrigger = trigger;
for k = 1:numel(bits)
  tmp  = bitand(trigger, bits(k));
  
  % all upflanks occurring within the upstate of a bit, are trigger codes
  % that contain this bit, so for the following part of the code to work,
  % it should be detectable as a 'new' upstate.
  allup   = diff([trigger(1) trigger])>0;
  upup  = tmp>0 & allup;
  tmp([upup(2:end) false]) = 0;
  
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
  end
end
newtrigger(newtrigger<0) = 0;

% the following part is directly copied from ft_read_event
detectflank = 'up';
channel     = 'UPPT001';
event       = [];
begsample   = 1;
pad         = 0;

if ~isempty(bits)
  trigshift = 3;
else
  trigshift = 0;
end

switch detectflank
  case 'up'
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad newtrigger(:)'])>0)
      event(end+1).type   = channel;
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = newtrigger(j+trigshift);      % assign the trigger value just _after_ going up
    end
  case 'down'
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad newtrigger(:)'])<0)
      event(end+1).type   = channel;
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = newtrigger(j-1-trigshift);    % assign the trigger value just _before_ going down
    end
  case 'both'
    % convert the trigger into an event with a value at a specific sample
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
  otherwise
    error('incorrect specification of ''detectflank''');
end

% event2 = read_logfile_audio(subjectname);
% 
% % now match event and event2 (convert the presentation timing values into
% % approximate sample values for the MEG -> fit a linear model only to get the offset.
% % this does not seem to work: try on a per trial basis to minimize the
% % mismatch
% 
% sel1   = strcmp({event.type}, 'UPPT001');
% otherevent = event(setdiff(1:numel(event), sel1));
% event  = event(sel1);
% val1   = [event(:).value];
% val2   = [event2(:).value];
% 
% sel1   = find(val1==20);
% sel2   = find(val2==20);
% 
% if numel(sel1)<numel(sel2)
%   % assume the logfile is correct
%   % the trigger channel in acq has missed some of them
%   error('there is a mismatch between the triggers that I don''t understand');
% elseif numel(sel1)>numel(sel2)
%   % don't know what's going on
%   error('there is a mismatch between the triggers that I don''t understand');
% else
%   % assume a 1 to 1 match
% end
% 
% for k = 1:numel(sel1)-1
%   x1 = [event([sel1(k) sel1(k+1)]).sample];
%   x2 = [event2([sel2(k) sel2(k+1)]).sample];
%   x2(2,:) = 1;
%   b  = x1/x2;
%   fprintf('using betas of %d and %d\n', b(1), b(2));
%   for m = sel2(k):sel2(k+1)-1
%     event2(m).sample = b(1)*event2(m).sample + b(2);
%   end
% end
% 
% % update the remaining triggers
% for k = (m+1):numel(event2)
%   event2(k).sample = b(1)*event2(k).sample + b(2);
% end
% 
% event = [event(:);event2(:)];
% [srt,ix] = sort([event.sample]');
% event = event(ix);
% 
% 
