function data = createdummystructure(input, label, lay, alphathreshold, indx)

% this is a helper function that is used many times and formats the input
% data such that topoplotCC can swallow it

data           = [];
data.dimord    = 'chan_chan';
data.freq      = 0;
data.cohspctrm = zeros(numel(label));
data.widthpos  = zeros(numel(label));
data.widthneg  = zeros(numel(label));
data.label     = label;

if isfield(input, 'stat_t')
  fname = 'stat_t';
elseif isfield(input, 'stat_a')
  fname = 'stat_a';
elseif isfield(input, 'stat_b')
  fname = 'stat_b';
end

tmp                 = input.(fname).stat;
tmpprob             = input.(fname).prob;
data.widthpos(indx) = abs(tmp)-min(abs(tmp(:)));
data.widthneg(indx) = abs(tmp)-min(abs(tmp(:)));

tmp(tmpprob>alphathreshold)     = 0; % only color the statistically thresholded values
data.cohspctrm(indx)            = tmp;
data.widthpos(data.cohspctrm<0) = 0; 
data.widthneg(data.cohspctrm>0) = 0;

[a,b] = match_str(data.label,lay.label);
data  = ft_selectdata(data,'channel', data.label(a));
