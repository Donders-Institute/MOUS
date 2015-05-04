function data = mous_granger_getdata_masked(filename, mask_edges, mask_frequency)

% MOUS_GRANGER_GETDATA_MASKED loads in the GC data and selects a subset of
% it according to the specified masks.
%
% Use as
%  data = mous_granger_getdata_masked(filename, mask_edges, mask_frequency)
%
% Input arguments:
%  filename
%  mask_edges     = boolean NxN matrix
%  mask_frequency = boolean 1xM vector
%
% Output argument:
%  data = fieldtrip data structure with GC spectra linearly indexed


% the following assumes that the relevant data are stored with variable name 'g'
load(filename, 'g');
if nargin<3
  mask_frequency = true(1,numel(g.freq));
end

data        = [];
data.freq   = double(g.freq(mask_frequency));
data.dimord = 'chancmb_freq';

tmpout  = zeros(sum(mask_edges(:)),sum(mask_frequency));
cnt = 0;
for k = find(mask_frequency)
  cnt = cnt+1;
  tmp = g.grangerspctrm(:,:,k);
  tmpout(:,cnt) = double(tmp(mask_edges)); 
end
data.grangerspctrm = tmpout;

[i1,i2]  = find(mask_edges);
data.labelcmb = [g.label(i1) g.label(i2)];
