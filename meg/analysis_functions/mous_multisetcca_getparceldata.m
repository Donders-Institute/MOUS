function dataout = mous_multisetcca_getparceldata(subjectname, data, source, timinginfo, groupinfo, parcel_indx, shift)

% this function projects the sensor-level data into source space, for the
% specified parcel, and then reorganizes the trials such, that they align
% across a set of subjects, according to the specified timinginfo and
% groupinfo

[a,b] = match_str(source.filterlabel, data.label);

indx       = 1:min(5,size(source.F{parcel_indx},1));
data.trial = source.F{parcel_indx}(indx,a)*cellrowselect(data.trial,b);
data.label = data.label(indx);

% first select the trials according to the earlier determined selection
% based on timing inaccuracies:
data.trial = data.trial(timinginfo.trials);
data.time  = data.time(timinginfo.trials);
data.trialinfo = data.trialinfo(timinginfo.trials,:);

assert(isequal(data.trialinfo, timinginfo.trialinfo));

% sort the stuff according to the trialid
[srt,srt_idx] = sort(data.trialinfo(:,end));
data.trial = data.trial(srt_idx);
data.trialinfo = data.trialinfo(srt_idx,:);
data.time = data.time(srt_idx);
fn = fieldnames(timinginfo);
for k = 1:numel(fn)
  try
    timinginfo.(fn{k}) = timinginfo.(fn{k})(srt_idx,:);
  catch
    timinginfo.(fn{k}) = timinginfo.(fn{k})(srt_idx);
  end
end

% now, 'unfold' the trials according to the timinginfo
for k = 1:numel(data.trial)
  smpin  = timinginfo.smpin{k};
  smpout = timinginfo.smpout{k}; 
  datin  = data.trial{k};
  datout = nan(size(datin,1), numel(timinginfo.time{k}));
  timeout = timinginfo.time{k};
  for m = 1:size(smpout,1)
    nsmp = smpout(m,2)-smpout(m,1)+1;
    
    smpin_idx  = smpin(m,1)-1+(1:nsmp);
    smpout_idx = smpout(m,1):smpout(m,2);
    
    keep_idx   = smpin_idx<=size(datin,2);
    smpin_idx  = smpin_idx(keep_idx);
    smpout_idx = smpout_idx(keep_idx);
    
    datout(:,smpout_idx) = datin(:,smpin_idx);%-repmat(nanmean(datin,2),[1 numel(smpin_idx)]);
  end
  datout  = datout(:,1:smpout_idx(end));
  timeout = timeout(1:smpout_idx(end));

  data.trial{k} = datout;
  data.time{k}  = timeout;
end

% now, create a new set of trials according to the groupinfo
trial = cell(1,numel(groupinfo.trialid));
time  = cell(1,numel(groupinfo.trialid));
trialinfo = nan(numel(groupinfo.trialid),size(data.trialinfo,2));
for k = 1:numel(trial)
  sel = find(data.trialinfo(:,end)==groupinfo.trialid(k));
  if ~isempty(sel)
    % create an maxnsmp trial with corresponding time axis, and fill
    % as appropriate with data
    dat = data.trial{sel};
    tim = data.time{sel};
    
    %timaxis = groupinfo.mintim(k) + (0:(groupinfo.maxnsmp(k)-1))./120;
    
    timaxis = (round(120.*groupinfo.mintim(k)):round(120.*groupinfo.maxtim(k)))./120;
    time{k} = timaxis;
    
    trial{k} = nan(size(dat,1),numel(timaxis));
    trial{k}(:,nearest(time{k},tim(1))+(0:(size(dat,2)-1))) = dat;
    trialinfo(k,:) = data.trialinfo(sel,:);
  else
    % create an all-nan trial
    timaxis = groupinfo.mintim(k) + (0:(groupinfo.maxnsmp(k)-1))./120;
    time{k} = timaxis;
    trial{k} = nan(numel(data.label),numel(timaxis));
    trialinfo(k,end) = groupinfo.trialid(k);
  end
end

% if shift is different from 0, shift the data with the specified number of
% samples: per definition if shift>0, the data shifts to the left, which
% means that time is delayed (equivalently)
if shift>0
  for k = 1:numel(trial)
    trial{k} = [trial{k}(:,(1+shift):end) nan(size(trial{k},1),shift)];
  end
elseif shift<0
  for k = 1:numel(trial)
    trial{k} = [nan(size(trial{k},1),abs(shift)) trial{k}(:,1:(end+shift))];
  end
end

dataout = keepfields(data, {'label'});
dataout.trial = trial;
dataout.time  = time;
dataout.trialinfo = trialinfo;

