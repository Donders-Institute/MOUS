function stats = mous_multisetcca_regress(tlck, design, stimuli, folds, varargin)

lambda              = 1;
ortho               = ft_getopt(varargin, 'orthogonalise', {});
contentwords_only   = ft_getopt(varargin, 'contentwords_only', false);
reduceto            = ft_getopt(varargin, 'modelcomparison', []);

if nargin<2
  folds = [];
end

if iscellstr(ortho)
    indx = find(ismember(tlck.trialinfo.Properties.VariableNames,ortho));
    if length(indx) == length(ortho)
        ortho = indx;
    else
        %FIXME:test if displays correctly
        warning('variables for orthogonalising not present in design matrix')
    end
else 
    if max(ortho) >= size(tlck.trialinfo,2)
         warning('mismatch between design matrix and other parameters')
    end
end

if iscellstr(reduceto)
    indx = find(ismember(tlck.trialinfo.Properties.VariableNames,reduceto));
    if length(indx) == length(reduceto)
        reduceto = indx;
    else
        %FIXME:test if displays correctly
        warning('variables for orthogonalising not present in design matrix')
    end
else 
    if max(reduceto) >= size(tlck.trialinfo,2) && length(reduceto) < size(tlck.trialinfo,2)
         warning('mismatch between design matrix and other parameters')
    end
end

if contentwords_only
  % identify the nouns, adjectives and verbs
  sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
  
%   % select these from the data
%   words.POS      = words.POS(sel>0);
%   words.duration = words.duration(sel>0);
%   words.word     = words.word(sel>0);
%   
  cfg        = [];
  cfg.trials = find(sel);
  tlck        = ft_selectdata(cfg, tlck);
end


if nargin > 2 && iscell(tlck)
  % cell input, assumes the data in the first argument, the V in the
  % second, and the X in the third
  for k = 1:numel(tlck)
    stats(k) = mous_multisetcca_regress(tlck{k}, stimuli{k}, folds{k});
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

else
  
  if ~isempty(ortho)
  %FIXME: if columns used for ortho are not the last ones, appending them
  %afterwards will change order and therefore reduceto might be wrongly
  %mapped
  %FIXME: also if constant present, it will be orthogonalized
  y   = table2array(design(:,setdiff(1:size(design,2),ortho)));
  x   = table2array(design(:,ortho));
  y   = y-x*((x'*x)\(x'*y));
  design = [x y];  
  clear y x
  end
  
  %% do the regressions
  [F, R0, R, n, p1, p2, B] = dat2F(tlck.trial, design, reduceto, folds);
  stats.F  = F;
  stats.R  = R;
  stats.R0 = R0;
  stats.p1 = p1;
  stats.p2 = p2;
  stats.n  = n;
  stats.B  = B;
  stats.ivar = tlck.trialinfo.Properties.VariableNames;

%FIXME: maybe we want an option for iteratively doing the model comparison?
%adding one predictor at a time as seems to have been done before?
%   for k = 1:size(Xnew,2)-4
%     %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
%     tmpX = Xnew(:,[1 2 3 4 4+k]);
%     [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(tlck.trial,tmpX,[1 2 3 4]);
%   end

%FIXME:when is the normalisation needed??
%   V = normc(tlck.trialinfo.w2v);
%   X = normc(table2array(tlck.trialinfo(:,1:11)));
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
