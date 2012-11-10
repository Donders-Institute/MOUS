function source3d = mous_mne_2dto3d(subjectname, source2d, varargin)

% MOUS_MNE_2DTO3D interpolates mne results (computed on the cortical sheet)
% onto a 3D regular grid that can be easily used for group statistics a la
% FieldTrip, or interpolated to another 2D sheet.
%
% Input arguments:
%   subjectname = string, name of the subject (needed to interface with
%     database)
%   source2d    = source-structure with MNE results. Should contain the
%     triangulation of the UNINFLATED sheet.
%   
%
% Output arguments:
%   source3d    = source-structure with MNE results, interpolated onto a
%     3D-grid. Coordinate system is according to the MNI template.

resolution = ft_getopt(varargin, 'resolution', 5);

% create individual 3D grid based on the MNI-template with specified
% resolution.
[p,f,e] = fileparts(which('mous_mne_2dto3d'));
fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', 'standard_sourcemodel3d5mm.mat');
load(fname);
template = sourcemodel;

cfg     = [];
cfg.mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF'); 
cfg.mri.coordsys = 'ctf';
cfg.grid.warpmni   = 'yes';
cfg.grid.template  = template;
cfg.grid.nonlinear = 'yes';
target  = ft_prepare_sourcemodel(cfg);

cfg     = [];
cfg.parameter = ft_getopt(varargin, 'parameter', 'avg.pow');
cfg.interpmethod = ft_getopt(varargin, 'interpmethod', 'sphere_avg');
cfg.sphereradius = ft_getopt(varargin, 'sphereradius', 1);
source3d = ft_sourceinterpolate(cfg, source2d, target);

source3d.pos      = template.pos;
source3d.coordsys = 'spm';


