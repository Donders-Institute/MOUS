function source2d = mous_mne_3dto2d(source3d, varargin)

target = ft_getopt(varargin, 'target');

if isempty(target)
  [p,f,e] = fileparts(which('mous_mne_3dto2d'));
  fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', 'canonicalmesh');
  load(fname);
  target = ft_convert_units(canonicalmesh, 'cm');
end

cfg              = [];
cfg.parameter    = ft_getopt(varargin, 'parameter',    'avg.pow');
cfg.interpmethod = ft_getopt(varargin, 'interpmethod', 'sphere_avg');
cfg.sphereradius = ft_getopt(varargin, 'sphereradius', 1);
source2d         = ft_sourceinterpolate(cfg, source3d, target);
