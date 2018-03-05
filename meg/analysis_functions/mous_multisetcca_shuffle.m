function [Y, allshufvec] = mous_multisetcca_shuffle(X, blocks)

if iscell(blocks)
  % shuffle trials and subjects, but maintain the shuffling across
  % blocks of subjects
  rng('shuffle');
  for m = 1:numel(blocks)
    allshufvec(blocks{m},:) = repmat(randperm(numel(X{1}.trial)), numel(blocks{m}), 1);
  end
else
  allshufvec = blocks;
end

Y = shuffletrials(X, allshufvec, 2);
