function [peaks, val1, val2, grangerout] = mous_granger_getpeaks(granger, varargin)

% MOUS_GRANGER_GETPEAKS estimates the frequencies at which the granger
% spectrum is peaking.
%
% It assumes chan_chan_freq in input.
% Approach: smooth spectrum, standardize, peakdetect

krn       = ft_getopt(varargin, 'krn', gausswin(7,6));
threshold = ft_getopt(varargin, 'threshold', 3);
foilim    = ft_getopt(varargin, 'foilim',    [0 140]);
numpeak   = ft_getopt(varargin, 'numpeak',   'all');

foilim(1) = nearest(granger.freq, foilim(1));
foilim(2) = nearest(granger.freq, foilim(2));

if ischar(numpeak) && strcmp(numpeak, 'all')
  keeppeaks = inf;
elseif ischar(numpeak)
  error('numpeak can assume either the value ''all'' or should be numeric');
else
  keeppeaks = numpeak;
end

Nchan = numel(granger.label);
p = cell(Nchan);
datsmooth = zeros(size(granger.grangerspctrm));
for k = 1:Nchan
  fprintf('detecting peaks in channel %d from %d\n',k, Nchan);
  dat = squeeze(granger.grangerspctrm(:,k,:));
  tmp = ft_preproc_smooth(dat, krn(:)');
  datsmooth(:,k,:) = tmp;
  
  dat = ft_preproc_standardize(tmp);
  for m = 1:size(dat,1)
    p{m,k} = peakdetect2(dat(m,foilim(1):foilim(2)), threshold);
  end
end

grangerout = granger;
grangerout.grangerspctrm = datsmooth;

for k = 1:numel(p)
  if isempty(p{k}),
    p{k} = nan;
  elseif numel(p{k})>1
    %p{k} = p{k}(p{k}>nsmooth);
    if ~isempty(p{k}) && ~isfinite(keeppeaks)
      p{k} = p{k};
    elseif ~isempty(p{k})
      p{k} = p{k}(1:min(numel(p{k}),keeppeaks));
    else
      p{k} = nan;
    end
    p{k} = p{k} + foilim(1) - 1; % account for foilim(1) offset
  else
    p{k} = p{k} + foilim(1) - 1;
  end
end

npeaks = max(cellfun(@numel,p(:)));
peaks  = zeros([size(p) npeaks])+nan;
val1   = zeros(size(p))+nan;
val2   = val1;

for k = 1:Nchan
  fprintf('computing the peak values in channel %d from %d\n',k, Nchan);
  dat  = squeeze(granger.grangerspctrm(:,k,:));
  tmp = ft_preproc_smooth(dat, krn(:)');
  
  dat  = tmp;
  dats = ft_preproc_standardize(tmp);
  datsmooth(:,k,:) = tmp;
  
  for m = 1:size(dat,1)
    if all(isfinite(p{m,k}))
      n             = numel(p{m,k});
      val1(m,k,1:n) = dat(m,p{m,k});
      val2(m,k,1:n) = dats(m,p{m,k});
      peaks(m,k,1:n) = p{m,k};
    end
  end
end
