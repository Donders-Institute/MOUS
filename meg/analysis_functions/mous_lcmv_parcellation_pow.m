function pow = mous_lcmv_parcellation_pow(csd, parcellation)

nparc = numel(parcellation.label);
nfreq = numel(csd.freq);

pow = zeros(nparc,nfreq);
for k = 1:nparc
  F = parcellation.filter{k};
  S = cumsum(parcellation.s{k});
  S = S./S(end);
  %F = F(S<0.99,:);
  F = F(S<0.95,:);
 
  for m = 1:nfreq
    tmpdat = F*csd.crsspctrm(:,:,m)*F';
    pow(k,m) = sum(abs(diag(tmpdat)));
  end
end
  