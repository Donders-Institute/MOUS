% script that adds visual timing information to the stimuli struct-array

subj = mous_db_getfilename('allV','subjectname');
[f,s] = mous_db_getfilename(subj,'meg_raw_log');
f([6 17]) = [];

sel1  = contains(f, '-1-');
sel2  = contains(f, '-2-');
sel3  = contains(f, '-3-');
sel4  = contains(f, '-4-');
sel5  = contains(f, '-5-');
sel6  = contains(f, '-6-');

subj1 = subj(sel1);
subj2 = subj(sel2);
subj3 = subj(sel3);
subj4 = subj(sel4);
subj5 = subj(sel5);
subj6 = subj(sel6);

for m = 1:6
  switch m
    case 1
      s = subj1;
    case 2
      s = subj2;
    case 3
      s = subj3;
    case 4
      s = subj4;
    case 5
      s = subj5;
    case 6
      s = subj6;
  end
  f = mous_db_getfilename(s, 'meg_ds_task');
  for k = 1:numel(s)
    cfg                   = [];
    cfg.dataset           = f{k};
    cfg.trialfun          = 'trialfun_visual_word_new';
    cfg.trialdef.prestim  = 0;
    cfg.trialdef.poststim = 'nextword';
    cfg = ft_definetrial(cfg);
    trl{k,m} = cfg.trl;
  end
end

for k = 1:numel(trl)
  tmptrl = trl{k};
  if ~isempty(tmptrl)
    utrl   = unique(tmptrl(:,end));
    for m = 1:numel(utrl)
      onsets{utrl(m),k} = tmptrl(tmptrl(:,end)==utrl(m),6)./1200;
    end
  end
end
for k = 1:size(onsets,1)
  if any(~cellfun('isempty',onsets(k,:)))
    sel = ~cellfun('isempty',onsets(k,:));
    tmp(k,1:sum(sel)) = onsets(k, sel);
  end
end

% the timing inaccuracies are appalling, most likely due to some
% interaction between the sub-refresh timing requirements and projector
% refresh locked presentation. There's some additional slips in sub-refresh
% rate samples, which is probably indicicative of the inherent unknown
% temporal relationship between the sending of the trigger, and the actual
% refresh of the screen. that's too bad for now, but here I will use the
% median across subjects as the representative timing information
onsets = cell(908,1);
for k = 1:size(tmp,1)
  tmptmp = tmp(k,:);
  nword  = cellfun(@numel,tmptmp);
  x      = cat(2,tmptmp{nword==mode(nword)});
  onsets{k} = [median(x,2) x];
end


