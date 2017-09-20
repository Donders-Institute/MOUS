function [sR,S,A,W,iq, sel] = mous_granger_icasso(X, opts)


SR.index = zeros(0,2);
for k = 1:15
  [sR,S,A,W,iq,sel] = mous_granger_ica(subj, method, opts);
  SR.A{k} = A;
  SR.W{k} = W;
  SR.index = cat(1, SR.index, [k*ones(opts.ncomp,1) (1:opts.ncomp)']);
end

sR.whiteningMatrix = eye(ncomp);
sR.dewhiteningMatrix = eye(size(V,2));
sR.mode = 'both';
sR.signal = V';

% get a concatenation of the unmixing matrices 
%tmp = icassoGet(sR, 'W');
tmp = cat(2,sR.A{:});
C   = tmp'*tmp;
C   = C./sqrt(diag(C)*diag(C)');
C(C>1) = 1;
C(C<-1)= -1;

sR=icassoCluster(sR,'strategy','AL','simfcn',C,'s2d','sim2dis','L','rdim');
sR=icassoProjection(sR,'cca','s2d','sqrtsim2dis','epochs',75);
[Iq, mixing, unmixing, dat] = icassoShow(sR, 'estimate', 'off');

savedir = '/project/3011020.09/jansch/results/20150328_granger';
sR = ft_struct2single(sR);
system(['mkdir -p ',savedir]);
filename = fullfile(savedir, 'granger_nmf_alpha');
W = single(W);
save(filename, 'W', 'sR', 'Iq', 'mixing', 'unmixing', 'sel', 'label');
