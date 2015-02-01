function [pte1, pte2, r, opt_kappa, test_corr, nalpha, nbeta, K1, K2] = mous_kcca_kfoldcv(X1,X2,opt)

% Script to wrap kcca in a k-fold cross-validation loop
% options: 
%   opt.eta   : Gram-Schmidt tolerance
%   opt.kappa : regularisation parameter. 
%               >0 = fixed value
%               -1 = optimise wrt a random kernel
%               -2 = optimise using nested CV
%   opt.stand : standardize the kernels?
%   opt.nfold : number of cross-validation folds
%   opt.nrand : permute N times the order of observations in kernel space
%               to get a null distribution of the test_corr variable 


if size(X1,1) ~= size(X2,1)
    fprintf('Error: input matrices have non-compatible dimensions\n');
    return;
elseif all(size(X1)==size(X1,1))
    % assume with square matrices that the input data are already the
    % kernels
    opt.computekernel = 0;
    K1 = X1;
    K2 = X2;
end
N = size(X1,1);

%%%%%%%%%%%%%%%
% parse options
%%%%%%%%%%%%%%%
if exist('opt','var') && isfield(opt,'eta')
    eta = opt.eta;
else
    eta = 0.5;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'kappa'))
    opt.kappa = 0.1;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'stand'))
    opt.stand = 0;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'nfold'))
    opt.nfold = 10;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'computekernel'))
    opt.computekernel = 1;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'nrand'))
    opt.nrand = 0;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'verbose'))
    opt.verbose = 1;
end
if ~exist('opt','var') || (exist('opt','var') && ~isfield(opt,'allcomponents'))
    opt.allcomponents = 0;
end

if ~opt.stand && opt.computekernel
    K1 = X1*X1';
    K2 = X2*X2';
end

%%%%%%%%%%%%%%%%
% initialisation
%%%%%%%%%%%%%%%%
Npf       = max(sum(cv_index(N,1,opt.nfold)), sum(cv_index(N,opt.nfold,opt.nfold)));
opt_kappa = zeros(opt.nfold,1);
nalpha    = cell(opt.nfold,1);
nbeta     = cell(opt.nfold,1);
r         = cell(opt.nfold,1);
mindim    = inf;
diffdim   = false;
if opt.allcomponents
    pte1 = zeros(N,Npf); pte2 = zeros(N,Npf); 
else
    pte1 = zeros(N,1);   pte2 = zeros(N,1); 
end

%%%%%%%%%%%%%%%%%%%%
% begin main CV loop
%%%%%%%%%%%%%%%%%%%%
for i = 1:opt.nfold
    % configure training and test indices
    [tr,te] = cv_index(N,i,opt.nfold); 
    
    % centre kernels
    if opt.stand && opt.computekernel
        X1z = (X1 - ones(N,1)*mean(X1(tr,:))) ./ (ones(N,1)*std(X1(tr,:)));
        X2z = (X2 - ones(N,1)*mean(X2(tr,:))) ./ (ones(N,1)*std(X2(tr,:)));
        K1 = X1z*X1z';
        %figure;imagesc(K1);
        K2 = X2z*X2z';
        K1tr = K1(tr,tr); K1te = K1(te,tr);
        K2tr = K2(tr,tr); K2te = K2(te,tr);
    else
        [K1tr, K1te] = centerTrainTestKernels(K1(tr,tr),K1(te,tr));
        [K2tr, K2te] = centerTrainTestKernels(K2(tr,tr),K2(te,tr));
    end
    % precompute GSDs
    Rx = gsd(K1tr,eta);
    Ry = gsd(K2tr,eta);
    
    if opt.kappa < 0
        switch opt.kappa
            case -1 
                kappa = opt_kappa_rand(K1tr,K2tr,Rx,Ry,eta);
            case -2
                kappa = opt_kappa_cv(K1tr,K2tr,eta);
            otherwise
                fprintf('unknown value for kappa\n');
                return;
        end
    else
        kappa = opt.kappa;
    end
    opt_kappa(i) = kappa;
    
    %run kCCA
    [nalpha{i}, nbeta{i}, r{i}] = kcanonca_reg_ver2(K1tr,K2tr,eta,kappa,0,2,Rx,Ry);
    
    projte1 = K1te*nalpha{i};
    projte2 = K2te*nbeta{i};
   
    if opt.allcomponents
        % save all components
        pte1(te,size(pte1,2)-size(projte1,2)+1:end) = projte1;
        pte2(te,size(pte2,2)-size(projte2,2)+1:end) = projte2;
    else
        % just save the last component
        pte1(te)  = projte1(:,end);
        pte2(te)  = projte2(:,end);
        nalpha{i} = nalpha{i}(:,end);
        nbeta{i}  = nbeta{i}(:,end);
        r{i}      = r{i}(end);
    end
    
    % keep track of number of components
    if i > 1 && (mindim ~= size(projte1,2) || mindim ~= size(projte1,2))
        diffdim = true;
    end
    mindim = min([mindim, size(projte1,2), size(projte2,2)]);
        
    if opt.verbose, fprintf('Fold %d: rank=%d, kappa=%2.2f, train corr=%2.2f\n',i,size(nalpha,2),kappa,r{i}(end)); end
end
    
if opt.allcomponents
    % trim projection matrices
    pte1 = pte1(:,size(pte1,2)-mindim+1:end);
    pte2 = pte2(:,size(pte2,2)-mindim+1:end);
end

test_corr = diag(corr(pte1,pte2));

if diffdim,     warning('Dimensionality differs between CV folds');       end
if opt.verbose, fprintf('CV complete. Test corr=%2.2f\n',max(test_corr)); end

if opt.nrand>0,
  % get a permutation distribution of the test_corr using nrand
  % randomizations
  tmpopt = opt;
  tmpopt.nrand = 0;
  test_corr(end, opt.nrand+1) = 0;
  for k = 1:opt.nrand
    indx = randperm(N);
    [~,~,~,~,tmp] = mous_kcca_kfoldcv(K1(indx,indx),K2,tmpopt);
    test_corr(1:numel(tmp),k+1) = tmp(:);
  end
end

end

%%%%%%%%%%%%%%%%%%
% private funtions
%%%%%%%%%%%%%%%%%%
function [tr,te] = cv_index(N,f,Nfold)

% training and test indices
npf = floor(N / Nfold);
te = false(N,1);
if (f < Nfold)
    te((1:npf)+(f-1)*npf) = true;
else
    te((((f-1)*npf)+1):N) = true;
end
tr = ~te;

end

function opt_kappa = opt_kappa_cv(K1,K2,eta)

% Locating optimal regularisation value for kcca
% using nested cross-validation.
Ntr   = size(K1,1);
Nfold = 10;

kappa = 0:0.1:1;

va_r = zeros(length(kappa),1);
for cnt = 1:length(kappa)   
    pva1 = zeros(Ntr,1); pva2 = zeros(Ntr,1);
    for j = 1:Nfold
        [tr,va] = cv_index(Ntr,j,10);
        
        % note: kernels are already centred
        % unfortunately we need to recompute the GSD every time
        [nalpha, nbeta] = kcanonca_reg_ver2(K1(tr,tr),K2(tr,tr),eta,kappa(cnt),0,2);
        
        projva1  = K1(va,tr)*nalpha;
        projva2  = K2(va,tr)*nbeta;
        pva1(va) = projva1(:,end);
        pva2(va) = projva2(:,end);
    end
    va_r(cnt) = corr(pva1,pva2);
end
[val, idx] = max(va_r);  
opt_kappa = kappa(idx);
end

function opt_kappa = opt_kappa_rand(K1,K2,Rx,Ry,eta)

% Locating optimal regularisation value for kcca
% by maximising the difference from a random kernel

% Create randomised version of K2
rp = randperm(length(K2));
K2rp = K2(rp,rp);
Ryr = gsd(K2rp,eta);

kappa = 0:0.1:1;
diff_r = zeros(length(kappa),1);
                
for cnt=1:length(kappa)
    [junk1,junk2,r_1] = kcanonca_reg_ver2(K1,K2,eta,kappa(cnt),1,2,Rx,Ry);
    [junk1,junk2,r_2] = kcanonca_reg_ver2(K1,K2rp,eta,kappa(cnt),1,2,Rx,Ryr);               
     diff_r(cnt) = norm(r_1 - r_2);
end
[val, idx] = max(abs(diff_r));
opt_kappa = kappa(idx);
end