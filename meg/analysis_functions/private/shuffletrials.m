function [X] = shuffletrials(X, shufvec)

% helper function to shuffle the trials, keeping the overall
% autocorrelation as much as possible

for k = 1:numel(X)
  tmp = cat(2, X{k}.trial{:});
      
  nsmp       = cellfun('size', X{k}.trial, 2);
  sampleaxis = 1:sum(nsmp);
  smpx       = mat2cell(sampleaxis, 1, nsmp);
  smpx_shuf  = smpx(shufvec(k,:));
  tmp        = tmp(:, cat(2, smpx_shuf{:}));
  for m = 1:numel(smpx)
    X{k}.trial{m} = tmp(:,smpx{m});
  end
end
