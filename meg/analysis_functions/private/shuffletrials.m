function [X] = shuffletrials(X, shufvec, methodflag)

if nargin<3
  methodflag=1;
end

% helper function to shuffle the trials, keeping the overall
% autocorrelation as much as possible

if methodflag==1
  % this does a random reordering of the trials while using all
  % samples, but disobeying the trial boundaries
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
elseif methodflag==2
  nsmp = cellfun('size',X{1}.trial,2);
  
  % this does a random reordering of the trials and obeys the onsets of the
  % trials, discarding sample at the end (if the shuffled trial is shorter
  % than its original counterpart, and adding nans, if longer
  for k = 1:numel(X)
    tmp = X{k}.trial(shufvec(k,:));
    nchan = numel(X{k}.label);
    for m = 1:numel(tmp)
      tmptrial = nan(nchan, nsmp(m));
      endsmp   = min(nsmp(m),size(tmp{m},2));  
      tmptrial(:,1:endsmp) = tmp{m}(:,1:endsmp);
      X{k}.trial{m} = tmptrial;
    end
  end
end