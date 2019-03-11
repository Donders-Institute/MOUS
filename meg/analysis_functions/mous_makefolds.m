function folds = mous_makefolds(nobs,nfold,balancefolds,design)

% FOLDS = MOUS_MAKEFOLDS(NOBS,NFOLD,BALANCEFOLDS,DESIGN);
% create a cell array of nfold folds based on nobs observations.
% If balancefolds is true, the last column in the design is used to balance
% the folding. This makes sense only in discrete regressors with not too
% many different values.


if isempty(balancefolds)
  balancefolds = false;
end

if ~balancefolds
  
  reorder = randperm(nobs);
  ix    = round(linspace(0,nobs,nfold+1)); % indices of observations that go into the test sample
  folds = cell(nfold,1);
  for k = 1:nfold
    folds{k} = reorder((ix(k)+1):ix(k+1));
  end
  
else
  
  if istable(design)
    design = table2array(design);
  end
  if size(design,2)>1
    design = design(:,end);
    % assume the last column to be of relevance
  end
  udesign = unique(design);
  if numel(udesign)>15
    % 10 is arbitrary
    error('the number of unique values in the design is too large for a balanced folding');
  end
  folds = cell(nfold,1);
  for k = 1:numel(folds)
    folds{k} = zeros(1,0);
  end
  
  for k = 1:numel(udesign)
    n(k,1) = sum(design==udesign(k));
  end
  while any(n<nfold)
    sel = find(n<nfold);
    for m = sel(:)'
      if m==1
        m_alt = 2;
      else
        m_alt = m-1;
      end
      design(design==udesign(m)) = udesign(m_alt);
    end
    udesign = unique(design);
    n = [];
    for m = 1:numel(udesign)
      n(m,1) = sum(design==udesign(m));
    end
  end
  
  for k = 1:numel(udesign)
    indx = find(design==udesign(k));
    indx = indx(randperm(numel(indx)));
    ix   = round(linspace(0,numel(indx),nfold+1));
    for m = 1:nfold
      folds{m} = cat(2,folds{m},indx((ix(m)+1):ix(m+1))');   
    end
  end
  
end