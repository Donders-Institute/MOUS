function stats = mous_multisetcca_regress(tlck, design, varargin)

% This function models timelocked data with a GLM given some predictors in variable
% design, and does a model comparison against a reduced model where the
% reduced model can be defined with the key 'modelcomparison' (default is to
% compare only first predictor against rest). If specified, a constant will be
% added to the design (if not present). The input design should be a table object.

outerfolds          = ft_getopt(varargin, 'outerfolds', []);
innerfolds          = ft_getopt(varargin, 'innerfolds', []);
lambda              = ft_getopt(varargin, 'lambda', 0);
ortho               = ft_getopt(varargin, 'ortho', {});
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

% orthogonalise and convert table object to matrix
% FIXME ortho should be defined as 'ivar' names
% not column indices
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

% z-score the design
if normalise
  design = normc(design);
end

% create cell-array with trial indices for outer folds
if ~iscell(outerfolds) && ~isempty(outerfolds)
  fprintf('creating outer fold partitioning of data for cross-validation\n');
  outerfolds = mous_makefolds(size(tlck.trial,1), outerfolds, balancefolds, design);
elseif isempty(outerfolds)
  outerfolds = {1:size(tlck.trial,1)};
else
  error('unsupported specification of outerfolds');
end

% create cell-array with trial indices for inner folds, if necessary
if numel(lambda)>1 && ~iscell(innerfolds) && ~isempty(innerfolds)
  fprintf('creating inner fold partitioning of data for nested cross-validation\n');
  tmpfolds = cell(1,numel(outerfolds));
  for m = 1:numel(outerfolds)
    ix = outerfolds{m};
    iy = setdiff(1:size(tlck.trial,1),ix);
    tmpfolds{m} = mous_makefolds(size(tlck.trial,1)-numel(outerfolds{m}), innerfolds, balancefolds, design(iy,:));
  end
  innerfolds = tmpfolds;
elseif iscell(outerfolds) && numel(lambda)==1
  if ~iscell(innerfolds)
    innerfolds = cell(size(outerfolds));
  end
  for k = 1:numel(outerfolds)
    innerfolds{k} = {nan};
  end
end

% do the regression
siz = size(tlck.trial);
dat = reshape(tlck.trial,[siz(1) siz(2)*siz(3)]);

% do a nested for-loop for the computation of the model coefficients for
% the training data and the model fits for the inner loop test data
Rin   = zeros(siz(2)*siz(3),numel(outerfolds),numel(innerfolds{1}),numel(lambda));
R0in  = zeros(siz(2)*siz(3),numel(outerfolds),numel(innerfolds{1}),numel(lambda));
Rout  = zeros(siz(2)*siz(3),numel(outerfolds));
R0out = zeros(siz(2)*siz(3),numel(outerfolds));
nin   = zeros(numel(innerfolds{1}),1);
for i_out = 1:numel(outerfolds)
  out_test     = outerfolds{i_out};
  dat_test     = dat(out_test,:);
  design_test  = design(out_test,:);
  
  out_train    = setdiff(1:siz(1),out_test);
  dat_train    = dat(out_train,:);
  design_train = design(out_train,:);
  for i_in = 1:numel(innerfolds{i_out})
    
    if ~isfinite(innerfolds{i_out}{i_in})
      dat_test_in     = dat_test;
      design_test_in  = design_test;
      
      dat_train_in    = dat_train;
      design_train_in = design_train;
      
      nin(i_in,1) = size(dat_test_in,1);
    else
      in_test         = innerfolds{i_out}{i_in};
      dat_test_in     = dat_train(in_test,:);
      design_test_in  = design_train(in_test,:);
      
      in_train        = setdiff(1:size(dat_train,1),in_test);
      dat_train_in    = dat_train(in_train,:);
      design_train_in = design_train(in_train,:);
      
      nin(i_in,1) = numel(innerfolds{i_out}{i_in});
    end
    design_cov     = design_train_in'*design_train_in;
    design_reduced = design_train_in(:,reduceto)'; % transpose and select columns only once
    for i_lambda = 1:numel(lambda)
      design_cov_reg = design_cov + lambda(i_lambda).*eye(size(design_train_in,2));
      
      % compute the regression weights given a fixed value of lambda
      B   = (design_cov_reg\design_train_in')*dat_train_in;
      B0  = (design_cov_reg(reduceto,reduceto)\design_reduced)*dat_train_in;
      
      % compute the model fit for the test data
      Rin(: , i_out, i_in, i_lambda) = sum((dat_test_in - design_test_in            * B ).^2);
      R0in(:, i_out, i_in, i_lambda) = sum((dat_test_in - design_test_in(:,reduceto)* B0).^2);
    end
  end
end
Rsq_this = squeeze(mean(mean(1-Rin./R0in,3),2));

if numel(lambda)>1
  % for each sample in this fold take the lambda value that optimizes
  % Rsq: this requires recomputation of the model
  [~, idx] = max(Rsq_this, [], 2);
  
  B(:)  = nan;
  B0(:) = nan;
  for i_out = 1:numel(outerfolds)
    for i_lambda = 1:numel(lambda)
      design_cov_reg = design_train'*design_train + lambda(i_lambda).*eye(size(design_train,2));
      
      % compute the regression weights given a fixed value of lambda
      B(:,idx==i_lambda)  = (design_cov_reg\design_train')*dat_train(:,idx==i_lambda);
      B0(:,idx==i_lambda) = (design_cov_reg(reduceto,reduceto)\design_train(:,reduceto)')*dat_train(:,idx==i_lambda);
    end
    
    % compute the model fit for the test data
    Rout(:,  i_out) = sum((dat_test - design_test            * B ).^2);
    R0out(:, i_out) = sum((dat_test - design_test(:,reduceto)* B0).^2);
  end
else
  Rout  = squeeze(sum(R_this, 3));
  R0out = squeeze(sum(R0_this, 3));
end
Rsq = mean(1 - Rout./R0out,2);

stats.Rsq   = reshape(Rsq, [siz(2) siz(3)]);
stats.ivar  = ivarnames;
stats.ivar0 = ivarnames0;
