function tlck = mous_auditory_chop(subjectname)

% load in the data epoched per sentence with audioonset + audiodelay
% correction and then manually subtracting a baseline of 0.2 seconds (or
% so)
f   = mous_db_getfilename(subjectname, 'meg_ds_task');
trl = mous_defineTrial(f{1}, 'audioonset', 0, 'trialfun_auditory_sentence');
trl(:,[1 3]) = trl(:,[1 3]) - 240; % subtract the baseline
trl = trl(trl(:,end)<500,:); % select the sentences

cfg            = [];
cfg.dataset    = f{1};
cfg.continuous = 'yes';
cfg.lpfilter   = 'yes';
cfg.lpfreq     = 40;
cfg.trl        = trl;
cfg.channel    = 'MEG';
cfg.padding    = 10;
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 0.5;
cfg.hpfiltord  = 2;
data = ft_preprocessing(cfg);

% create a mask variable that codes for the artifacts
mous_db_getdata(subjectname, 'meg_artifact_cfg');
trlnew = mous_artifact_remove(trl, f{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle});
dum = false(1,max(trl(:,2)));
for k = 1:size(trlnew,1)
  dum(trlnew(k,1):trlnew(k,2))=true;
end
for k = 1:numel(data.trial)
  mask{1,k} = dum(data.sampleinfo(k,1):data.sampleinfo(k,2));
end

load mous_stimuli;
indx = {};
pre = {};
pst = {};
for k = 1:numel(data.trial)
  idx      = data.trialinfo(k,5);
  if isfield(stimuli(idx).words, 'onset')
    onset    = cat(1,stimuli(idx).words.onset);
    offset   = cat(1,stimuli(idx).words.offset);
    duration = cat(1,stimuli(idx).words.duration);
    
    offset = offset - onset(1);
    onset  = onset  - onset(1);
    if all(isfinite(onset))
    for m = 1:numel(onset)
      indx{k}(m) = nearest(data.time{k},onset(m));
      pre{k}(m)  = indx{k}(m)-60; pre{k}(m) = max(pre{k}(m),1);
      pre{k}(m)  = indx{k}(m)-pre{k}(m);
      if m<numel(onset)
        pst{k}(m) = nearest(data.time{k},onset(m+1))-indx{k}(m);
      else
        pst{k}(m) = numel(data.time{k})-indx{k}(m);
      end
    end
    end
  end
end

% second loop to only define as triggers those instances where the duration
% of the previous word was sufficiently long, and truncate at 0.5 seconds
for k = 1:numel(data.trial)
  if ~isempty(indx{k})
  duration = diff([0 indx{k}]);
  sel = [true duration(2:end)>300] & [duration(1:end-1)>300 true];
  indx{k} = indx{k}(sel);
  pre{k} = pre{k}(sel);
  pst{k} = pst{k}(sel);
  pst{k} = min(pst{k}, 600);
  end
 end
params.tr = indx;
params.pre = pre;
params.pst = pst;
params.mask = mask;
params.computenew = 0;
params.demean = 'prezero';
X.x = 1;
[~,~,avg,cnt]=denoise_avg2(params,data.trial,X);

tlck = [];
tlck.label = data.label;
tlck.dimord = 'chan_time';
tlck.time   = ((1:661)-60)./1200;
tlck.avg = avg;
tlck.dof = repmat(cnt,[numel(data.label) 1]);
tlck.grad = data.grad;

