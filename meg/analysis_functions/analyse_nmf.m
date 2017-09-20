% output of multiple runs of nmf are stored in cell-arrays A and S

s = cat(1,S{:});
a = cat(2,A{:});

C = s*s';
C = C./sqrt(diag(C)*diag(C)');

[P,Z,order] = hcluster(1-C, 'al');
R           = rindex(1-C, P);
[~,N]       = min(R);
[iq,in,out] = clusterquality('mean',C,P(N,:));

idx = zeros(N,1);
for k = 1:N
  index        = find(P(N,:)==k);
  [~,idx(k,1)] = max(sum(C(index,index)));
  idx(k)       = index(idx(k));
end

