function [tlck, Trl_idx] = mous_multisetcca_extractwords(comp, stimuli, latency)

if nargin<3
  latency = [-0.1 0.8];
end

isaudio = false(numel(comp.label),1);
for k = 1:numel(comp.label)
  isaudio(k) = strcmp(comp.label{k}(end-3),'2');
end
iv = (~isaudio);
ia = ( isaudio);

xx = cell(numel(comp.trial),1);
for k = 1:numel(comp.trial)
  xx{k}=stimuli(comp.trialinfo(k,end)).timinginfo_visual(:,2);
end

% set up cfg for ft_timelockanalysis to grab the word onset locked data
cfg              = [];
cfg.keeptrials   = 'yes';

% create the event-locked structure array (as a function of ordinal word)
nword = 15; %max number of words per sentence
timeorig = comp.time;
time     = comp.time;
for m = 1:nword
  usetrials = true(numel(comp.trial),1);
  for k = 1:numel(comp.trial)
    if numel(xx{k})>=m
      offset = round(xx{k}(m)*comp.fsample)./comp.fsample; % this needs some rounding off in integer multiples of hte sampling interval
      % to avoid a crash in the new implementation of timelockanalysis
      time{k}=timeorig{k}-offset;
    else
      usetrials(k)=false;
    end
  end
  comp.time=time;
  cfg.trials = usetrials;
  if any(usetrials)
    tmptlck(m)=ft_timelockanalysis(cfg, comp);
    duration = nan(size(tmptlck(m).trial,1),2);
    for mm = 1:size(tmptlck(m).trial,1)
      trl_idx = tmptlck(m).trialinfo(mm,end);
      Trl_idx{m}(mm,1) = trl_idx;
      Trl_idx{m}(mm,2) = m;
      duration(mm,1) = stimuli(trl_idx).timinginfo(m+1,2)-stimuli(trl_idx).timinginfo(m,2);
      try,duration(mm,2) = stimuli(trl_idx).timinginfo_visual(m+1,2)-stimuli(trl_idx).timinginfo_visual(m,2); end
    end
    tmptlck(m).trialinfo = duration;
  end
end
Trl_idx = cat(1,Trl_idx{:});

for k = 1:numel(comp.trial)
  id         = comp.trialinfo(k,end);
  nword_here = stimuli(id).numwords;
  
  % very sporadically there's some discrepancy between the
  % 'timinginfo_visual' field, and the expected number of words. In this
  % case, let the smallest number prevail, to avoid crashes.
  if nword_here>numel(xx{k})
    nword_here = numel(xx{k});
  end
  
  words      = stimuli(id).words;
  words      = words(1:nword_here);
  
  dur_v(k,1:nword_here-1) = diff(xx{k});
  dur_v(k,  nword_here)   = min(1,comp.time{k}(end)); % time axis is corrected for last word onset, but occasionally the sentences is way too long, truncate length at 1
  indx(k, 1:nword_here)   = 1:nword_here;
  
  allwords(1:nword_here,k) = keepfields(words,{'POS' 'word' 'duration'})';
end
% reorganize the words
allwords = allwords'; %to order according to ordinal word position not trials
words          = [];
words.word     = [allwords(:).word]';
words.POS      = [allwords(:).POS]';
words.duration = [allwords(:).duration]';

begtim  = latency(1);
endtim  = latency(2);
tim     = linspace(begtim,endtim,diff(latency).*120+1);
N       = numel(tim);

Yav = zeros(0,N); % hard coded
Ya  = zeros(0,N);
Yv  = zeros(0,N);
Yall = zeros(0,N*size(tmptlck(1).trial,2));

% loop over ordinal words
for k = 1:numel(tmptlck)
  
  begs = nearest(tmptlck(k).time,begtim);
  ends = nearest(tmptlck(k).time,endtim);
  begx = nearest(tim, tmptlck(k).time(begs));
  endx = nearest(tim, tmptlck(k).time(ends));
  
  if any(iv)
    tmp  = reshape(nanmean(tmptlck(k).trial(:,iv,:),2), [], numel(tmptlck(k).time));
    tmpY = nan(size(tmp,1),N);
    tmpY(:,begx:endx) = tmp(:,begs:ends);
    Yv   = cat(1,Yv,tmpY);
  end
  
  if any(ia)
    tmp  = reshape(nanmean(tmptlck(k).trial(:,ia,:),2), [], numel(tmptlck(k).time));
    tmpY = nan(size(tmp,1),N);
    tmpY(:,begx:endx) = tmp(:,begs:ends);
    Ya   = cat(1,Ya,tmpY);
  end
    
  tmp  = reshape(nanmean(tmptlck(k).trial(:,:,:),2), [], numel(tmptlck(k).time));
  tmpY = nan(size(tmp,1),N);
  tmpY(:,begx:endx) = tmp(:,begs:ends);
  Yav  = cat(1,Yav,tmpY);
  
  tmp  = tmptlck(k).trial(:,:,begs:ends);
  tmpY = nan(size(tmp,1),size(tmp,2),N);
  tmpY(:,:,begx:endx) = tmp;
  siz   = size(tmpY);
  tmpY  = reshape(permute(tmpY,[1 3 2]),[siz(1) siz(2)*siz(3)]);
  Yall  = cat(1,Yall,tmpY);
end

Yav(~isfinite(Yav)) = 0;
if any(iv)
  Yv(~isfinite(Yv))   = 0;
else
  Yv = nan(size(Ya));
end
if any(ia)
  Ya(~isfinite(Ya))   = 0;
else
  Ya = nan(size(Yv));
end
Yall(~isfinite(Yall)) = 0;

tlck = [];
tlck.time         = tim;
tlck.trial(:,1,:) = Yv;
tlck.trial(:,2,:) = Ya;
tlck.trial(:,3,:) = Yav;
tlck.trial(:,3+(1:siz(2)),:) = permute(reshape(Yall,[size(Yall,1) siz(3) siz(2)]),[1 3 2]);
tlck.label  = {'visual';'audio';'both'};
tlck.label = cat(1,tlck.label,comp.label);
tlck.dimord = 'rpt_chan_time';

tlck.trialinfo = table(words.word, words.POS, cat(1,tmptlck.trialinfo), Trl_idx(:,1), Trl_idx(:,2),...
  'variablenames', {'word','POS','duration2','id','ordinal'});

