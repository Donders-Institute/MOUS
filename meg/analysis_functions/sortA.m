function [A,S] = sortA(A,S)

if ndims(A)==3,
  Aorig = A;
  A = squeeze(mean(A,2));
end

for k = 1:size(A,2)
  [~,m(k)] = max(A(:,k));
end
[srt,ix] = sort(m);
A=A(:,ix);
S=S(ix,:);

if exist('Aorig', 'var')
  Aorig = Aorig(:,:,ix);
  A     = Aorig;
end