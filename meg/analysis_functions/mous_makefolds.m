function folds = mous_makefolds(nobs,nfold)

reorder = randperm(nobs);
ix    = round(linspace(0,nobs,nfold+1)); % indices of observations that go into the test sample
folds = cell(nfold,1);
for k = 1:nfold
  folds{k} = reorder((ix(k)+1):ix(k+1));
end