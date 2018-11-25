function [tlck, Trl_idx] = mous_multisetcca_extractwords(comp, stimuli)

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
cfg.vartrllength = 2;

% create the event-locked structure array (as a function of ordinal word)
nword = 15;
timeorig = comp.time;
time     = comp.time;
for m = 1:nword
  usetrials = true(numel(comp.trial),1);
  for k = 1:numel(comp.trial)
    if numel(xx{k})>=m
      time{k}=timeorig{k}-xx{k}(m);
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

% create a set of matrices that hold potentially interesting independent variables
perpl   = nan(numel(comp.trial),nword);
entr    = nan(numel(comp.trial),nword);
lexfreq = nan(numel(comp.trial),nword);
lb      = nan(numel(comp.trial),nword);
rb      = nan(numel(comp.trial),nword);
w2v     = nan(numel(comp.trial), 320, nword);
nchar   = nan(numel(comp.trial),nword);
dur_v   = nan(numel(comp.trial),nword);
indx    = nan(numel(comp.trial),nword);

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
  
  tmp = [words.perplexity];
  perpl(k,1:nword_here) = tmp;
  tmp = [words.entropy];
  tmp(~isfinite(tmp))= 0;
  entr(k,1:nword_here)  = tmp;
  tmp = [words.lexfreq];
  tmp(~isfinite(tmp))= 1;
  lexfreq(k,1:nword_here) = tmp;
  tmp = [words.leftbranch];
  tmp(~isfinite(tmp))= 1;
  lb(k,1:nword_here) = tmp;
  tmp = [words.rightbranch];
  tmp(~isfinite(tmp))=1;
  rb(k,1:nword_here) = tmp;
  
  dur_v(k,1:nword_here-1) = diff(xx{k});
  dur_v(k,  nword_here)   = min(1,comp.time{k}(end)); % time axis is corrected for last word onset, but occasionally the sentences is way too long, truncate length at 1
  indx(k, 1:nword_here)   = 1:nword_here;
  
  for m = 1:nword_here
    nchar(k,m) = numel(words(m).word{1});
    if isempty(words(m).word2vec)
      words(m).word2vec = zeros(1,320);
    end
  end
  tmp = cat(3,words.word2vec);
  w2v(k,:,1:nword_here) = tmp;
  
  allwords(1:nword_here,k) = keepfields(words,{'POS' 'word' 'duration'})';
end
% reorganize the words
words          = [];
words.word     = [allwords(:).word]';
words.POS      = [allwords(:).POS]';
words.duration = [allwords(:).duration]';


dlb = lb - [zeros(size(lb,1),1) lb(:,1:end-1)];
drb = rb - [zeros(size(rb,1),1) rb(:,1:end-1)];

begtim = -0.1;
endtim = 0.8;
begs = nearest(tmptlck(1).time,begtim);
ends = nearest(tmptlck(1).time,endtim);
N    = ends-begs+1;
tim  = tmptlck(1).time(begs:ends);

Yav = zeros(0,N); % hard coded
Ya  = zeros(0,N);
Yv  = zeros(0,N);
Yall = zeros(0,N*size(tmptlck(1).trial,2));
allX = zeros(0,2);

% loop over ordinal words
sel = false(numel(comp.trial),nword);
for k = 1:numel(tmptlck)
  sel(:,k) = isfinite(lb(:,k)); % indicates the existing words for this position
  
  tmp  = reshape(nanmean(tmptlck(k).trial(:,iv,:),2), [], numel(tmptlck(k).time));
  begs = nearest(tmptlck(k).time,begtim);
  ends = nearest(tmptlck(k).time,endtim);
  nsmp = ends-begs+1;
  tmpY = tmp(:,begs:ends);
  
  tmpY(:,end+1:N) = nan;
  Yv   = cat(1,Yv,tmpY);
  
  tmp  = reshape(nanmean(tmptlck(k).trial(:,ia,:),2), [], numel(tmptlck(k).time));
  tmpY = tmp(:,begs:ends);
  
  tmpY(:,end+1:N) = nan;
  Ya   = cat(1,Ya,tmpY);
  
  tmp  = reshape(nanmean(tmptlck(k).trial(:,:,:),2), [], numel(tmptlck(k).time));
  tmpY = tmp(:,begs:ends);
  
  tmpY(:,end+1:N) = nan;
  Yav   = cat(1,Yav,tmpY);
  
  tmp   = tmptlck(k).trial(:,:,begs:ends);
  tmp(:,:,end+1:N) = nan;
  siz   = size(tmp);
  tmp   = reshape(permute(tmp,[1 3 2]),[siz(1) siz(2)*siz(3)]);
  Yall  = cat(1,Yall,tmp);
end

Yav(~isfinite(Yav)) = 0;
Yv(~isfinite(Yv))   = 0;
Ya(~isfinite(Ya))   = 0;
Yall(~isfinite(Yall)) = 0;

% create design matrix
X               = [nchar(sel(:)) dur_v(sel(:)) lexfreq(sel(:)) indx(sel(:)) perpl(sel(:)) entr(sel(:)) lb(sel(:)) rb(sel(:)) dlb(sel(:)) drb(sel(:))];
X(:,[3 5])      = log10(X(:,[3 5]));
X(~isfinite(X)) = 0;
X      = X - nanmean(X);

tlck = [];
tlck.time         = tim;
tlck.trial(:,1,:) = Yv;
tlck.trial(:,2,:) = Ya;
tlck.trial(:,3,:) = Yav;
tlck.trial(:,3+(1:siz(2)),:) = permute(reshape(Yall,[size(Yall,1) siz(3) siz(2)]),[1 3 2]);
tlck.label  = {'visual';'audio';'both'};
tlck.label = cat(1,tlck.label,comp.label);
tlck.dimord = 'rpt_chan_time';

% embeddings
V = zeros(0,320);
for k = 1:size(w2v,3)
  V = cat(1, V, w2v(sel(:,k),:,k));
end
V = V-mean(V); 

tlck.trialinfo = table(X(:,1), X(:,2), X(:,3), X(:,4),...
  X(:,5), X(:,6), X(:,7), X(:,8),...
  X(:,9), X(:,10),...
  V, words.word, words.POS, cat(1,tmptlck.trialinfo), ...
  'variablenames', {'nchar','duration','loglexfreq','index','logperplexity','entropy','leftbranch','rightbranch','dleftbranch','drightbranch','w2v','word','POS','duration2'});

