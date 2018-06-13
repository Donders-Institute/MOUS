function bin = mous_multisetcca_stratifyivar(X,ivar,covariates,nbins)

% helper function to create an indexing vector bins, for stratified
% shuffling

for k = 1:numel(covariates)
  selcol(k) = find(ismember(ivar, covariates{k}));
  ordinal(k) = any(ismember({'index', 'leftbranch', 'rightbranch', 'dleftbranch', 'drightbranch'}, covariates{k}));
end
X = X(:,selcol);

for k = 1:size(X,2)
  tmp = X(:,k) - nanmin(X(:,k));
  if ~ordinal(k)
    edges = eqpop(tmp,nbins(k));
  else
    edges = (nanmin(tmp)-0.5):(nanmax(tmp)+0.5);
  end
  [N{k},Bin{k}] = histc(tmp, edges);  
  numk(k)       = numel(edges)-1;
end
offset = [0 cumprod(numk)];

bin = Bin{1};
for k = 2:numel(Bin)
  bin = bin+offset(k).*Bin{k};
end
ubin = unique(bin);
newbin = bin;
for k = 1:numel(ubin)
  newbin(bin==ubin(k)) = k;
end
bin = newbin;
