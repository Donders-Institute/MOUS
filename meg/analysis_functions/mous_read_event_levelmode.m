function [event] = mous_read_event_audio(dataset, bits)

% ideally we should use ft_read_data here
cfg            = [];
cfg.dataset    = dataset;
cfg.continuous = 'yes';
cfg.channel    = 'UPPT001';
data           = ft_preprocessing(cfg);
trigger        = data.trial{1}(1,:);

bitvalue = [1 2 4 8 16 32 64 128];
for k = 1:numel(bitvalue)
  n(k) = sum(bitand(trigger,bitvalue(k))>0);
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

trig    = newtrigger;

detectflank = 'up';
trigshift   = 3;
channel     = 'UPPT001';
event       = [];
begsample   = 1;
pad         = 0;

switch detectflank
  case 'up'
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad trig(:)'])>0)
      event(end+1).type   = channel;
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = trig(j+trigshift);      % assign the trigger value just _after_ going up
    end
  case 'down'
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad trig(:)'])<0)
      event(end+1).type   = channel;
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = trig(j-1-trigshift);    % assign the trigger value just _before_ going down
    end
  case 'both'
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad trig(:)'])>0)
      event(end+1).type   = [channel '_up'];        % distinguish between up and down flank
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = trig(j+trigshift);      % assign the trigger value just _after_ going up
    end
    % convert the trigger into an event with a value at a specific sample
    for j=find(diff([pad trig(:)'])<0)
      event(end+1).type   = [channel '_down'];      % distinguish between up and down flank
      event(end  ).sample = j + begsample - 1;      % assign the sample at which the trigger has gone down
      event(end  ).value  = trig(j-1-trigshift);    % assign the trigger value just _before_ going down
    end
  otherwise
    error('incorrect specification of ''detectflank''');
end
