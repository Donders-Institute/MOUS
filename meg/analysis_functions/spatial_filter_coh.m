function [coh, ori]=spatial_filter_coh(phi,cc,lambda,refindx,method)

% phi is the leadfield matrix -> pairwise columns belong to one position

% cc is the cross-spectral density matrix
% cmi is the inverted regularised cross-spectral density matrix
s   = svd(cc);
cmi = pinv(cc + s(1)*lambda*eye(size(cc,1)));

% specify some variables
nD       = 200;
nPoints  = size(phi,2)/2;
nRef     = numel(refindx);

coh(nPoints,nRef)     = 0; 
ori(2,2,nPoints,nRef) = 0;  
for m = 1:numel(refindx)
  refidx = (refindx(m)-1)*2 + (1:2);
  phiref = phi(:,refidx);
  
  % spatial filter and power for reference dipole
  wRef     = (phiref'*cmi*phiref)\phiref'*cmi;
  powerRef = wRef*cc*wRef';

  switch method
    case '1dip_scalar'
      for k = 1:nPoints,
%         pidx       = (k-1)*2 + (1:2); 
%         phipoint   = phi(:,pidx);
%         [c, o]     = coh_1dip_scalar(phipoint,cc,cmi,wRef,powerRef);
%         coh(k,m)     = c;
%         ori(:,:,k,m) = o;
      end
    case '1dip_pca'
      [u,s,v]  = svd(powerRef);
      powerRef = u(:,1)'*powerRef*u(:,1);
      wRef     = u(:,1)'*wRef;
      for k = 1:nPoints,
        pidx       = (k-1)*2 + (1:2);
        phipoint   = phi(:,pidx);
        [c, o]     = coh_1dip_pca(phipoint,cc,cmi,wRef,powerRef);
        coh(k,m)     = c;
        ori(:,:,k,m) = [u(:,1)';o];
      end
    case '1dip_cca'
      for k = 1:nPoints,
        if k==refindx(m), coh(k,m) = 1;continue; end
        pidx       = (k-1)*2 + (1:2); 
        phipoint   = phi(:,pidx);
        [c, o]     = coh_1dip_cca(phipoint,cc,cmi,wRef);
        coh(k,m)     = c;
        ori(:,:,k,m) = o;
      end
    case '2dip_cca'
      for k = 1:nPoints,
        if k==refindx(m), coh(k,m) = 1;continue; end
        pidx       = (k-1)*2 + (1:2); 
        phipoint   = phi(:,pidx);
        [c, o]     = coh_2dip_cca(phipoint,phiref,cc,cmi);
        coh(k,m)     = c;
        ori(:,:,k,m) = o;
      end
    case '1dip_jk'
      for k = 1:nPoints,
        pidx       = (k-1)*2 + (1:2); 
        phipoint   = phi(:,pidx);
        [c, o]     = coh_1dip_jk(phipoint,cc,cmi,wRef,powerRef,nD);
        coh(k,m)     = c;
        ori(:,:,k,m) = o;
      end
    otherwise
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 dipole, power pca
function [c, o] = coh_1dip_pca(phipoint,cc,cmi,wRef,powerRef)
    
% leadfield and spatial filter of the other source
phi_cmi  = phipoint'*cmi;
wPoint   = (phi_cmi*phipoint)\phi_cmi;
power    = wPoint*(cc*wPoint'); % putting the brackets makes it faster
[u,s,v]  = svd(power);
power    = s(1);
wPoint   = u(:,1)'*wPoint;
csd      = wRef*cc*wPoint';
c        = abs(csd).^2./abs(power.*powerRef);
o        = u(:,1)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2 dipoles, cca
function [c, o] = coh_2dip_cca(phipoint,phiref,cc,cmi)

% leadfield and spatial filter of the combined sources
phicombi = [phiref phipoint];
wCombi   = (phicombi'*cmi*phicombi)\phicombi'*cmi;
csd      = wCombi*cc*wCombi';
[e,d]    = multivariate_decomp(csd, 1:2, 3:4, 'cca');
o        = reshape(e(:,1),[2 2])';
o        = diag(sqrt(sum(o.^2,2)))*o; % norm normalize the rows
c        = abs(d(1)).^2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 dipole, cca
function [c, o] = coh_1dip_cca(phipoint,cc,cmi,wRef)

% leadfield and spatial filter of the other source
wPoint   = (phipoint'*cmi*phipoint)\phipoint'*cmi;
wCombi   = [wRef; wPoint];
csd      = wCombi*cc*wCombi';
[e,d]    = multivariate_decomp(csd, 1:2, 3:4, 'cca');
o        = reshape(e(:,1),[2 2])';
o        = diag(sqrt(sum(o.^2,2)))*o; % norm normalize the rows
c        = abs(d(1)).^2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 dipole, Jan's method
function [c, o] = coh_1dip_jk(phipoint,cc,cmi,wRef,powerRef,nD)

% leadfield and spatial filter of the other source
wPoint   = (phipoint'*cmi*phipoint)\phipoint'*cmi;
% power and csd for single dipole case
power        = wPoint*cc*wPoint';
pseudocross  = wRef*cc*wPoint';
% Jan's way of determining the optimal orientation
[c,oris] = numer_maxcoh_eval2_discr2(pseudocross,powerRef,power,nD);
c        = abs(c); % original code: real(c)
o        = oris([2 1],:);
