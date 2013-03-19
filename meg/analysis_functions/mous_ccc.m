function [output] = mous_ccc(sourcemodel, freq, varargin)

%[COH0] = MOUS_CCC(SOURCEMODEL, FREQ)
%
%estimate the coherence between all dipole-pairs.
%using a pairwise spatial filter
%
%PS: also computes filter correlation

threshold = ft_getopt(varargin, 'threshold', 0);
lambda    = ft_getopt(varargin, 'lambda',    0.001);
refindx   = ft_getopt(varargin, 'refindx',   []);

inside  = sourcemodel.inside;
ninside = numel(inside);
nchan   = numel(freq.label);
lforig  = cat(2, sourcemodel.leadfield{inside});

% scale the values in the csd matrix; this shouldn't affect the results,
% but most likely leads to less extreme exponents (numerical issues)
%s1             = svd(real(freq.crsspctrm));
%freq.crsspctrm = freq.crsspctrm./s1(1);

if size(sourcemodel.leadfield{sourcemodel.inside(1)},2)>1,
  % get optimal orientation using the same tolerance for the pinv as
  % beamformer_dics
  fprintf('computing optimal orientation for the sources\n');
  fprintf('norm normalizing leadfields with the norm of the leadfield\n');
  for k = 1:ninside
    lf = sourcemodel.leadfield{sourcemodel.inside(k)};
    sourcemodel.leadfield{sourcemodel.inside(k)} = lf./norm(lf);
  end
  nori = size(sourcemodel.leadfield{inside(1)},2);
  filt = zeros(ninside, nchan);
  if nori>1,
    ori  = zeros(nori,ninside);
    eta  = zeros(1,ninside);
    C    = real(freq.crsspctrm);
    s    = svd(C);
    C    = C + eye(size(C,1))*lambda*s(1);
    invC = pinv(real(C), 10*size(C,1)*max(svd(C))*eps);
    for m = 1:ninside
      indx = inside(m);
      tmpl = sourcemodel.leadfield{indx};
      X    = tmpl'*invC*tmpl;
      [u,s,~] = svd(real(pinv(X, 10*size(X,1)*max(svd(X))*eps)));
      ori(:,m) = u(:,1);
      eta(m)   = s(1,1)./s(2,2);
      tmpl     = tmpl*u(:,1);
      filt(m,:) = (1./(tmpl'*invC*tmpl))*tmpl'*invC;
    end
    
    % create a linear projection matrix
    proj = zeros(nori*ninside, ninside);
    for k = 1:ninside
      proj((k-1)*nori+(1:nori),k) = ori(:,k);
    end
    indx = find(proj);
    proj = sparse(proj);
  else
    proj = speye(ninside);
    indx = find(proj);
    ori  = ones(1,ninside);
  end
  lf         = lforig*proj;
else
  lf   = cat(2, sourcemodel.leadfield{sourcemodel.inside});
  filt = [];
  eta  = [];
  ori  = [];
end

C = freq.crsspctrm;
s = svd(C);
C = C./s(1); % normalise a bit to keep the numbers in a nice range
[c, pow, w12, scale] = compute_pairwise(lf, C, threshold, lambda, refindx);

fprintf('creating output structure\n');

output.coh = single(c);
output.w12 = single(w12);
output.pow = single(pow);
output.scale = single(scale);
output.eta = single(eta);

%output.p1   = p1;
%output.p2   = p2;
%output.coh0 = w12./sqrt(p1.*p2);

output.lf    = lforig;
output.ori   = ori;
output.filt  = filt;

%---------------------------------------------------
function [c,pow,w12,scale] = compute_pairwise(lf, C, threshold, lambda, refindx)

nvox = size(lf,2);
if isreal(C)
  % real valued case
  fprintf('Covariance matrix is real-valued\n');
  fprintf('norm normalizing leadfields with the norm of the leadfield\n');
  for k = 1:size(lf,2)
    lf(:,k)   = lf(:,k)./norm(lf(:,k));
  end
  fprintf('computing voxel level covariance\n');
  lfC   = lf'/C;  % lf'*inv(C);
  lfClf = lfC*lf; % lf'*inv(C)*lf;
  pow = 1./diag(lfClf); % voxel power
  csd2x2 = inv2x2(convertsquareto2x2(lfClf)); % multiple pairwise csd
  fprintf('getting the cross-terms\n');
  c   = convert2x2tosquare(csd2x2, [1 2]);
  fprintf('getting the auto-terms\n');
  p1  = abs(convert2x2tosquare(csd2x2, [1 1]));
  p2  = abs(convert2x2tosquare(csd2x2, [2 2]));
  fprintf('getting the filter inner products\n');
  fprintf('unfolding...\n');
  w12 = convertsquareto2x2(lfC*lfC');
  fprintf('sandwiching...\n');
  w12 = sandwich2x2(csd2x2, w12);
  fprintf('folding...\n');
  w12 = convert2x2tosquare(w12, [1 2]);
else
  % complex valued case
  fprintf('Covariance matrix is complex-valued\n');
  
  % get temporary copy for real and imaginary parts
  rC    = real(C);
  svdC  = svd(rC);
  if ischar(lambda)
    lambda = str2double(lambda)*svdC(1);
  end
  rCreg = rC + eye(size(C,1))*lambda;
  
  fprintf('norm normalizing leadfields with the norm of the leadfield\n');
  for k = 1:nvox
    lf(:,k)   = lf(:,k)./norm(lf(:,k));
  end
  fprintf('computing voxel level covariance\n');
  lfC   = lf'/rCreg;
  lfClf = lfC*lf; % lf'*inv(rC)*lf;
  pow    = 1./diag(lfClf); % voxel power
  csd2x2 = inv2x2(convertsquareto2x2(lfClf)); % multiple pairwise csd, real part
  % the above is strictly only true when using an unregularised inverse of
  % the real part of the csd matrix. 

  fprintf('getting the cross-terms: ');
  fprintf('unfolding...');
  tmpcross = convertsquareto2x2(lfC*C*lfC');
  fprintf('sandwiching...');
  tmp      = sandwich2x2(csd2x2, tmpcross);
  fprintf('folding...\n');
  c        = convert2x2tosquare(tmp, [1 2]);
  
  % the below is only true when using an unregularised inverse of the csd
  % matrix, this is generally not the case
  % but also the scaling matrices for the lf'*inv(rC)
%   fprintf('getting the cross-terms, real part\n');
%   creal = convert2x2tosquare(tmp, [1 2]);
%   fprintf('getting the cross-terms, imaginary part\n');
%   tmpimag = convertsquareto2x2(lfC*(1i.*iC)*lfC');
%   cimag   = convert2x2tosquare(sandwich2x2(tmp, tmpimag), [1 2]);
%   fprintf('combining real and imaginary parts\n');
%   c   = creal + cimag;
  fprintf('getting the auto-terms\n');
  p1  = abs(convert2x2tosquare(tmp, [1 1]));
  p2  = abs(convert2x2tosquare(tmp, [2 2]));
  clear tmp;
  fprintf('getting the filter inner products: ');
  fprintf('unfolding...');
  w12 = convertsquareto2x2(lfC*lfC');
  fprintf('sandwiching...');
  tmp = sandwich2x2(csd2x2, w12);
  fprintf('folding...\n');
  w12 = convert2x2tosquare(tmp, [1 2]);
  clear tmp;
end

% power product
pp    = sqrt(p1.*p2);

if 1,
  % scale with power product and do least-sq fit on coherence value, rather
  % than covariance
  c     = c./pp;
  c(~isfinite(c)) = 1;
  w12 = w12./pp;
end

if ~isempty(refindx)
  
% estimate scalar lambda, imposing global least-squares fit to diagonal 
options  = optimset('fminunc');
options  = optimset(options, 'Display', 'off');
options  = optimset(options, 'MaxIter', 1500);
options  = optimset(options, 'TolFun', 1e-31);
options  = optimset(options, 'LargeScale', 'off');

c   = c(:,refindx);
w12 = w12(:,refindx);
nvox = numel(refindx);

tmpc  = real(c);    tmpc(~isfinite(tmpc))  = 0;
tmpc0 = real(w12); tmpc0(~isfinite(tmpc0)) = 0;

for k = 1:nvox
  if mod(k,100)==0, fprintf('computing optimal lambda for voxel %d/%d\n',k,nvox); end
  
  % weight the individual points with their relative coherence
  tmpw   = abs(tmpc(:,k));
  tmpw   = (tmpw./nansum(tmpw)).^2; % weight the extreme points more
  
  % make a temporary copy of the null-coherence, and scale
  tmpc0x = tmpc0(:,k);
  scale  = max(tmpc0x);
  tmpc0x = tmpc0x./scale;
 
  sel    = abs(tmpc(:,k))>threshold;
  sel(k) = false;
  tmpw   = tmpw(sel);
  tmpc0x = tmpc0x(sel);
  
  lambda(k,1) = fminunc(@dcoh_error, 1, options, tmpc(sel,k), tmpc0x, abs(real(tmpw)));
  err(k,1)    = dcoh_error(lambda(k,1), tmpc(sel,k), tmpc0x, tmpw);
  lambda(k,1) = lambda(k,1)./scale;
  w12(:,k)    = w12(:,k).*lambda(k,1);
end
end

w12(~isfinite(w12)) = 1;
scale = lambda;
if 0,
c     = c./pp;
c(~isfinite(c)) = 1;
w12 = w12./pp;
w12(~isfinite(w12)) = 1;
end

function err = dcoh_error(lambda,c1,c2,w)

err = sum(sqrt((w(:).*(c1(:)-c2(:).*lambda)).^2));
%err = abs(sum(((w(:).*(c1(:)-c2(:).*lambda)))));
