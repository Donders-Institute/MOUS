function tlck = mous_auditory_chop(subjectname)

% load in the data epoched per sentence with audioonset + audiodelay
% correction and then manually subtracting a baseline of 0.2 seconds (or
% so)
f   = mous_db_getfilename(subjectname, 'meg_ds_task');
if numel(f)>1
  ext = cell(1,numel(f));
  for k = 1:numel(f)
    ext{k} = sprintf('_pt%s',num2str(k));
  end
else
  ext{1} = '';
end

data = cell(1,numel(f));
mask = cell(1,numel(f));
for k = 1:numel(f)
  if strcmp(subjectname(1), 'A')
    % auditory subject
    trl        = mous_defineTrial(f{k}, 'audioonset', 0, 'trialfun_auditory_sentence');
  else
    trl        = mous_defineTrial(f{k}, 0, 0, 'trialfun_visual_sentence');
  end
  trl(:,[1 3]) = trl(:,[1 3]) - 240; % subtract 0.2 s for the baseline
  trl          = trl(trl(:,end)<500,:); % select the sentences
  
  cfg            = [];
  cfg.dataset    = f{k};
  cfg.continuous = 'yes';
  cfg.lpfilter   = 'yes';
  cfg.lpfreq     = 40;
  cfg.lpfilttype = 'firws';
  cfg.trl        = trl;
  cfg.channel    = 'MEG';
  cfg.padding    = 10;
  cfg.hpfilter   = 'yes';
  cfg.hpfreq     = 2;%0.5;
  cfg.hpfilttype = 'firws';
  cfg.usefftfilt = 'yes';
  data{k}        = ft_preprocessing(cfg);
  
  % create a mask variable that codes for the artifacts
  mous_db_getdata(subjectname, ['meg_artifact_cfg',ext{k}]);
  if ~isempty(cfgjump.artfctdef.zvalue.artifact)
    % take half the data padding length for preprocessing
    cfgjump.artfctdef.zvalue.artifact(:,1) = cfgjump.artfctdef.zvalue.artifact(:,1)-1200*5;
    cfgjump.artfctdef.zvalue.artifact(:,2) = cfgjump.artfctdef.zvalue.artifact(:,2)+1200*5;
  end
  trlnew = mous_artifact_remove(trl, f{k}, {cfgeog1 cfgeog2 cfgjump cfgmuscle});
  
  dum    = false(1,max(trl(:,2)));
  for kk = 1:size(trlnew,1)
    dum(trlnew(kk,1):trlnew(kk,2))=true;
  end
  
  mask{k} = cell(1,numel(data{k}.trial));
  for kk = 1:numel(data{k}.trial)
    mask{k}{1,kk} = dum(data{k}.sampleinfo(kk,1):data{k}.sampleinfo(kk,2));
  end
  
  % keep track of the gradiometer info
  sens(k)    = data{k}.grad;
  weights(k) = numel(data{k}.trial);
end

if numel(f)>1
  data = ft_appenddata([], data{:});
  mask = cat(2, mask{:});
  data.grad = ft_average_sens(sens, 'weights', weights);  
else
  data = data{1};
  mask = mask{1};
end

load mous_stimuli;
indx = cell(1,numel(data.trial));
pre = cell(1,numel(data.trial));
pst = cell(1,numel(data.trial));
for k = 1:numel(data.trial)
  idx      = data.trialinfo(k,5);
  if isfield(stimuli(idx).words, 'onset')
    onset    = cat(1,stimuli(idx).words.onset);
    %offset   = cat(1,stimuli(idx).words.offset);
    %duration = cat(1,stimuli(idx).words.duration);
    
    %offset = offset - onset(1);
    onset  = onset  - onset(1);
    if all(isfinite(onset))
    for m = 1:numel(onset)
      indx{k}(m) = nearest(data.time{k},onset(m));
      pre{k}(m)  = indx{k}(m)-90; pre{k}(m) = max(pre{k}(m),1);
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
tlck.time   = ((1:691)-90)./1200;
tlck.avg = avg;
tlck.dof = repmat(cnt,[numel(data.label) 1]);
tlck.grad = data.grad;

