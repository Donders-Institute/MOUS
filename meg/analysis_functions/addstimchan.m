function out = addstimchan(data,modality,lags,parametricflag)

% ADDSTIMCHAN takes a data structure, and creates a corresponding
% stick-function 'stim-channel', to be used e.g. for a trf analysis

load mous_stimuli;

if nargin<2 || isempty(modality)
  modality = 'vis';
end

if nargin<3 || isempty(lags)
  lags = 0;
end

if nargin<4
  parametricflag = false;
end

T = data.trialinfo(:,end);
out = keepfields(data, {'time' 'trialinfo'});
out.trial = out.time;
for k = 1:numel(out.time)
  out.trial{k}(:) = 0;
  
  stim_id = T(k);
  switch modality
  case 'vis'
    timing  = stimuli(stim_id).timinginfo_visual(:,1:2);
    timing(end+1,:) = 0;
  case 'aud'
    timing  = stimuli(stim_id).timinginfo;
  end
  
  nword = size(timing,1)-1;
  for m = 1:nword
    if ~parametricflag
      %nearest(out.time{k},timing(m,2))
      out.trial{k}(nearest(out.time{k},timing(m,2))) = 1;
    else
      out.trial{k}(nearest(out.time{k},timing(m,2))) = m-nword/2;
    end
  end
end

if lags(1)~=0 || numel(lags)>1
  out.trial = cellshift(out.trial, lags, 2, [], 'nan');
  out.time  = cellshift(out.time,  lags, 2, [], 'nan');

  selx     = nearest(lags,0);
  out.time = cellrowselect(out.time, selx);

   
  for k = 1:numel(out.time)
    selx = isfinite(out.time{k});
    out.time{k} = out.time{k}(:,selx);
    out.trial{k} = out.trial{k}(:,selx);
  end
  if isequal(out.time,data.time)
    out.time = data.time;
  end
  %out.fsample = data.fsample;
  
  for k = 1:numel(out.trial)
    out.trial{k}(:,sum(isfinite(out.trial{k}),1)<numel(lags)) = 0;
    out.trial{k}(:,~isfinite(data.trial{k}(1,:))) = nan;
  end
  
  cfg = [];
  cfg.method = 'acrosschannel';
  out = ft_channelnormalise(cfg, out);
end

label = cell(numel(lags),1);
 for k = 1:numel(lags)
  label{k} = sprintf('stim_on_lagged%0.3d',k);
end
out.label = label;
 
