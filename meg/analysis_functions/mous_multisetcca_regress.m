function stats = mous_multisetcca_regress(tlck, stimuli, folds, cvflag)

lambda = 1;

if nargin<3
  cvflag = false;
end

if nargin > 2 && iscell(tlck)
  % cell input, assumes the data in the first argument, the V in the
  % second, and the X in the third
  for k = 1:numel(tlck)
    [Y{k},X{k},V{k},ivar,stats(k)] = mous_multisetcca_regress(tlck{k}, stimuli{k}, folds{k});
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


ivar = tlck.trialinfo.Properties.VariableNames;
if ~cvflag
  
  %% do the regressions
  [F, R0, R, n, p1, p2, B] = dat2F(tlck.trial, tlck.trialinfo.w2v, [], 1);
  stats.w2v.F  = F;
  stats.w2v.R  = R;
  stats.w2v.R0 = R0;
  stats.w2v.p1 = p1;
  stats.w2v.p2 = p2;
  stats.w2v.n  = n;
  stats.w2v.B  = B;
  stats.w2v.ivar = {'w2v'};
  
  % regress out the first 4 columns of X
  y   = tlck.trialinfo.w2v(:,2:end);
  x   = table2array(tlck.trialinfo(:,1:4));
  y   = y-x*((x'*x)\(x'*y));
  Vnew = [x y];
  [F, R0, R, n, p1, p2, B] = dat2F(tlck.trial, Vnew, [1 2 3 4], 1);
  stats.w2v_orth.F  = F;
  stats.w2v_orth.R  = R;
  stats.w2v_orth.R0 = R0;
  stats.w2v_orth.p1 = p1;
  stats.w2v_orth.p2 = p2;
  stats.w2v_orth.n  = n;
  stats.w2v_orth.B  = B;
  stats.w2v_orth.ivar = {'w2v'};
  
  clear F R0 R n p1 p2 B;
  for k = 1:size(tlck.trialinfo(:,1:end-4),2)-1 %without POS and word, duration or w2v
    [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(tlck.trial,table2array(tlck.trialinfo(:,[1 1+k])));
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

%FIXME: add option 'orthogonalise' with two parameters given the columsn to
%orthogonalise and the columns which to use for it
%   % orthogonalise the design(:,5:end) with respect to the first 4 columns
%   y   = X(:,5:end);
%   x   = X(:,1:4);
%   y   = y-x*((x'*x)\(x'*y));
%   Xnew = [x y];
%   for k = 1:size(Xnew,2)-4
%     %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
%     tmpX = Xnew(:,[1 2 3 4 4+k]);
%     [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(tlck.trial,tmpX,[1 2 3 4]);
%   end
%   stats.xorth.F  = F;
%   stats.xorth.R  = R;
%   stats.xorth.R0 = R0;
%   stats.xorth.p1 = p1;
%   stats.xorth.p2 = p2;
%   stats.xorth.n  = n;
%   stats.xorth.B  = B;
%   stats.xorth.ivar = ivar(5:end);
else
  V = normc(tlck.trialinfo.w2v);
  X = normc(table2array(tlck.trialinfo(:,1:11)));
  
  
  %% do the regressions
  [F,R0,R] = dat2F(tlck.trial, V, [], lambda, folds);
  stats.w2v.dR = F;
  stats.w2v.R0  = R0;
  stats.w2v.R   = R;
  stats.w2v.ivar = {'w2v'};
  
  % regress out the first 4 columns of X
  y   = V(:,2:end);
  x   = X(:,1:4);
  y   = y-x*((x'*x)\(x'*y));
  Vnew = [x y];
  [F,R0,R] = dat2F(tlck.trial, Vnew, [1 2 3 4], lambda, folds);
  stats.w2v_orth.dR  = F;
  stats.w2v_orth.R0  = R0;
  stats.w2v_orth.R   = R;
  stats.w2v_orth.ivar = {'w2v'};
  
  clear F R0 R;
  for k = 1:size(X,2)-1
    [F(:,:,k),R0(:,:,k),R(:,:,k)] = dat2F(tlck.trial,X(:,[1 1+k]), 1, lambda, folds);
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
    [F(:,:,k),R0(:,:,k),R(:,:,k)] = dat2F(tlck.trial,tmpX,[1 2 3 4], lambda, folds);
  end
  stats.xorth.dR = F;
  stats.xorth.R0  = R0;
  stats.xorth.R   = R;
  stats.xorth.ivar = ivar(5:end);
  
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
