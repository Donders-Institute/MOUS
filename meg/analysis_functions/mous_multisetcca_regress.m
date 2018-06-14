function [Y,X,V,ivar,stats,words] = mous_multisetcca_regress(comp, stimuli, folds, cvflag)

lambda = 1;

if nargin<4
  cvflag = false;
end

if nargin > 2 && ~iscell(comp) && ~ft_datatype(comp, 'timelock') && ~cvflag
  cfg = [];
  for k = 1:numel(folds)
    cfg.trials = folds{k};
    tmpcomp    = ft_selectdata(cfg, comp);
    [Y{k},X{k},V{k},ivar,stats(k),words{k}] = mous_multisetcca_regress(tmpcomp, stimuli);
  end
  
  % accumulate the R's and the n's
  % for the different stat fields
  fn = fieldnames(stats(1));
  for m = 1:numel(fn)
    tmp = stats(1).(fn{m});%   X = cat(1,X{:});

    R  = zeros(size(tmp.R));
    R0 = zeros(size(tmp.R0));
    n  = 0;
    p1 = tmp.p1(1);
    p2 = tmp.p2(1);
    
    for k = 1:numel(folds)
      R  = R  + stats(k).(fn{m}).R;
      R0 = R0 + stats(k).(fn{m}).R0;
      n  = n  + stats(k).(fn{m}).n(1);
    end
  
    F = ((R0-R)./(p2-p1))./(R./(n-p2));
    p = 1-fcdf(F, p2-p1, n-p2);
  
    S.(fn{m}).F = F;
    S.(fn{m}).p = p;
    S.(fn{m}).ivar = stats(1).(fn{m}).ivar;
  
  end
  stats = S;
  
  return;
elseif nargin > 2 && iscell(comp)
  % cell input, assumes the data in the first argument, the V in the
  % second, and the X in the third
  for k = 1:numel(comp)
    [Y{k},X{k},V{k},ivar,stats(k)] = mous_multisetcca_regress(comp{k}, stimuli{k}, folds{k});
  end
  % accumulate the R's and the n's
  % for the different stat fields
  fn = fieldnames(stats(1));
  for m = 1:numel(fn)
    tmp = stats(1).(fn{m});%   X = cat(1,X{:});

    R  = zeros(size(tmp.R));
    R0 = zeros(size(tmp.R0));
    n  = 0;
    p1 = tmp.p1(1);
    p2 = tmp.p2(1);
    
    for k = 1:numel(folds)
      R  = R  + stats(k).(fn{m}).R;
      R0 = R0 + stats(k).(fn{m}).R0;
      n  = n  + stats(k).(fn{m}).n(1);
    end
  
    F = ((R0-R)./(p2-p1))./(R./(n-p2));
    %p = nan(size(F));%1-fcdf(F, p2-p1, n-p2);
  
    S.(fn{m}).F = F;
    %S.(fn{m}).p = p;
    S.(fn{m}).ivar = stats(1).(fn{m}).ivar;
  end
  stats = S;
  
  return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% here starts the preparation of the data, if needed
if ~ft_datatype(comp, 'timelock')
  % this is where it is assumed that the relevant word onset related
  % timecourses need to be computed still
  
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
      tlck(m)=ft_timelockanalysis(cfg, comp);
    end
  end
  
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
  begs = nearest(tlck(1).time,begtim);
  ends = nearest(tlck(1).time,endtim);
  N    = ends-begs+1;
  tim  = tlck(1).time(begs:ends);
  
  Yav = zeros(0,N); % hard coded
  Ya  = zeros(0,N);
  Yv  = zeros(0,N);
  Yall = zeros(0,N*size(tlck(1).trial,2));
  allX = zeros(0,2);
  
  % loop over ordinal words
  sel = false(numel(comp.trial),nword);
  for k = 1:numel(tlck)
    sel(:,k) = isfinite(lb(:,k)); % indicates the existing words for this position
    
    tmp  = reshape(nanmean(tlck(k).trial(:,iv,:),2), [], numel(tlck(k).time));
    begs = nearest(tlck(k).time,begtim);
    ends = nearest(tlck(k).time,endtim);
    nsmp = ends-begs+1;
    tmpY = tmp(:,begs:ends);
    
    tmpY(:,end+1:N) = nan;
    Yv   = cat(1,Yv,tmpY);
    
    tmp  = reshape(nanmean(tlck(k).trial(:,ia,:),2), [], numel(tlck(k).time));
    tmpY = tmp(:,begs:ends);
    
    tmpY(:,end+1:N) = nan;
    Ya   = cat(1,Ya,tmpY);
    
    tmp  = reshape(nanmean(tlck(k).trial(:,:,:),2), [], numel(tlck(k).time));
    tmpY = tmp(:,begs:ends);
    
    tmpY(:,end+1:N) = nan;
    Yav   = cat(1,Yav,tmpY);
    
    tmp   = tlck(k).trial(:,:,begs:ends);
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
  X               = [ones(sum(sel(:)),1)./sum(sel(:)) nchar(sel(:)) dur_v(sel(:)) lexfreq(sel(:)) indx(sel(:)) perpl(sel(:)) entr(sel(:)) lb(sel(:)) rb(sel(:)) dlb(sel(:)) drb(sel(:))];
  X(:,[4 6])      = log10(X(:,[4 6]));
  X(~isfinite(X)) = 0;
  X(:,2:end)      = X(:,2:end) - nanmean(X(:,2:end));
  
  
  
  Y.time         = tim;
  Y.trial(:,1,:) = Yv;
  Y.trial(:,2,:) = Ya;
  Y.trial(:,3,:) = Yav;
  Y.trial(:,3+(1:siz(2)),:) = permute(reshape(Yall,[size(Yall,1) siz(3) siz(2)]),[1 3 2]);
  Y.label  = {'visual';'audio';'both'};
  %for k = 1:siz(2)
  %  Y.label{end+1} = sprintf('individual%03d',k);
  %end
  Y.label = cat(1,Y.label,comp.label);
  Y.dimord = 'rpt_chan_time';
  
  V = zeros(0,320);
  for k = 1:size(w2v,3)
    V = cat(1, V, w2v(sel(:,k),:,k));
  end
  V = [ones(size(V,1),1) V-mean(V)]; % add constant regressor
  
  Y.trialinfo = table(X(:,1), X(:,2), X(:,3), X(:,4),...
                      X(:,5), X(:,6), X(:,7), X(:,8),...
                      X(:,9), X(:,10), X(:,11),...
                      V(:,2:end), words.word, words.POS, ...
                      'variablenames', {'const','nchar','duration','loglexfreq','index','logperplexity','entropy','leftbranch','rightbranch','dleftbranch','drightbranch','w2v','word','POS'});
  
  
else
  Y = comp;
  V = stimuli.V;
  X = stimuli.X;
  
  %V = stimuli;
  %X = folds;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ivar = {'const','nchar','duration','loglexfreq','index','logperplexity','entropy','leftbranch','rightbranch','dleftbranch','drightbranch'};
if ~cvflag
  
  %% do the regressions
  [F, R0, R, n, p1, p2, B] = dat2F(Y.trial, V, [], 1);
  stats.w2v.F  = F;
  stats.w2v.R  = R;
  stats.w2v.R0 = R0;
  stats.w2v.p1 = p1;
  stats.w2v.p2 = p2;
  stats.w2v.n  = n;
  stats.w2v.B  = B;
  stats.w2v.ivar = {'w2v'};
  
  % regress out the first 4 columns of X
  y   = V(:,2:end);
  x   = X(:,1:4);
  y   = y-x*((x'*x)\(x'*y));
  Vnew = [x y];
  [F, R0, R, n, p1, p2, B] = dat2F(Y.trial, Vnew, [1 2 3 4], 1);
  stats.w2v_orth.F  = F;
  stats.w2v_orth.R  = R;
  stats.w2v_orth.R0 = R0;
  stats.w2v_orth.p1 = p1;
  stats.w2v_orth.p2 = p2;
  stats.w2v_orth.n  = n;
  stats.w2v_orth.B  = B;
  stats.w2v_orth.ivar = {'w2v'};
  
  clear F R0 R n p1 p2 B;
  for k = 1:size(X,2)-1
    [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(Y.trial,X(:,[1 1+k]));
  end
  
  stats.x.F  = F;
  stats.x.R  = R;
  stats.x.R0 = R0;
  stats.x.p1 = p1;
  stats.x.p2 = p2;
  stats.x.n  = n;
  stats.x.B  = B;
  stats.x.ivar = ivar(2:end);
  
  clear F R0 R n p1 p2 B;
  
  % orthogonalise the design(:,5:end) with respect to the first 4 columns
  y   = X(:,5:end);
  x   = X(:,1:4);
  y   = y-x*((x'*x)\(x'*y));
  Xnew = [x y];
  for k = 1:size(Xnew,2)-4
    %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
    tmpX = Xnew(:,[1 2 3 4 4+k]);
    [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(Y.trial,tmpX,[1 2 3 4]);
  end
  stats.xorth.F  = F;
  stats.xorth.R  = R;
  stats.xorth.R0 = R0;
  stats.xorth.p1 = p1;
  stats.xorth.p2 = p2;
  stats.xorth.n  = n;
  stats.xorth.B  = B;
  stats.xorth.ivar = ivar(5:end);
  
  V = single(V);
  Y = ft_struct2single(Y);
else
  V = normc(V);
  X = normc(X);
  
  
  %% do the regressions
  [F,R0,R] = dat2F(Y.trial, V, [], lambda, folds);
  stats.w2v.dR = F;
  stats.w2v.R0  = R0;
  stats.w2v.R   = R;
  stats.w2v.ivar = {'w2v'};
  
  % regress out the first 4 columns of X
  y   = V(:,2:end);
  x   = X(:,1:4);
  y   = y-x*((x'*x)\(x'*y));
  Vnew = [x y];
  [F,R0,R] = dat2F(Y.trial, Vnew, [1 2 3 4], lambda, folds);
  stats.w2v_orth.dR  = F;
  stats.w2v_orth.R0  = R0;
  stats.w2v_orth.R   = R;
  stats.w2v_orth.ivar = {'w2v'};
  
  clear F R0 R;
  for k = 1:size(X,2)-1
    [F(:,:,k),R0(:,:,k),R(:,:,k)] = dat2F(Y.trial,X(:,[1 1+k]), 1, lambda, folds);
  end
  
  stats.x.dR = F;
  stats.x.R0  = R0;
  stats.x.R   = R;
  stats.x.ivar = ivar(2:end);
  
  clear F R0 R;
  
  % orthogonalise the design(:,5:end) with respect to the first 4 columns
  y   = X(:,5:end);
  x   = X(:,1:4);
  y   = y-x*((x'*x)\(x'*y));
  Xnew = [x y];
  for k = 1:size(Xnew,2)-4
    %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
    tmpX = Xnew(:,[1 2 3 4 4+k]);
    [F(:,:,k),R0(:,:,k),R(:,:,k)] = dat2F(Y.trial,tmpX,[1 2 3 4], lambda, folds);
  end
  stats.xorth.dR = F;
  stats.xorth.R0  = R0;
  stats.xorth.R   = R;
  stats.xorth.ivar = ivar(5:end);
  
  V = single(V);
  Y = ft_struct2single(Y);

end

function [F, R0, R, n, p1, p2, B] = dat2F(alldat, design, col0, lambda, B)

if nargin<3 || isempty(col0)
  col0 = 1;
end

if nargin<4 || isempty(lambda)
  lambda = 0;
end

if nargin<5
  B = [];
end

n  = size(design,1);
p2 = size(design,2);
p1 = numel(col0);

siz = size(alldat);
%dat = reshape(permute(alldat,[1 3 2]),[siz(1) siz(2)*siz(3)]);
dat = reshape(alldat,[siz(1) siz(2)*siz(3)]);
%dat = dat - nanmean(dat,1);
%dat = normc(dat);
if isempty(B)
  if ~lambda
    B   = design\dat;
  else
    B   = ((design'*design+lambda.*eye(size(design,2)))\design')*dat;
  end
elseif iscell(B)
  % assume that B is a cell-array containing the indices of the test-folds.
  for k = 1:numel(B)
    ix = B{k};
    iy = setdiff(1:size(alldat,1),ix);
    [~,  ~, ~, ~, ~, ~, Btmp] = dat2F(alldat(iy,:,:), design(iy,:), col0, lambda); 
    [~, tmpR0, tmpR]          = dat2F(alldat(ix,:,:), design(ix,:), col0, lambda, Btmp); 
    if k==1
      R0 = tmpR0.*numel(ix);
      R  =  tmpR.*numel(ix);
      n  =        numel(ix);
    else
      R0 = tmpR0.*numel(ix) + R0;
      R  = tmpR .*numel(ix) + R;
      n  =        numel(ix) + n;
    end
  end
  F = (R0-R)./R;
  return;
else
  % use the pre-supplied weights
  %B = reshape(permute(B, [1 3 2]), [size(B,1) size(B,2)*size(B,3)]);
  B = reshape(B, [size(B,1) size(B,2)*size(B,3)]);

end

R0 = reshape(sum((dat-design(:,col0)*B(col0,:)).^2),[siz(2) siz(3)]);
R  = reshape(sum((dat-design*B).^2),[siz(2) siz(3)]);

F  = ((R0-R)./(p2-p1))./(R./(n-p2));
%B  = permute(reshape(B,[size(B,1) siz(3) siz(2)]),[1 3 2]);
B  = reshape(B,[size(B,1) siz(2) siz(3)]);
