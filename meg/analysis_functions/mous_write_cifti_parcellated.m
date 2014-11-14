function mous_write_cifti_parcellated(filename, data, varargin)

% MOUS_WRITE_CIFTI_PARCELLATED writes a parcelalted cifti surface file
% 
% Use as
%   mous_write_cifti_parcellated(filename, data, varargin)
%
% Input arguments:
%   filename = string, name of the file
%   data     = structure
%   varargin = set of key-value pairs for additional arguments

param   = ft_getopt(varargin, 'parameter', 'avg');
parcellation = ft_getopt(varargin, 'parcellation');

if isempty(parcellation)
  error('to write a parcellated cifti file, a parcellation needs to be provided');
end

data.brainordinate = parcellation;

cfg           = [];
cfg.filename  = filename;
cfg.filetype  = 'cifti';
cfg.parameter = param;
ft_sourcewrite(cfg, data);
