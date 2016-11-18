 function tlck = mous_bsl_chop(subjectname,condition)

% load in the data epoched per sentence with audioonset + audiodelay
% correction and then manually subtracting a baseline of 0.2 seconds (or
% so)

%subj = mous_db_getfilename('all','subjectname');

if nargin<2
  condition = []; %use only sequences for the mne sourcerec
end

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
    trl(:,[1 3]) = trl(:,[1 3]) - 1200; % subtract 0.2 s for the baseline
  else
    trl        = mous_defineTrial(f{k}, 0, 0, 'trialfun_visual_sentence');
  end

 if ~isempty(condition)
    switch condition
        case 'sen'
           sel = ismember(trl(:,5),[1 5 2 6]);   
        case 'seq'
           sel = ismember(trl(:,5),[3 7 8 4]);
    end
    trl = trl(sel,:);
 end

  cfg            = [];
  cfg.dataset    = f{k};
  cfg.continuous = 'yes';
  cfg.lpfilter   = 'yes';
  cfg.lpfreq     = 40;
  cfg.lpfilttype = 'firws';
  cfg.trl        = trl;
  cfg.channel    = 'MEG';
  cfg.padding    = 10;
  %cfg.hpfilter   = 'yes';
  %cfg.hpfreq     = 0.5;%2;
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
  cutoffn = length(data{1}.trial);  
  data = ft_appenddata([], data{:});
  mask = cat(2, mask{:});
  data.grad = ft_average_sens(sens, 'weights', weights);
else
  data = data{1};
  mask = mask{1};
end

if strcmp(subjectname(1), 'A')
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
                for m = 1:1
                    indx{k}(m) = nearest(data.time{k},onset(m));
                    pre{k}(m)  = indx{k}(m)-1200; pre{k}(m) = max(pre{k}(m),1);
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
else %for visual modality
    trlallwords = [];
    % load in word onset smpl information via trialfun_visual_words
    for k = 1:numel(f)
    trlallwords{k}        = mous_defineTrial(f{k}, 0, 0, 'trialfun_visual_word');
    end
    if numel(f)>1  
     indxkeep = ~(trlallwords{1}(:,4) > cutoffn);
     trlallwords{1} = trlallwords{1}(indxkeep',:); 
     trlallwords = cat(1, trlallwords{:});   
    else
     trlallwords = trlallwords{1};
    end
    %make sure trialfun selection corresponds to data trial selection
    
    trlallwords = trlallwords(ismember(trlallwords(:,4),data.trialinfo(:,1)),:);
    indx = cell(1,numel(data.trial));
    pre = cell(1,numel(data.trial));
    pst = cell(1,numel(data.trial));
    indxzero = find(trlallwords(:,6) == 0);

    for k = 1:numel(data.trial)
        if k+1 < numel(indxzero)
            idx = [indxzero(k):(indxzero(k+1)-1)];
            onsets = trlallwords(idx,6);
        else
            idx = [indxzero(k):length(trlallwords)];
        end
        if all(isfinite(onsets))
                for m = 1:1
                    indx{k}(m) = onsets(m)+nearest(data.time{k},0);
                    pre{k}(m)  = indx{k}(m)-1200; pre{k}(m) = max(pre{k}(m),1);
                    pre{k}(m)  = indx{k}(m)-pre{k}(m);
                    if m<numel(onsets)
                        pst{k}(m) = nearest(data.time{k},onsets(m+1))-indx{k}(m);
                    else
                        pst{k}(m) = numel(data.time{k})-indx{k}(m);
                    end
                    pst{k} = min(pst{k}, 600);
                end
            end
    end
end

for k = 1:numel(pre)
        pre{k} = pre{k}(:);
        pst{k} = pst{k}(:); 
        indx{k} = indx{k}(:);
end

params.tr = indx;
params.pre = pre;
params.pst = pst;
params.mask = mask;
params.computenew = 0;
params.demean = 'prezero';
params.covariance = 1;
X.x = 1;
[~,~,avg,cnt,covar]=denoise_avg2(params,data.trial,X);

tlck = [];
tlck.label = data.label;
tlck.dimord = 'chan_time';
tlck.time   = ((1:1801)-1200)./1200;
tlck.avg = avg;
tlck.cov = covar;
tlck.dof = repmat(cnt,[numel(data.label) 1]);
tlck.grad = data.grad;

% cfg = [];
% cfg.latency = [tlck.time(1) 0];
% tlck = ft_selectdata(cfg,tlck);

mous_db_putdata(subjectname, 'meg_erf_bslchopped', 'tlck', '/project/3011020.09/MEG/');
