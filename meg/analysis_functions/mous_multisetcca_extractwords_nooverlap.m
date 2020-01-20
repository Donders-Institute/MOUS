function [tlck, Trl_idx, model_visual, model_audio] = mous_multisetcca_extractwords_nooverlap(comp, stimuli)

isaudio = false(numel(comp.label),1);
for k = 1:numel(comp.label)
  isaudio(k) = strcmp(comp.label{k}(end-3),'2');
end
iv = (~isaudio);
ia = ( isaudio);

xx = cell(numel(comp.trial),1);
for k = 1:numel(comp.trial)
  xx{k}=stimuli(comp.trialinfo(k,end)).timinginfo_visual(:,2);
  yy{k}=stimuli(comp.trialinfo(k,end)).timinginfo(1:end,2);
  yy{k}=yy{k}-yy{k}(1);
  
end

% split audio and visual modalities for the time being
cfg = [];
cfg.channel = comp.label(iv);
compvisual  = ft_selectdata(cfg, comp);
cfg.channel = comp.label(ia);
compaudio   = ft_selectdata(cfg, comp);


% remove the overlapping segments for the audio data again, and stitch it
% back together
trial = cell(1,numel(compaudio.trial));
for k = 1:numel(compaudio.trial)
  tim_v = xx{k};
  tim_a = yy{k}; 
  nword = numel(tim_v);
  begs = zeros(nword,1);
  ends = zeros(nword,1);
  for m = 1:nword-1
    begs(m+1,1) = nearest(compaudio.time{k}, tim_v(m+1));
    ends(m,1)   = nearest(compaudio.time{k}, tim_v(m)+(tim_a(m+1)-tim_a(m)));
  end
  begs(1)   = 1;
  ends(end) = size(compaudio.trial{k},2);
  
  trial{k} = compaudio.trial{k}(:,begs(1):ends(1));
  maxcorr{k,1}(1,1) = 1;
  for m = 2:nword
    % extract two selections from this trial, which should be more or less
    % overlapping initially, give or take a single sample shift
    
    % it could be that the cross correlation does not work well, if the
    % corresponding length of the auditory word is only a few samples,
    % so constrain the number of samples to-be-compared to the length of
    % of the audio word.
    nsmp = min(floor(compaudio.fsample.*(yy{k}(m+1)-yy{k}(m))),25);
    tmp1 = nanmean(compaudio.trial{k}(:,begs(m)+(1:nsmp)));
    tmp2 = nanmean(compaudio.trial{k}(:,ends(m-1)+(1:nsmp)));
    
    tmp1(~isfinite(tmp1))=0;
    tmp2(~isfinite(tmp2))=0;
    
    [c,lags] = xcorr(tmp1,tmp2,5,'coeff');
    [maxcorr{k,1}(m,1),shift] = max(c);
    if maxcorr{k,1}(m,1)<0.6
      searchrange = -abs(lags(shift)):abs(lags(shift));
      ok = false(1,numel(searchrange));
      for kk = 1:numel(searchrange)
        ix_kk = searchrange(kk);
        if ix_kk<=0
          ok(kk) = isequal(tmp1(1:5),tmp2((1:5)-ix_kk));
        else
          ok(kk) = isequal(tmp1((1:5)+ix_kk),tmp2(1:5)); 
        end
      end
      if any(ok)
        shift = searchrange(ok); % this is needed to be consistent
      else
        if begs(m)<ends(m-1)
          %keyboard
          shift = 0;
        end
      end
    else
      shift = lags(shift);
    end
    begs(m) = begs(m)+shift;
    
    trial{k} = cat(2,trial{k},compaudio.trial{k}(:,begs(m):ends(m)));    
  end
end

time = cell(1,numel(trial));
for k = 1:numel(trial)
  time{k} = compaudio.time{k}(1:size(trial{k},2));
  stim    = stimuli(compaudio.trialinfo(k,end));
  
  % content words have wordtype [1 3 4]
  cw   = ismember(stim.wordtype, [1 3 4]);
  dum  = zeros(2,size(trial{k},2));
  for m = 1:numel(yy{k})-1
    if cw(m)
      dum(1,nearest(time{k},yy{k}(m))) = 1;
    else
      dum(2,nearest(time{k},yy{k}(m))) = 1;
    end  
  end
  
  stim = stimuli(compvisual.trialinfo(k,end));
  cw   = ismember(stim.wordtype, [1 3 4]);
  dum2 = zeros(2,size(compvisual.trial{k},2));
  for m = 1:numel(xx{k})
    if cw(m)
      dum2(1,nearest(compvisual.time{k},xx{k}(m))) = 1;
    else
      dum2(2,nearest(compvisual.time{k},xx{k}(m))) = 1;
    end  
  end
  
  trial{k} = cat(1,trial{k},dum);
  compvisual.trial{k} = cat(1, compvisual.trial{k}, dum2);
end
compaudio.trial = trial;
compaudio.time  = time;
compaudio.label{end+1} = 'stimon_cw';
compaudio.label{end+1} = 'stimon_fw';
compvisual.label{end+1} = 'stimon_cw';
compvisual.label{end+1} = 'stimon_fw';

cfg            = [];
cfg.refchannel = {'stimon_cw'; 'stimon_fw'};
cfg.reflags    = (-12:96)./120;
cfg.demeanrefdata = true;
cfg.perchannel    = 'yes';
cfg.output = 'residual'; 
compaudio  = ft_denoise_tsr(cfg, compaudio);
compvisual = ft_denoise_tsr(cfg, compvisual);

for k = 1:numel(yy)
  yy{k} = yy{k}(1:end-1);
end

cfg         = [];
cfg.channel = compaudio.label(1:end-2);
compaudio   = ft_selectdata(cfg, compaudio);
cfg.channel = compvisual.label(1:end-2);
compvisual  = ft_selectdata(cfg, compvisual);

tlckaudio  = comp2tlck(compaudio,  stimuli, yy);
[tlckvisual, Trl_idx] = comp2tlck(compvisual, stimuli, xx);
% at this level the trialinfo should be identical for the relevant
% quantities (it only differs for duration, per construction)
assert(isequal(tlckaudio.trialinfo.w2v, tlckvisual.trialinfo.w2v));

tlck = tlckvisual;
tlck.trial = cat(2, tlckvisual.trial, tlckaudio.trial(:,4:end,:));
tlck.label = cat(1, tlckvisual.label, tlckaudio.label(4:end));
tlck.trial(:,2,:) = tlckaudio.trial(:,2,:);
tlck.trial(:,3,:) = nan;

model_visual = compvisual.weights;
model_audio  = compaudio.weights;

%------------------------------------------------------
% subfunction (clunky) to convert 'raw' representation
% into 'tlck' with onsets specified by 'xx'
function [tlck, Trl_idx] = comp2tlck(comp, stimuli, xx)

isaudio = false(numel(comp.label),1);
for k = 1:numel(comp.label)
  isaudio(k) = strcmp(comp.label{k}(end-3),'2');
end
iv = (~isaudio);
ia = ( isaudio);

% set up cfg for ft_timelockanalysis to grab the word onset locked data
cfg              = [];
cfg.keeptrials   = 'yes';

% create the event-locked structure array (as a function of ordinal word)
nword = 15;
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
allwords = allwords'; %to order according to ordinal word position not trials
words          = [];
words.word     = [allwords(:).word]';
words.POS      = [allwords(:).POS]';
words.duration = [allwords(:).duration]';


dlb = lb - [zeros(size(lb,1),1) lb(:,1:end-1)];
drb = rb - [zeros(size(rb,1),1) rb(:,1:end-1)];

begtim  = -0.1;
endtim  = 0.8;
fsample = mean(diff(tmptlck(1).time));
tim     = linspace(begtim,endtim,0.9.*120+1);
N       = numel(tim);

Yav = zeros(0,N); % hard coded
Ya  = zeros(0,N);
Yv  = zeros(0,N);
Yall = zeros(0,N*size(tmptlck(1).trial,2));
allX = zeros(0,2);

% loop over ordinal words
sel = false(numel(comp.trial),nword);
for k = 1:numel(tmptlck)
  sel(:,k) = isfinite(lb(:,k)); % indicates the existing words for this position
  
  begs = nearest(tmptlck(k).time,begtim);
  ends = nearest(tmptlck(k).time,endtim);
  nsmp = ends-begs+1;
  
  if any(iv)
  tmp  = reshape(nanmean(tmptlck(k).trial(:,iv,:),2), [], numel(tmptlck(k).time));
  tmpY = tmp(:,begs:ends);
  
  tmpY(:,end+1:N) = nan;
  Yv   = cat(1,Yv,tmpY);
  end
  
  if any(ia)
  tmp  = reshape(nanmean(tmptlck(k).trial(:,ia,:),2), [], numel(tmptlck(k).time));
  tmpY = tmp(:,begs:ends);
  end
  
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

% create design matrix
X               = [nchar(sel(:)) dur_v(sel(:)) lexfreq(sel(:)) indx(sel(:)) perpl(sel(:)) entr(sel(:)) lb(sel(:)) rb(sel(:)) dlb(sel(:)) drb(sel(:))];
X(:,[3 5])      = log10(X(:,[3 5]));
X(~isfinite(X)) = 0;
%X      = X - nanmean(X);

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
  V, words.word, words.POS, cat(1,tmptlck.trialinfo), Trl_idx(:,1), Trl_idx(:,2),...
  'variablenames', {'nchar','duration','loglexfreq','index','logperplexity','entropy','leftbranch','rightbranch','dleftbranch','drightbranch','w2v','word','POS','duration2','id','ordinal'});

