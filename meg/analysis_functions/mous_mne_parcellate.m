function [data] = mous_mne_parcellate(source, tlck, parcellation, varargin)

hasavg   = isfield(tlck, 'avg');
if ~hasavg, error('input timelock structure should have an avg-field'); end
hastrial = isfield(tlck, 'trial');

parcelparam = ft_getopt(varargin, 'parcelparam', 'parcellation');
svdmethod   = ft_getopt(varargin, 'svdmethod',   'projectfilt');
R           = ft_getopt(varargin, 'R', []);

parc      = parcellation.(parcelparam);
parclabel = parcellation.([parcelparam,'label']);
nparc     = numel(parclabel);


if ~isfield(source.avg, 'filter')
  error('the input source structure should contain spatial filters');
end
if ~isfield(source, 'inside')
  source.inside = 1:size(source.pos,1);
end

if hastrial, 
  ntrial = size(tlck.trial,1);
  trial  = zeros(ntrial, nparc, numel(tlck.time));
end

if isfield(parcellation, 'filter')
  F = parcellation.filter;
  U = nan;
  S = nan;
  N = nan;
else  
  F = zeros(nparc, size(source.avg.filter{source.inside(1)},2));
  U = cell(nparc,1);
  S = zeros(nparc, 10)+nan;
  N = S;
  for k = 1:nparc
    sel = intersect(find(parc==k), source.inside);
    f   = cat(1, source.avg.filter{sel});
    if size(f,1)>0
      switch svdmethod
        case 'projectfilt'
          dat = f;%*tlck.avg;
        case 'projectavg'
          %dat = f*tlck.avg;
          dat = f*tlck.avg(:,nearest(tlck.time,0):end);
      end
      c   = dat*dat';
      [u,s,v] = svd(c);
      ix      = 1:min(size(s,1),10);
      S(k,ix) = cumsum(diag(s(ix,ix)))./sum(diag(s));
      
      if ~isempty(R)
        iy = find(S(k,:)>R,1,'first');
        if isempty(iy), iy = 1; end
      else
        iy = 1;
      end
      
      U{k} = u(:,1:iy)';
      for m = 1:iy
        F(k,:,m) = u(:,m)'*f;
      end
      if isfield(source.avg, 'noisecov')
        n = blkdiag(source.avg.noisecov{sel});
        n = u(:,1)'*n*u(:,1);
        N(k,1) = n(1,1);
      else
        N(k,1) = nan;
      end
    else
      U{k} = nan;
      F(k,:) = nan;
      S(k,1) = nan;
      N(k,1) = nan;
    end
  end
end

if size(F,3)==1
  avg = F*tlck.avg;
else
  avg = zeros(size(F,1),0);
  for m = 1:size(F,3)
    avg = cat(2,avg,F(:,:,m)*tlck.avg);
  end
end
if hastrial
  if size(F,3)>1
    error('multiple trials in combination with more than one component is not allowed');
  end
  for m= 1:ntrial
    trial(m,:,:) = F*shiftdim(tlck.trial(m,:,:));
  end  
end

% create the output
data       = [];
data.avg   = avg;
data.label = parclabel;
data.time  = tlck.time;
data.dimord = tlck.dimord;
data.S      = S;
data.N      = N;
data.F      = F;
data.U      = U;
if hastrial,                   data.trial     = trial;          end
if isfield(tlck, 'trialinfo'), data.trialinfo = tlck.trialinfo; end
