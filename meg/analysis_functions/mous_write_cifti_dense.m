function mous_write_cifti_dense(filename, data, varargin)

% MOUS_WRITE_CIFTI_DENSE writes a dense cifti surface file
% 
% Use as
%   mous_write_cifti_dense(filename, data, varargin)
%
% Input arguments:
%   filename = string, name of the file
%   data     = structure, of matrix containing the functional data
%   varargin = set of key-value pairs for additional arguments

param   = ft_getopt(varargin, 'parameter', 'avg');
surface = ft_getopt(varargin, 'surface',   []);
inside  = ft_getopt(varargin, 'inside',    []);
time    = ft_getopt(varargin, 'time',      []);
freq    = ft_getopt(varargin, 'freq',      []);

if isstruct(data)
  if ~isfield(data, 'pos') && isempty(surface)
    error('if the input data does not contain topological information about the surfaces, it needs to be provided in the input arguments');
  elseif ~isfield(data, 'pos') && ~isempty(surface)
    pos = surface.pos;
  elseif isfield(data, 'pos') && isempty(surface)
    pos = data.pos;
    surface = data;
  elseif isfield(data, 'pos') && ~isempty(surface)
    error('either data should contain topological information, or the additionally specified surface, not both');
  end

  data = data.(param);
elseif isnumeric(data)
  % data is numeric, then a surface should be present
  if isempty(surface)
    error('when numeric data is in the input, there should be a surface');
  end
  pos = surface.pos;
else
  error('data input should either be numeric or a struct');
end

if size(data,1)<size(pos,1) && isempty(inside)
  error('an inside vector should be provided in the input');
elseif size(data,1)<size(pos,1)
  siz     = size(data);
  tmpdata = zeros([size(pos,1),siz(2:end)]);
  tmpdata(inside,:,:,:,:) = data;
  data = tmpdata;
  clear tmpdata;
end

surface.(param) = data;
if ~isempty(time),
  surface.time = time;
  surface.dimord = 'pos_time';
end

% ensure that the data has a 'brainstructure' field
% assume that the first half of vertices is left and the other half is
% right
if ~isfield(surface, 'brainstructure')
  n = size(surface.pos,1)./2;
  surface.brainstructure      = [ones(n,1);ones(n,1)*2];
  surface.brainstructurelabel = {'CORTEX_LEFT';'CORTEX_RIGHT'};
end
cfg           = [];
cfg.filename  = filename;
cfg.filetype  = 'cifti';
cfg.parameter = param;
ft_sourcewrite(cfg, surface);
