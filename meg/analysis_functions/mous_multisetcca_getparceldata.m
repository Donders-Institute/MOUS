function [dataout, stim] = mous_multisetcca_getparceldata(subjectname, data, timinginfo, groupinfo, shift, stretch, weightrepeats)

% this function reorganizes the parcel-based time seriessuch, that the trials align
% across a set of subjects, according to the specified timinginfo and
% groupinfo

if nargin<7 || isempty(weightrepeats)
  weightrepeats = false;
end
if nargin<6 || isempty(stretch)
  stretch = [];
end
if nargin<5 || isempty(shift)
  shift = 0;
end

hasstim = strncmp(data.label{end},'stim',4);

% first select the trials according to the earlier determined selection
% based on timing inaccuracies:
data.trial = data.trial(timinginfo.trials);
data.time  = data.time(timinginfo.trials);
data.trialinfo = data.trialinfo(timinginfo.trials,:);

% sanity check
assert(isequal(data.trialinfo, timinginfo.trialinfo));

% sort the stuff according to the trialid
[srt,srt_idx]  = sort(data.trialinfo(:,end));
data.trial     = data.trial(srt_idx);
data.trialinfo = data.trialinfo(srt_idx,:);
if isfield(data,'sampleinfo'), data.sampleinfo = data.sampleinfo(srt_idx,:); end
data.time      = data.time(srt_idx);
fn = fieldnames(timinginfo);
for k = 1:numel(fn)
  try
    timinginfo.(fn{k}) = timinginfo.(fn{k})(srt_idx,:);
  catch
    timinginfo.(fn{k}) = timinginfo.(fn{k})(srt_idx);
  end
end

if ~hasstim && nargout==2
  % create a stim channel that can be used for debugging, i.e. to check
  % whether the unfolding worked well
  if strcmp(subjectname(2),'2')
    stim = addstimchan(data,'aud');
  elseif strcmp(subjectname(2),'1')
    stim = addstimchan(data,'vis');
  else
    error('wrong subjectname');
  end
  for k = 1:numel(stim.trial)
    tmp = stim.trial{k};
    tmp(end+1)=1;
    sel = find(tmp);
    for m = 1:numel(sel)-1
      tmp(sel(m):sel(m+1)) = linspace(m,m+1,sel(m+1)-sel(m)+1);
    end
    tmp = tmp(1:end-1);
    stim.trial{k} = tmp;
  end
  stim.fsample = data.fsample;
  data = ft_appenddata([], data, stim);
  hasstim = true;
else
  % it has been taken from above, and added again
end

% now, 'unfold' the trials according to the timinginfo. This maps the
% timeseries as 'timed' by smpin onto smpout
for k = 1:numel(data.trial)
  smpin  = timinginfo.smpin{k};
  smpout = timinginfo.smpout{k}; 
  if ~isempty(shift)
    % assume this to be in samples, a positive value effectively means
    % shifting this response to the 'right' in time, i.e. pretend that it
    % occurred later than in reality
    smpin(:,1) = smpin(:,1) - shift;
    
%     sel = sum(smpin-1<shift,2)>0;
%     smpin(sel,:) = [];
%     smpout(sel,:) = [];
    sel = smpin(:,1) < 1;
    if sum(sel)
      val = smpin(sel,1);
      smpin(sel,1) = smpin(sel,1)-val+1;
      smpout(sel,1) = smpout(sel,1)-val+1;
    end
  end
  datin   = data.trial{k};
  countin = zeros(1,numel(data.time{k}));
  
  datout   = nan(size(datin,1), numel(timinginfo.time{k}));
  countout = zeros(size(smpout,1),numel(timinginfo.time{k}));
  
  for m = 1:size(smpin,1)-1
    countin(smpin(m,1):smpin(m+1,1)-1) = m;
  end
  countin(smpin(end,1):end) = m+1;
  
  timeout = timinginfo.time{k};
  for m = 1:size(smpout,1)
    nsmp = smpout(m,2)-smpout(m,1)+1;
    
    smpin_idx  = smpin(m,1)-1+(1:nsmp);
    smpout_idx = smpout(m,1):smpout(m,2);
    
    keep_idx   = smpin_idx<=size(datin,2); % this can become empty in rare cases, i.e. when shuffling
    
    if sum(keep_idx)
      smpin_idx  = smpin_idx(keep_idx);
      smpout_idx = smpout_idx(keep_idx);
      
      keep_idx   = smpout_idx<=size(datout,2);
      smpin_idx  = smpin_idx(keep_idx);
      smpout_idx = smpout_idx(keep_idx);
      
      if ~isempty(stretch) && stretch~=1
        nsmp   = numel(smpout_idx);
        tmpdat = datin(:,smpin_idx(1):end);
        
        % stretch the time axis
        x_in = 0:(size(tmpdat,2)-1);
        x_out = linspace(0,(nsmp-1)./stretch, nsmp);
        
        tmpdat = interp1(x_in(:),tmpdat',x_out(:),'linear')';
        
      else
        tmpdat = datin(:,smpin_idx);
      end
      
      datout(:,smpout_idx) = tmpdat;%-repmat(nanmean(tmpdat,2),[1 numel(smpin_idx)]);
      countout(m,smpout_idx) = countin(smpin_idx);
      last_idx = smpout_idx(end);
    end
  end
  datout  = datout(:,1:last_idx);
  timeout = timeout(1:last_idx);
  countout = countout(:,1:last_idx);
  
  overlap  = zeros(size(countout,1));
  for kk = 1:size(countout,1)
    overlap(:,kk) = sum(countout==kk,2);
  end
  
  countout_bin = zeros(size(countout));
  for kk = 1:size(countout,1)
    nsmp = overlap(overlap(:,kk)>0,kk);
    nmax = numel(nsmp);
    for kk1 = 1:nmax
      for kk2 = 1:nmax
        rowindx = kk-kk2+1;
        if rowindx<= size(countout,1)
          tmpindx = find(countout(rowindx,:)==kk,nsmp(kk1));
          countout_bin(rowindx,tmpindx) = countout_bin(rowindx,tmpindx)+1;
        end
      end
    end
  end
  countout_bin = sum(countout_bin,1);  
  
  if weightrepeats
    data.trial{k} = datout./repmat(countout_bin,[size(datout,1),1]);
  else
    data.trial{k} = datout;
  end
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
    %timaxis = groupinfo.mintim(k) + (0:(groupinfo.maxnsmp(k)-1))./120;
    timaxis = (round(120.*groupinfo.mintim(k)):round(120.*groupinfo.maxtim(k)))./120;
    time{k} = timaxis;
    trial{k} = nan(numel(data.label),numel(timaxis));
    trialinfo(k,end) = groupinfo.trialid(k);
  end
end

% % % % % % if shift is different from 0, shift the data with the specified number of
% % % % % % samples: per definition if shift>0, the data shifts to the left, which
% % % % % % means that time is delayed (equivalently)
% % % % % if shift>0
% % % % %   for k = 1:numel(trial)
% % % % %     trial{k} = [trial{k}(:,(1+shift):end) nan(size(trial{k},1),shift)];
% % % % %   end
% % % % % elseif shift<0
% % % % %   for k = 1:numel(trial)
% % % % %     trial{k} = [nan(size(trial{k},1),abs(shift)) trial{k}(:,1:(end+shift))];
% % % % %   end
% % % % % end

if hasstim
  stim = keepfields(data, {'label'});
  stim.label = data.label(end);
  stim.trial    = cellrowselect(trial, size(trial{1},1));
  stim.time     = time;
  stim.trialinfo = trialinfo;
  
  dataout           = keepfields(data, {'label'});
  dataout.label     = dataout.label(1:end-1);
  dataout.trial     = cellrowselect(trial, 1:(size(trial{1},1)-1));
  dataout.time      = time;
  dataout.trialinfo = trialinfo;
else
  dataout           = keepfields(data, {'label'});
  dataout.trial     = trial;
  dataout.time      = time;
  dataout.trialinfo = trialinfo;
end
