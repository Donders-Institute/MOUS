function varargout = mous_stratify(cfg, varargin)

% MOUS_STRATIFY stratifies the input data arguments with respect to a
% certain quantity
%
% Use as [datout1, datout2] = mous_stratify(cfg, {datin1 v1}, {datin2 v2})
%
% Where the input data arguments should be organised in cell-array (each
% cell having two elements, where the first element is the data structure,
% and the second element is a vector with length numel(datain.trial), with
% the quantity to be stratified

if numel(varargin)>2
  %error('more than 2 data input arguments are not supported');
end

cfg.equalbinavg = ft_getopt(cfg, 'equalbinavg', 'no');

for k = 1:numel(varargin)
  data{k} = varargin{k}{1};
  v{k}    = varargin{k}{2};
  if size(v{k},1)>size(v{k},2)
    v{k} = v{k}';
  end
end

out = ft_stratify(cfg, v{:});

tmpcfg = [];
for k = 1:numel(varargin)
  tmpcfg.trials = find(isfinite(out{k}));
  varargout{k}  = ft_selectdata(tmpcfg, data{k});
end
