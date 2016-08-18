function output = mous_powspctrm_biascorrect(input, varargin)

% MOUS_POWSPCTRM_BIASCORRECT performs a bias correction on a powspctrm,
% based on the DOF

if ~isfield(input, 'dof'), error('the input data should contain a ''dof'' field'); end

parameter = ft_getopt(varargin, 'parameter', 'powspctrm');
if strcmp(parameter, 'powspctrm')
  m = repmat(shiftdim(input.dof./2,-1),[numel(input.label) 1 1]);
elseif strcmp(parameter, 'avg')
  m = input.dof;
  cfg = [];
  cfg.operation = 'x1.^2';
  cfg.parameter = parameter;
  input = ft_math(cfg, input);
elseif strcmp(parameter, 'trial')
  %m = repmat(shiftdim(input.dof,-1),[numel(input.trial,1) 1 1]);
  m = input.dof;
  cfg = [];
  cfg.operation = 'x1.^2';
  cfg.parameter = parameter;
  input = ft_math(cfg, input);
end


cfg           = [];
cfg.operation = 'log(x1)-psi(s)+log(s)';
cfg.matrix    = m;
cfg.parameter = parameter;
output = ft_math(cfg, input);