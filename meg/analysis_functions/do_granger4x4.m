function [g, g_toti] = do_granger4x4(csd,freq,cmbindx)

if nargin==2,
  cmbindx = make_cmbindx(size(csd,1));
end
[h,z,s] = sfactorization_wilson4x4(csd,freq,35,1e-18,cmbindx,'none','chol',false);

H = reshape(h,[4 4 size(h,1)/16 size(h,2)]);
Z = reshape(z,[4 4 size(z,1)/16]);
S = reshape(s,[4 4 size(s,1)/16 size(s,2)]);


%%%%%%%%%%%%%%%%%%%
% blockwise granger
%%%%%%%%%%%%%%%%%%%

% H = transfer function nchan x nchan x ncmb x nfreq
% Z = noise covariance  nchan x nchan x ncmb
% S = crosspectrum      nchan x nchan x ncmb x nfreq

ncmb   = size(H,3);
nfreq  = size(H,4);

g      = zeros(2,2,ncmb,nfreq);
g_toti = zeros(ncmb,nfreq);
for k = 1:ncmb
  % projection matrix for block2 -> block1
  P1 = [eye(2) zeros(2); -Z(3:4,1:2,k)/Z(1:2,1:2,k) eye(2)];
  
  % projection matrix for block1 -> block2
  P2 = [eye(2) -Z(1:2,3:4,k)/Z(3:4,3:4,k); zeros(2) eye(2)];
  
  for m = 1:nfreq
    Sj = S(:,:,k,m);
    Zj = Z(:,:,k);
    H1 = H(:,:,k,m)/P1;
    H2 = H(:,:,k,m)/P2;
    
    num1 = abs(det(Sj(1:2,1:2)));
    num2 = abs(det(Sj(3:4,3:4)));
    
    denom1 = abs(det(H1(1:2,1:2)*Zj(1:2,1:2)*H1(1:2,1:2)'));
    denom2 = abs(det(H2(3:4,3:4)*Zj(3:4,3:4)*H2(3:4,3:4)'));
    
    g(2,1,k,m) = log(num1./denom1);
    g(1,2,k,m) = log(num2./denom2);
    
    g_toti(k,m) = log( (abs(det(Sj([1 2],[1 2]))).*abs(det(Sj([3 4],[3 4]))))./abs(det(Sj)) );
  end
end

% Below is the original implemention: it has been verified to give the same
% result as the above (but then for a single block of 4 channels
%[h,z,s] = sfactorization_wilson(csd,freq,35,1e-18,'none','chol',false);
%g  = ft_connectivity_granger(shiftdim(h,-1),shiftdim(z,-1),shiftdim(s,-1),'dimord','rpt_chan_chan_freq','powindx',{[1 2] [3 4]});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list = make_cmbindx(n)

list   = zeros(0,4);
nblock = n/2;
for k = 1:nblock
  for m = (k+1):nblock
    list(end+1,:) = [(k-1)*2+(1:2) (m-1)*2+(1:2)];
  end
end

