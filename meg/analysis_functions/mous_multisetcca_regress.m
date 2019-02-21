function stats = mous_multisetcca_regress(tlck, design, varargin)
%This function models timelocked data with a GLM given some predictors in variable
%design, and does a model comparison against a reduced model where the
%reduced model can be defined with the key 'modelcomparison' (default is to
%compare only first predictor against rest). If specified, constant will be
%added post orthogonalisation.
folds               = ft_getopt(varargin, 'folds',      []);
outerfolds          = ft_getopt(varargin, 'outerfolds', folds);
innerfolds          = ft_getopt(varargin, 'innerfolds', folds);
lambda              = ft_getopt(varargin, 'lambda', 0);
ortho               = ft_getopt(varargin, 'ortho', {});
contentwords_only   = ft_getopt(varargin, 'contentwords_only', false);
reduceto            = ft_getopt(varargin, 'modelcomparison', 'constant');
constant            = ft_getopt(varargin, 'constant', false);
normalise           = ft_getopt(varargin, 'normalise', false);
balancefolds        = ft_getopt(varargin, 'balancefolds', false);

ivarnames = design.Properties.VariableNames;
if constant
  % check whether the design table contains a constant. If not, add it
  if ~any(ismember(ivarnames, 'constant'))
    design = cat(2,array2table(ones(757,1),'VariableNames', {'constant'}),design);
    ivarnames = design.Properties.VariableNames;
  end
end

if iscellstr(ortho)
  indx = find(ismember(design.Properties.VariableNames,ortho));
  if length(indx) == length(ortho)
    ortho = indx;
  else
    ft_warning('variables for orthogonalising not present in design matrix')
    return
  end
else
  if max(ortho) >= size(design,2)
    ft_warning('mismatch between design matrix and ortho parameters')
    return
  end
end

if ~iscellstr(reduceto)
  if isnumeric(reduceto)
    error('numeric indices for regressors to do modelcomparison are not supported anymore');
  end
  reduceto = {reduceto};
end

indxvec = cell(1,numel(ivarnames));
cnt = 0;
for k = 1:numel(ivarnames)
  indxvec{k} = cnt+(1:size(design.(ivarnames{k}),2));
  cnt = indxvec{k}(end);
end

ivarnames0 = reduceto;
indx = find(ismember(design.Properties.VariableNames,reduceto));
if length(indx) == length(reduceto)
  reduceto = cell2mat(indxvec(indx));
else
  warning('one or more variables for model comparison not present in design matrix')
end

if contentwords_only
  % identify the nouns, adjectives and verbs
  sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
  
  cfg        = [];
  cfg.trials = find(sel);
  tlck       = ft_selectdata(cfg, tlck);
  
  design     = design(sel>0,:);
end

if ~iscell(outerfolds) && ~isempty(outerfolds)
  outerfolds = mous_makefolds(size(tlck.trial,1), outerfolds, balancefolds,design);
end
if iscell(outerfolds) && numel(lambda)>1 && ~iscell(innerfolds) && ~isempty(innerfolds)
  fprintf('creating partitioning of data for nested cross-validation\n');
  
  for m = 1:numel(outerfolds)
    tmpfolds{m} = mous_makefolds(size(tlck.trial,1)-numel(outerfolds{m}), innerfolds);
  end
  innerfolds = tmpfolds;
elseif iscell(outerfolds) && numel(lambda)==1
  if ~iscell(innerfolds)
    innerfolds = cell(size(outerfolds));
  end
  for k = 1:numel(outerfolds)
    innerfolds{k} = [];
  end
end

if ~isempty(ortho)
  [~, n] = size(ortho);
  y   = table2array(design(:,setdiff(1:size(design,2),ortho)));
  x   = table2array(design(:,ortho));
  y   = y-x*((x'*x)\(x'*y));
  design = [x y];
  %permute design to ensure original order of predictors
  order           = 1:size(design,2);
  neworder(ortho) = order(1:n);
  neworder(setdiff(order,ortho)) = order(n+1:end);
  design = design(:,neworder);
  clear y x
else
  
  design = cell2mat(table2cell(design));
end

if normalise
  design = normc(design);
end

%% do the regressions
output = doregression(tlck.trial, design, 'col0', reduceto, 'lambda', lambda, 'outerfolds', outerfolds, 'innerfolds', innerfolds, 'output', {'Rsq', 'B'});

if numel(output)>1
  stats.Rsq = mean(cat(3,output.Rsq),3);
  stats.B   = cat(4,output.B);
  stats.B0  = cat(4,output.B0);
  stats.ivar = ivarnames;
  stats.ivar0 = ivarnames0;
else
  stats.Rsq = output.Rsq;
  stats.B   = output.B;
  stats.B0  = output.B0;
  stats.ivar = ivarnames;
  stats.ivar0 = ivarnames0;
end
if isfield(output, 'lambda')
  stats.lambda = output(1).lambda;
end

%FIXME: maybe we want an option for iteratively doing the model comparison?
%adding one predictor at a time as seems to have been done before?
%   for k = 1:size(Xnew,2)-4
%     %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
%     tmpX = Xnew(:,[1 2 3 4 4+k]);
%     [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = doregression(tlck.trial,tmpX,[1 2 3 4]);
%   end


function output = doregression(alldat, design, varargin)

col0   = ft_getopt(varargin, 'col0', 1); % assume the first column in the design to be a constant
lambda = ft_getopt(varargin, 'lambda', []);
B      = ft_getopt(varargin, 'B',  []);
B0     = ft_getopt(varargin, 'B0', []);
innerfolds = ft_getopt(varargin, 'innerfolds', []);
outerfolds = ft_getopt(varargin, 'outerfolds', []);
outputargs = ft_getopt(varargin, 'outputargs', {'Rsq' 'B' 'B0' 'R' 'R0'});

computeweights = isempty(B) && any(ismember(outputargs, 'B'));
computeRsq     = any(ismember(outputargs, 'Rsq'));
computeR       = any(ismember(outputargs, 'R'));
computeR0      = any(ismember(outputargs, 'R0'));
if computeR || computeR0
  computeweights = true;
end

n  = size(design,1);
p2 = size(design,2);
p1 = numel(col0);

% assume data and design to be properly scaled in order to avoid numerical
% issues, also the mean should be dealt with by means of an explicit
% regressor in the design (or the data should be demeaned)

siz = size(alldat);
dat = reshape(alldat,[siz(1) siz(2)*siz(3)]);
if ~isempty(outerfolds)
  % do an outer fold cross validation
  if isempty(innerfolds)
    innerfolds = cell(size(outerfolds));
  end
  for k = 1:numel(outerfolds)
    if numel(lambda)==1 && ~isempty(innerfolds{k})
      error('nested cross-validation is not possible with just a single value for the hyperparameter');
    end
    
    ix = outerfolds{k};
    iy = setdiff(1:size(alldat,1),ix);
    
    % for the given outer fold, compute the performance statistic, which
    % can be computed across several values of the hyperparameter
    if numel(lambda)==1
      % speed things up a bit by not computing a lot of unnecessary junk
      tmp       = doregression(alldat(iy,:,:), design(iy,:), 'col0', col0, 'lambda', lambda, 'innerfolds', innerfolds{k});
      output(k) = doregression(alldat(ix,:,:), design(ix,:), 'col0', col0, 'lambda', lambda, 'B', tmp.B, 'B0', tmp.B0);
    else
      
      for m = 1:numel(lambda)
        tmp         = doregression(alldat(iy,:,:), design(iy,:), 'col0', col0, 'lambda', lambda(m), 'innerfolds', innerfolds{k});
        output(k,m) = doregression(alldat(ix,:,:), design(ix,:), 'col0', col0, 'lambda', lambda(m), 'B', tmp.B, 'B0', tmp.B0);
      end
    end
  end
  
  if numel(lambda)>1
    % select the values that optimise the Rsq in the inner
    % cross-validation loop
    Rsq = squeeze(mean(reshape(cat(3, output.Rsq), [size(output(1).Rsq) size(output)]),3));
    
    Lout = zeros(size(output(1).Rsq))-inf;
    [mR, ixR] = max(Rsq,[],3);
    newoutput = output(:,1);
    for k = 1:numel(newoutput)
      newoutput(k).B(:)   = nan;
      newoutput(k).B0(:)  = nan;
      newoutput(k).Rsq(:) = nan;
      for m = unique(ixR(:))'
        Lout(ixR==m) = lambda(m);
        newoutput(k).B(:,ixR==m) = output(k,m).B(:,ixR==m);
        newoutput(k).B0(:,ixR==m) = output(k,m).B0(:,ixR==m);
        newoutput(k).Rsq(ixR==m) = output(k,m).Rsq(ixR==m);
      end
      newoutput(k).lambda = Lout;
    end
    output = newoutput; 
    
  end
  return;
  
elseif isempty(B)
  % compute the regression weights
  if (~iscell(lambda) && numel(lambda)==1 && lambda==0) || isempty(lambda)
    % do an unregularized regression
    B   = design\dat;
    B0  = design(:,col0)\dat;
  elseif ~isempty(innerfolds)
    % do a nested cross-validation keeping the performance metric as an aggregate across
    % inner folds for each value of the hyperparameter lambda, recursing
    % into doregression
    for m = 1:numel(innerfolds)
      ix = innerfolds{m};
      iy = setdiff(1:size(alldat,1),ix);
      tmp       = doregression(alldat(iy,:,:), design(iy,:), 'col0', col0, 'lambda', lambda);
      output(m) = doregression(alldat(ix,:,:), design(ix,:), 'col0', col0, 'lambda', lambda, 'B', tmp.B, 'B0', tmp.B0);  
    end
    R  = cat(3,output.R);
    R0 = cat(3,output.R0);
    n  = cat(3,output.n);
    Rsq = 1-sum(R.*n,3)./sum(R0.*n,3);
    
    % compute the weights across all observations for the current lambda
    output = doregression(alldat, design, 'col0', col0, 'lambda', lambda);    
    output.Rsq = Rsq; % keep the aggregated quality metric.
    
    return;
  elseif isempty(innerfolds)
    B  = ((design'*design+lambda.*eye(size(design,2)))\design')*dat;
    B0 = ((design(:,col0)'*design(:,col0)+lambda.*eye(numel(col0)))\design(:,col0)')*dat; 
  elseif iscell(lambda)
    % this is the case when each of the samples has its own lambda
    lambda = lambda{1}(:);
    B  = nan(size(design,2),size(dat,2));
    B0 = nan(numel(col0), size(dat,2));
    U = unique(lambda);
   
    for m = 1:numel(U)
      
      B(:,lambda==U(m))  = ((design'*design+U(m).*eye(size(design,2)))\design')*dat(:,lambda==U(m));
      B0(:,lambda==U(m)) = ((design(:,col0)'*design(:,col0)+U(m).*eye(numel(col0)))\design(:,col0)')*dat(:,lambda==U(m));
      
    end
  else
    % compute the regression weights given a fixed value of lambda
    B   = ((design'*design+lambda.*eye(size(design,2)))\design')*dat;
    B0  = ((design(:,col0)'*design(:,col0)+lambda.*eye(numel(col0)))\design(:,col0)')*dat;
  end
else
  B  = reshape(B,  [size(B,1)  siz(2)*siz(3)]);
  B0 = reshape(B0, [size(B0,1) siz(2)*siz(3)]);
end

output.n = siz(1);
output.lambda = lambda;
if computeR0
  output.R0 = reshape(sum((dat-design(:,col0)*B0).^2),[siz(2) siz(3)]);
end
if computeR
  output.R  = reshape(sum((dat-design*B).^2),[siz(2) siz(3)]);
end
if computeweights
  output.B  = reshape(B,[size(B,1) siz(2) siz(3)]);
  output.B0 = reshape(B0, [size(B0,1) siz(2) siz(3)]);
end
if computeRsq
  if exist('F', 'var')
    output.Rsq = F;
  else
    output.Rsq = (output.R0-output.R)./output.R0;
  end
end

