function freq = mous_auditory_chop_freq(subjectname, condition)

if nargin == 1
  condition = 'sent';
end

if ~isstruct(subjectname)
  
  % load in the data epoched per sentence with audioonset + audiodelay
  % correction and then manually subtracting a baseline of 0.4 seconds (or
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
      trl(:,3)   = 0; % time point zero should be audio onset, rather than the onset of the first word
    else
      trl        = mous_defineTrial(f{k}, 0, 0, 'trialfun_visual_sentence');
    end
    trl(:,[1 3]) = trl(:,[1 3]) - 480; % subtract 0.2 s for the baseline
    switch condition
      case 'sent'
        trl = trl(trl(:,end)<500,:); % select the sentences
      case 'seq'
        trl = trl(trl(:,end)>500,:); % select the sequences
    end
    
    cfg            = [];
    cfg.dataset    = f{k};
    cfg.continuous = 'yes';
    cfg.lpfilter   = 'yes';
    cfg.lpfreq     = 80;
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
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'template';%'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data);
  data = ft_megplanar(cfgplanar, data);
  
else
  % this is new behaviour, and bypasses the creation of the data object on
  % the fly, uses arbitrary data, if appropriate. Can e.g. also be a comp
  % structure. This requires the creation of a mask parameter
  
  
  data = subjectname;
  mask = cell(1,numel(data.trial));
  for k = 1:numel(data.trial)
    mask{k} = isfinite(data.trial{k}(1,:));
    data.trial{k}(:,~mask{k}) = 0;
  end
  
  
  % try to extract the subjectname
  tmp     = ft_findcfg(data.cfg, 'dataset');
  [p,f,e] = fileparts(tmp);
  if strncmp(f(1:3),'sub-',4)
    subjectname = f(1:8);
  else
    subjectname = f(1:5);
  end
  subjectname = strrep(subjectname,'sub-1','V');
  subjectname = strrep(subjectname,'sub-2','A');
  
end

fsample = 1./mean(diff(data.time{1}));



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
      pre{k}(m)  = indx{k}(m)-240; pre{k}(m) = max(pre{k}(m),1);
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
params.fsample = fsample;
params.time = data.time;
params.timeoi = -0.15:0.01:0.45;
params.freqoi = 4:2:40;
params.timwin = 4./params.freqoi;
params.output = 'itc';
params.nrand  = 0;%100;
X.x = 1;
[~,~,avg,cnt,avg_shuf,pval]=denoise_avg_spectrogram(params,data.trial,X);

freq = [];
freq.label = data.label;
freq.dimord = 'chan_freq_time';
freq.time   = params.timeoi;
freq.freq   = params.freqoi;
freq.itcspctrm = avg;
freq.itcspctrm_shuf = avg_shuf;
freq.pval      = pval;
freq.dof = cnt;
freq.grad = data.grad;

