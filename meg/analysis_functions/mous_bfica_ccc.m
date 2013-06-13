function [cohsent, cohseq] = mous_bfica_ccc(sourcemodel, freq, varargin)

% reduce leadfields to 2 columns
ndip = size(sourcemodel.leadfield{sourcemodel.inside(1)},2);
if ndip==3
  for k = 1:numel(sourcemodel.inside)
    indx = sourcemodel.inside(k);
    tmp  = sourcemodel.leadfield{indx};
    [u,s,v] = svd(tmp);
    sourcemodel.leadfield{indx} = tmp*v(:,1:2);
  end
end


lambda  = ft_getopt(varargin, 'lambda', 0.001);
if isfield(freq, 'time') && numel(freq.time)>1
  freq    = mtmconvol2mtmfft(freq, []);
end

% orient the leadfields
if isfield(sourcemodel,'avg') && isfield(sourcemodel.avg,'ori')
for k = 1:numel(sourcemodel.inside)
  indx = sourcemodel.inside(k);
  sourcemodel.leadfield{indx} = sourcemodel.leadfield{indx}*sourcemodel.avg.ori{indx};
end
end

sel1    = find(ismember(freq.trialinfo(:,2), [1 2 5 6]));
sel2    = find(ismember(freq.trialinfo(:,2), [3 4 7 8]));

n = min(numel(sel1), numel(sel2));
tmp1 = randperm(numel(sel1));
tmp2 = randperm(numel(sel2));
sel1 = sort(tmp1(1:n));
sel2 = sort(tmp2(1:n));

tmp     = ft_selectdata(freq, 'rpt', [sel1(:)' sel2(:)']);
tmp     = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
%sourcemodel = projectori(sourcemodel, tmp.crsspctrm, lambda);

% cfg      = [];
% cfg.fwhm = 'yes';
% sourcemodel = ft_sourcedescriptives(cfg, sourcemodel);
refindx     = ft_getopt(varargin, 'refindx', 1:numel(sourcemodel.inside),1);

tmp     = ft_selectdata(freq, 'rpt', sel1);
%tmp     = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
%cohsent = mous_ccc(sourcemodel, tmp, 'refindx', refindx, 'lambda', lambda);
cohsent = estimate_nullcoh4x4(sourcemodel, tmp, 'refindx', refindx, 'lambda', lambda);

tmp     = ft_selectdata(freq, 'rpt', sel2);
%tmp     = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
%cohseq  = mous_ccc(sourcemodel, tmp, 'refindx', refindx, 'lambda', lambda);
cohseq  = estimate_nullcoh4x4(sourcemodel, tmp, 'refindx', refindx, 'lambda', lambda);

cohsent.inside  = sourcemodel.inside;
cohsent.outside = sourcemodel.outside;
cohsent.dim     = sourcemodel.dim;
cohsent.dof     = numel(sel1);

cohseq.inside  = sourcemodel.inside;
cohseq.outside = sourcemodel.outside;
cohseq.dim     = sourcemodel.dim;
cohseq.dof     = numel(sel2);

try
  cohsent = rmfield(cohsent, 'lf');
  cohseq  = rmfield(cohseq,  'lf');
end
try
  cohsent = rmfield(cohsent, 'w12');
  cohseq  = rmfield(cohseq,  'w12');
end
try
  cohsent = rmfield(cohsent, 'coh0');
  cohseq  = rmfield(cohseq, 'coh0');
end

if isfield(sourcemodel, 'fwhm')
  cohsent.fwhm   = sourcemodel.fwhm;
  cohseq.fwhm    = sourcemodel.fwhm;
  
  cohsent.coh = single(abs(cohsent.coh));
  %krn = compute_kernel(sourcemodel);
  %cohsent.coh = single(krn'*double(abs(cohsent.coh))*krn);
  %cohsent.w12 = single(krn'*double(abs(cohsent.w12)));%*krn);
  %cohsent     = rmfield(cohsent, 'w12');
  
  cohseq.coh = single(abs(cohseq.coh));
  %cohseq.coh = single(krn'*double(abs(cohseq.coh))*krn);
  %cohseq.w12 = single(krn'*double(abs(cohseq.w12)));%*krn);
  %cohseq     = rmfield(cohseq, 'w12');
end

tmp = tril(ones(size(cohsent.coh,1)),-1)>0;
cohsent.coh = cohsent.coh(tmp);
cohseq.coh  = cohseq.coh(tmp);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sourcemodel = projectori(sourcemodel, C, lambda)

inside  = sourcemodel.inside;
ninside = numel(inside);
nchan   = size(C,1);
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
    C    = real(C);
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
      sourcemodel.avg.filter{indx} = (1./(tmpl'*invC*tmpl))*tmpl'*invC;
      sourcemodel.leadfield{indx}  = tmpl;
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
    ori  = ones(1,ninside);
  end
else
  eta  = [];
  ori  = [];
end
sourcemodel.eta = eta;
sourcemodel.ori = ori;
