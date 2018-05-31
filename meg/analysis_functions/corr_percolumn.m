function out = corr_percolumn(in1, in2)

% corr_percolumn computes the pearson correlation across pairs of columns,
% i.e. diag(corr(in1,in2));

% out = diat(corr(in1, in2));

% mean subtract the columns
in1 = bsxfun(@minus, in1, mean(in1));
in2 = bsxfun(@minus, in2, mean(in2));

nom = sum(in1.*in2);
denom = sqrt(sum(in1.^2).*sum(in2.^2));

out = nom./denom;

