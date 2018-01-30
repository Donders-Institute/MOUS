function dataout = addstimchan(data,modality,lags)

load mous_stimuli;

if nargin<2
  modality = 'vis';
end

if nargin<3 || isempty(modality)
  lags = 0;
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

  for m = 1:(size(timing,1)-1)
    out.trial{k}(nearest(out.time{k},timing(m,2))) = 1;
  end
end

out.trial = cellshift(out.trial, lags, 2, [], 'nan');
out.time  = cellshift(out.time,  lags, 2, [], 'nan');

selx     = nearest(lags,0);
out.time = cellrowselect(out.time, selx);

label = cell(numel(lags),1);
for k = 1:numel(lags)
  label{k} = sprintf('stim_on_lagged%0.3d',k);
end
out.label = label;

for k = 1:numel(out.time)
  selx = isfinite(out.time{k});
  out.time{k} = out.time{k}(:,selx);
  out.trial{k} = out.trial{k}(:,selx);
end
if isequal(out.time,data.time)
  out.time = data.time;
end
out.fsample = data.fsample;

for k = 1:numel(out.trial)
  out.trial{k}(:,sum(isfinite(out.trial{k}),1)<numel(lags)) = 0;
  out.trial{k}(:,~isfinite(data.trial{k}(1,:))) = nan;
end

cfg = [];
cfg.method = 'acrosschannel';
out = ft_channelnormalise(cfg, out);

dataout           = ft_appenddata([],data,out);
dataout.topolabel = cat(1, data.label, out.label);
dataout.topo      = blkdiag(data.topo, eye(numel(lags)));
dataout.unmixing  = blkdiag(data.unmixing, eye(numel(lags)));
dataout.topodimord = data.topodimord;
dataout.unmixingdimord = data.unmixingdimord;
dataout.trialinfo = data.trialinfo;




