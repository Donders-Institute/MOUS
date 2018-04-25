function [W, A, rho, Rtest, Xtest, testfold] = mous_multisetcca(X,nfold,K,lambda,shufflag)

if nargin<4 || isempty(lambda)
  lambda = [];
end

if nargin<5 || isempty(shufflag) 
  shufflag = 0; % can otherwise be 1 or a cell-array
end

if iscell(shufflag)
  blocks   = shufflag;
  shufflag = 3;
  
  % do the shuffling per block of subjects, where each cell represents the
  % indices for a given block
end
if shufflag==2
  error('shufflag of ''2'' is not supported anymore');
end

% check the input data
if iscell(X)
  % one structure per set
  nset = numel(X);
else
  % single structure, where the assumption is that the set i.d. can be
  % recovered from the label list
  X = {X};
  nset = 1;
end
  
testfold = nfold;
if (numel(nfold)==1 && nfold>1) || iscell(nfold)
  
  if iscell(nfold)
    testfold = nfold;
    nfold    = numel(testfold);
  else
    % create the folds
    nobs     = numel(X{1}.trial);
    obs_shuf = randperm(nobs);
    ix       = round(linspace(0,nobs,nfold+1)); % indices of observations that go into the test sample
    testfold = cell(nfold,1);
    for k = 1:nfold
      testfold{k,1} = obs_shuf((ix(k)+1):ix(k+1));
    end
  end
  
  % loop over the folds
  for k = 1:nfold
    fprintf('Computing fold %d/%d\n',k,nfold);
    if exist('blocks', 'var')
      shufflag = blocks;
    end
    [W(:,:,:,k), A(:,:,:,k), rho(:,:,k), Rtest(:,:,k), Xtest(k,:)] = mous_multisetcca(X,testfold{k},K,lambda,shufflag);
  end
  
  % do a polarity check on the weights and get a majority vote: Note that
  % this only affects the output data structure's polarity of the time
  % series (+associated matrices) and the mixing weights A, not the other variables.
  for iter = 1:5
    [nchan,ncomp,nset,nfold] = size(A);
    tmpA = reshape(permute(A,[1 3 4 2]),[nchan*nset nfold ncomp]);
    
    siz  = [size(tmpA) 1];
    covA = zeros(siz(2),siz(2),siz(3));
    covAs = covA;
    for k = 1:size(tmpA,3)
      covA(:,:,k)  = cov(tmpA(:,:,k));
      covAs(:,:,k) = sign(covA(:,:,k))*sign(covA(:,:,k))';
    end
    
    x  = shiftdim(sum(covAs));
    ok = false(1,ncomp);
    
    flipmat = ones(nfold,ncomp);
    
    % if all values are nfold^2, it's ok
    ok = ok | all(x==nfold^2,1);
    
    % if the absolute of all values in a column are the same, it's easy to
    % solve
    sel = ~ok;
    for k = find(sel)
      [m,ix] = max(x(:,k));
      
      flipmat(:,k) = sign(covA(:,ix,k));
    end
    xold = x;
    
    %disp(sum(flipmat(:)<0));
    if size(flipmat,2)<size(Xtest{1}.topo,2)
      flipmat = repmat(flipmat, [1 size(Xtest{1}.topo,2)./size(flipmat,2)]);
    end
    
    for k = 1:size(Xtest,2)
      for m = 1:size(Xtest,1)
        Xtest{m,k}.topo     = Xtest{m,k}.topo*diag(flipmat(m,:));
        Xtest{m,k}.unmixing = diag(flipmat(m,:))*Xtest{m,k}.unmixing;
        for mm = 1:numel(Xtest{m,k}.trial)
          tmp = Xtest{m,k}.trial{mm};
          tmp(~isfinite(tmp)) = 0;
          tmp = diag(flipmat(m,:))*tmp;
          tmp(tmp==0) = nan;
          Xtest{m,k}.trial{mm} = tmp;
        end
      end
    end
    
    % also flip A and W as appropriate
    for k = 1:nfold
      for m = 1:ncomp
        A(:,m,:,k) = A(:,m,:,k).*flipmat(k,m);
        W(m,:,:,k) = W(m,:,:,k).*flipmat(k,m);
      end
    end
    
  end
  
  % return to invoking function
  return;
end


% preprocess the data: get the covariance matrix and the masked block-diagonal matrix

shufvec = shufflag;
switch shufflag
  case 0
    % nothing to be done
    allshufvec = [];
  case 1
    % shuffle trials and subjects and then do a covariance computation,
    % ensure the same trialorder across sets, otherwise we get
    % complex-valued results
    for m = 1:nset
      allshufvec(m,:) = randperm(numel(X{1}.trial));
    end
  case 3
    % shuffle trials and subjects, but maintain the shuffling across
    % blocks of subjects
    for m = 1:numel(blocks)
      allshufvec(blocks{m},:) = repmat(randperm(numel(X{1}.trial)), numel(blocks{m}), 1);
    end
end

% shuffle the trials
if ~isempty(allshufvec)
  fprintf('shuffling trials\n');
  X = shuffletrials(X, allshufvec);
end

% check whether the test and training data should be separated
computeRtest = false;
if numel(nfold)>1
  indx_test  = nfold;
  indx_train = setdiff(1:numel(X{1}.trial), indx_test);
  
  % split the data into train and test set
  Xtest  = cell(size(X));
  for k = 1:nset
    Xtest{k} = X{k};
    Xtest{k}.trial = Xtest{k}.trial(indx_test);
    Xtest{k}.time  = Xtest{k}.time(indx_test);
    try, Xtest{k}.trialinfo = Xtest{k}.trialinfo(indx_test,:); end
    
    X{k}.trial = X{k}.trial(indx_train);
    X{k}.time  = X{k}.time(indx_train);
    try, X{k}.trialinfo = X{k}.trialinfo(indx_train,:); end
    
  end
  computeRtest = true;
else
  Xtest = X;
end

if nset>1
  % get number of channels per set in case of a multiple cell-array as
  % input
  n = zeros(nset,1);
  for k = 1:nset
    n(k) = numel(X{k}.label);
  end
  sumn = cumsum([0 n(:)']);
else
  % decode the label in case of a single data structure as input
  label = X{1}.label;
  for k = 1:numel(label)
    tmp = tokenize(label{k},'_');
    label{k} = tmp{1};
  end
  ulabel = unique(label);
  n = zeros(numel(ulabel),1);
  for k = 1:numel(ulabel)
    n(k) = sum(strcmp(label,ulabel{k}));
  end
  sumn = cumsum([0 n(:)']);
end

R     = zeros(sum(n));
if computeRtest, Rtest = R; end
mask  = [];

if nset>1
  % compute covariance in a blockwise fashion, with relatively slow for
  % loops
  for k = 1:nset
    for m = k:nset
      % compute the covariance in blocks, pairwise across sets
      nchan1 = n(k);
      nchan2 = n(m);
      
      % i1 and i2 are the indices into the overall covariance matrix of
      % this particular sub-block
      i1 = sumn(k) + (1:nchan1);
      i2 = sumn(m) + (1:nchan2);
      
      %fprintf('%2.1f\n',100*cnt/nblocks);
      if k==m
        mask    = blkdiag(mask,ones(nchan1)); % this is the mask for the setwise block diagonal matrix
      end
      R(i1,i2) = nancov_shuf(X{k}.trial,X{m}.trial,0);
      if k~=m
        R(i2,i1) = ctranspose(R(i1,i2));
      end
      if computeRtest
        Rtest(i1,i2) = nancov_shuf(Xtest{k}.trial,Xtest{m}.trial,0);
        if k~=m
          Rtest(i2,i1) = ctranspose(Rtest(i1,i2));
        end
      end
    end
  end
else
  % compute covariances in a single shot
  R = nancov_shuf(X{1}.trial,X{1}.trial,0);
  if computeRtest
    Rtest = nancov_shuf(Xtest{1}.trial,Xtest{1}.trial,0);
  end
  for k = 1:numel(n)
    mask = blkdiag(mask,ones(n(k)));
  end
end

S = R.*mask;

% compute the spatial filter and its inverse
[W,A] = getAW(R,S,K,n,lambda);

% get the correlation matrix
if computeRtest
  rho = getrho(Rtest,W,K,n);
else
  rho   = getrho(R,W,K,n);
  Rtest = R;
end

% post-process the data if the input contained a cell array of fieldtrip
% data structures
complabel = cell(K,1);
for k = 1:K
  complabel{k,1} = sprintf('mscca%03d',k);
end

if nset>1
  W = W(:,:,1:nset);
  A = A(:,:,1:nset);
  for k = 1:nset
    Xtest{k}.trial = W(:,1:n(k),k)*Xtest{k}.trial;
    if ~isfield(Xtest{k}, 'topo')
      Xtest{k}.topo  = A(1:n(k),:,k);
    else
      Xtest{k}.topo  = Xtest{k}.topo*A(1:n(k),:,k);
    end
    if ~isfield(Xtest{k},'unmixing')
      Xtest{k}.unmixing = W(:,1:n(k),k);
    else
      Xtest{k}.unmixing = W(:,1:n(k),k)*Xtest{k}.unmixing;
    end
    Xtest{k}.label = complabel;
  end
else
  Wall = [];
  Aall = [];
  for k = 1:size(W,3)
    Wall = blkdiag(Wall,W(:,:,k));
    Aall = blkdiag(Aall,A(:,:,k));
  end
  for k = 1:numel(Xtest{1}.trial)
    tmp = Xtest{1}.trial{k};
    tmp(~isfinite(tmp)) = 0;
    tmp = Wall*tmp;
    tmp(tmp==0) = nan;
    Xtest{1}.trial{k} = tmp;
  end
  if isfield(Xtest{1},'topo')
    % well, what to do here?
    error('don''t know what to do');
  else
    Xtest{1}.topo = Aall;
  end
  if isfield(Xtest{1},'unmixing')
    error('don''t know what to do');
  else
    Xtest{1}.unmixing = Wall;
  end
  
  % expand the complabel, to match the data
  ncomp     = numel(complabel);
  complabel = repmat(complabel, [numel(ulabel) 1]);
  for k = 1:numel(complabel)
    complabel{k} = sprintf('%s_%s',complabel{k}, ulabel{ceil(k./ncomp)});
  end
  Xtest{1}.label = complabel;
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunctions
function [W,A] = getAW(R,S,K,n,lambda)

if ~isempty(lambda)
  R = R + eye(size(R,1)).*lambda;
  S = S + eye(size(S,1)).*lambda;
end
  
nset = numel(n);
%assert(all(n==n(1)));

% this eigenvalue decomposition gives the unmixing in the columns, so to make
% it a proper unmixing matrix, to-be-applied to each subject, it should be transposed 
[tempW,~] = eigs(R,S,K);
tempW     = normc(tempW);
tempA     = R*tempW/(tempW'*R*tempW);

W = nan+zeros(K,max(n),nset);
A = nan+zeros(max(n),K,nset);
sumn = cumsum([0 n(:)']);
for k = 1:nset
  nchan    = n(k);
  indx     = sumn(k) + (1:nchan);
  W(:,1:nchan,k) = (tempW(indx,:))'; %unmixing
  A(1:nchan,:,k) = (tempA(indx,:));  %mixing
end

function rho = getrho(R,W,K,n)

nset = numel(n);
%assert(all(n==n(1)));

R(~isfinite(R)) = 0;

tmp = zeros(K*nset,size(R,1));
sumn = cumsum([0 n(:)']);
for k = 1:nset
  nchan = n(k);
  for m = 1:K
    tmp((m-1)*nset+k, sumn(k)+(1:nchan)) = W(m,1:nchan,k);
  end
end
rho = tmp*R*tmp';
%rho = rho./sqrt(diag(rho)*diag(rho)');
