function [C, A] = S2C(S,indx,N,index,Ain)

if nargin<3
  N = 378;
end

if iscell(S)
  if nargin<4
    error('with a cell-array in the input, an index of a component needs to be supplied');
  else
    C = zeros(378,378,numel(S));
    if nargin==5,
      A = zeros(size(Ain{1},2),numel(S));
    end
    for k = 1:numel(S)
      c        = S2C(S{k},indx,N);
      C(:,:,k) = c(:,:,index);
      if nargin==5,
        A(:,k) = Ain{k}(index,:);
      end
    end
  end
  return;
end

if ~islogical(indx)

  n = N*(N-1)*0.5;
  triangle_low = tril(ones(N),-1)>0;
  C = zeros(N,N,size(S,1))+nan;
  tmp1 = zeros(N);
  tmp2 = zeros(N);
  s = zeros(numel(indx),1);
  for k = 1:size(C,3)
    s(indx) = S(k,:);
    tmp1(triangle_low) = s(1:n);
    tmp2(triangle_low) = s(n+(1:n));
    C(:,:,k) = tmp1+tmp2';
  end

else
  
  C = zeros(N,N,size(S,1));
  for k = 1:size(C,3)
    tmp = zeros(N);
    tmp(indx) = S(k,:);
    C(:,:,k) = tmp;
  end
  
end