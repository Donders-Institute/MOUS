function [Anew,Snew,Resnorm1,exitflag1,Resnorm2,exitflag2] = dual_regression(S,A,X,n)

[N,M] = size(X);
nn    = N/n;
ncomp = size(S,1);

Anew = cell(1,n);
Snew = cell(1,n);
Resnorm1  = cell(1,n);
exitflag1 = cell(1,n);
Resnorm2  = cell(1,n);
exitflag2 = cell(1,n);
for k = 1:n
  Anew{k} = zeros(nn, ncomp);
  Snew{k} = zeros(ncomp,  M);
  Resnorm1{k}  = zeros(nn, 1);
  exitflag1{k} = zeros(nn, 1);
  Resnorm2{k}  = zeros(1, ncomp);
  exitflag2{k} = zeros(1, ncomp);
end

S = S.';
for k = 1:n
  fprintf('processing subject %d...\n',k);
  Z = X((k-1)*nn+(1:nn),:)';
  fprintf('regression 1');
%   for kk = 1:nn
%     fprintf('.');
%     [Anew{k}(kk,:),Resnorm1{k}(kk,1),~,exitflag1{k}(kk,1)] = lsqnonneg(S, Z(:,kk));
%   end
  Anew{k} = kfcnnls(S,Z);
  fprintf('\nregression 2');
  Z = Z.';
%   for kk = 1:M
%     if mod(kk,250)==0,
%       fprintf('.');
%     end
%     [Snew{k}(:,kk),Resnorm2{k}(1,kk),~,exitflag2{k}(1,kk)] = lsqnonneg(Anew{k}, Z(:,kk));
%   end
  Snew{k} = kfcnnls(Anew{k}',Z);
  fprintf('\n');
end
