function C = parcellation2connmat(parcellation)

nparc = max(parcellation.parcellation(:));

C1 = tri2connmat(parcellation.tri);
C  = false(nparc);
for k = 1:size(C1,2)
  pindx = parcellation.parcellation(k);
  if pindx>0
    nindx = setdiff(parcellation.parcellation(C1(:,k)>0),0);
    C(nindx,pindx) = true;
  end
end
