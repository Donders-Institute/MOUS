function [data] = mous_mne_parcellate(source, tlck, parcellation, varargin)

hasavg   = isfield(tlck, 'avg');
if ~hasavg, error('input timelock structure should have an avg-field'); end
hastrial = isfield(tlck, 'trial');

parcelparam = ft_getopt(varargin, 'parcelparam', 'parcellation');


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
  S = zeros(nparc, 1);
  N = S;
  for k = 1:nparc
    sel = intersect(find(parc==k), source.inside);
    f   = cat(1, source.avg.filter{sel});
    if size(f,1)>0
      dat = f;%*tlck.avg;
      c   = dat*dat';
      [u,s,v] = svd(c);
      U{k} = u(:,1)';
      F(k,:) = u(:,1)'*f;
      S(k,1) = s(1)./sum(diag(s));
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

avg = F*tlck.avg;
if hastrial
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
