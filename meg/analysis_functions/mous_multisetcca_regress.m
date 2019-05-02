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
nrepeat             = ft_getopt(varargin, 'nrepeat', 1);
generalize          = ft_getopt(varargin, 'generalize', false);

if nrepeat>1
  sel = find(strcmp(varargin, 'nrepeat'));
  varargin{sel+1} = 1;
  for k = 1:nrepeat
    tmp(k) = mous_multisetcca_regress(tlck, design, varargin{:});
  end
  stats = tmp(1);
  if ~generalize
    stats.Rsq = mean(cat(3,tmp.Rsq),3);
  else
    stats.Rsq = mean(cat(4,tmp.Rsq),4);
  end
  if isfield(stats, 'lambda')
    stats.lambda = mean(cat(3,tmp.lambda),3);
  end
  return;
end

if generalize
  assert(isempty(outerfolds)||(numel(outerfolds)==1&&outerfolds==1));
end

ivarnames = design.Properties.VariableNames;
if constant
  % check whether the design table contains a constant. If not, add it
  if ~any(ismember(ivarnames, 'constant'))
    design = cat(2,array2table(ones(size(design,1),1),'VariableNames', {'constant'}),design);
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
elseif ~iscell(outerfolds)
  error('unsupported specification of outerfolds');
end

% create cell-array with trial indices for inner folds, if necessary
if numel(lambda)>1 && ~iscell(innerfolds) && ~isempty(innerfolds)
  fprintf('creating inner fold partitioning of data for nested cross-validation\n');
  tmpfolds = cell(1,numel(outerfolds));
  for m = 1:numel(outerfolds)
    ix = outerfolds{m};
    if numel(ix)==size(tlck.trial,1)
      % no outer folding
      tmpfolds{m} = mous_makefolds(size(tlck.trial,1), innerfolds, balancefolds, design);
    else
      iy = setdiff(1:size(tlck.trial,1),ix);
      tmpfolds{m} = mous_makefolds(size(tlck.trial,1)-numel(outerfolds{m}), innerfolds, balancefolds, design(iy,:));
    end
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
if ~generalize
  Rin   = zeros(siz(2)*siz(3),numel(outerfolds),numel(innerfolds{1}),numel(lambda));
  R0in  = zeros(siz(2)*siz(3),numel(outerfolds),numel(innerfolds{1}),numel(lambda));
  nin   = zeros(numel(innerfolds{1}),1);
else
  Rin   = zeros(siz(2).^2.*siz(3),1,numel(innerfolds{1}),numel(lambda));
  R0in  = zeros(siz(2).^2.*siz(3),1,numel(innerfolds{1}),numel(lambda));
  nin   = zeros(numel(innerfolds{1}),1);
end

N  = size(design,2);
N0 = numel(reduceto);

% outer fold loop
for i_out = 1:numel(outerfolds)
  out_test     = outerfolds{i_out};
  dat_test     = dat(out_test,:);
  design_test  = design(out_test,:);
  
  if numel(out_test)==size(dat,1)
    out_train = out_test; % test and train are the same, ordinary GLM
  else
    out_train    = setdiff(1:siz(1),out_test);
  end
  dat_train    = dat(out_train,:);
  design_train = design(out_train,:);
  
  % inner fold loop
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
    
    design_cov           = design_train_in'*design_train_in;
    design_cov_reduced   = design_cov(reduceto,reduceto);
    design_train_reduced = design_train_in(:,reduceto)'; % transpose and select columns only once
    design_test_reduced  = design_test_in(:,reduceto);
    
    
    for i_lambda = 1:numel(lambda)
      design_cov_reg         = design_cov +         lambda(i_lambda).*eye(N);
      design_cov_reg_reduced = design_cov_reduced + lambda(i_lambda).*eye(N0);
      
      % compute the regression weights given a fixed value of lambda
      B   = (design_cov_reg\design_train_in');
      B0  = (design_cov_reg_reduced\design_train_reduced);
      
      Ball = [B0;B]*dat_train_in; % just a single multiplication goes faster
      %B   = B*dat_train_in;
      %B0  = B0*dat_train_in;
      
      if ~generalize
        % compute the model fit for the test data
        Rin(: , i_out, i_in, i_lambda) = sum((dat_test_in - design_test_in     * Ball(N0+(1:N),:) ).^2);
        R0in(:, i_out, i_in, i_lambda) = sum((dat_test_in - design_test_reduced* Ball(1:N0,:)     ).^2);
      else
        siz(1) = size(dat_test_in,1);
        tmp1 = reshape(design_test_in      * Ball(N0+(1:N),:),[siz(1:2) 1 siz(3)]);
        tmp0 = reshape(design_test_reduced * Ball(1:N0,:),    [siz(1:2) 1 siz(3)]);
        datx = reshape(dat_test_in,                           [siz(1) 1 siz(2:3)]);
        
        Rin(:, 1, i_in, i_lambda)  = reshape(sum((datx(:,ones(1,siz(2)),:,:)-tmp1(:,:,ones(1,siz(2)),:)).^2),[],1);
        R0in(:, 1, i_in, i_lambda) = reshape(sum((datx(:,ones(1,siz(2)),:,:)-tmp0(:,:,ones(1,siz(2)),:)).^2),[],1);
        
      end
      
    end
  end
end
Rsq_this = squeeze(mean(mean(1-Rin./R0in,3),2));

if numel(lambda)>1
  if ~generalize
    Rout  = zeros(siz(2)*siz(3),numel(outerfolds));
    R0out = zeros(siz(2)*siz(3),numel(outerfolds));
  else
    Rout  = zeros(siz(2).^2.*siz(3),numel(outerfolds));
    R0out = zeros(siz(2).^2.*siz(3),numel(outerfolds));  
  end
  % for each sample in this fold take the lambda value that optimizes
  % Rsq: this requires recomputation of the model
  if ~generalize
    [~, idx] = max(Rsq_this, [], 2);
  else
    [~, idx] = max(max(reshape(Rsq_this, [siz(2) siz(2) siz(3), size(Rsq_this,2)]),[], 2),[], 4);
    idx = squeeze(idx);
  end
    
  L     = nan+zeros(siz(2)*siz(3),1);
  B(:)  = nan; B = B(:,1:numel(idx));
  B0(:) = nan; B0 = B0(:,1:numel(idx));
  for i_out = 1:numel(outerfolds)
    for i_lambda = 1:numel(lambda)
      design_cov_reg = design_train'*design_train + lambda(i_lambda).*eye(N);
      
      % compute the regression weights given a fixed value of lambda
      B(:,idx==i_lambda)  = (design_cov_reg\design_train')*dat_train(:,idx==i_lambda);
      B0(:,idx==i_lambda) = (design_cov_reg(reduceto,reduceto)\design_train(:,reduceto)')*dat_train(:,idx==i_lambda);
      L(idx==i_lambda) = lambda(i_lambda);
    end
    
    if ~generalize
      % compute the model fit for the test data
      Rout(:,  i_out) = sum((dat_test - design_test            * B ).^2);
      R0out(:, i_out) = sum((dat_test - design_test(:,reduceto)* B0).^2);
    else
      siz(1) = size(design_test, 1);
      tmp1 = reshape(design_test             * B,  [siz(1:2) 1 siz(3)]);
      tmp0 = reshape(design_test(:,reduceto) * B0, [siz(1:2) 1 siz(3)]);
      datx = reshape(dat_test,                     [siz(1) 1 siz(2:3)]);
      
      Rout(:,  i_out) = reshape(sum((datx(:,ones(1,siz(2)),:,:)-tmp1(:,:,ones(1,siz(2)),:)).^2),[],1);
      R0out(:, i_out) = reshape(sum((datx(:,ones(1,siz(2)),:,:)-tmp0(:,:,ones(1,siz(2)),:)).^2),[],1);
      
    end
  end
else
  Rout  = squeeze(mean(Rin, 3));
  R0out = squeeze(mean(R0in, 3));
end
Rsq = mean(1 - Rout./R0out,2);

stats       = keepfields(tlck, {'time', 'label'});
if ~generalize
  stats.Rsq   = reshape(Rsq, [siz(2) siz(3)]);
  stats.dimord = 'chan_time';
else
  stats.Rsq   = reshape(Rsq, [siz(2) siz(2) siz(3)]);
  stats.dimord = 'chan_chan_time';
end
stats.ivar  = ivarnames;
stats.ivar0 = ivarnames0;
if exist('L','var')
  stats.lambda = reshape(L, [siz(2) siz(3)]);
end

