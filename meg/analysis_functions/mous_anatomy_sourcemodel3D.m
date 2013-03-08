function [sourcemodel] = mous_anatomy_sourcemodel3D(mri, resolution)

% MOUS_ANATOMY_SOURCEMODEL3D computes a 3D regular grid with 
% specified resolution based on an inverse warp of a template
% grid in MNI space.
%
% Changelog: 26-02-2013: use templates in MOUS/meg/templates/ directory.
% This means recomputing all sourcemodels for all subjects. Reason: the
% default sourcemodels in FieldTrip are not fully covering the top of the
% brain.

[p,f,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', ['standard_sourcemodel3d',num2str(resolution),'mm.mat']);
load(fname);

% create the grid
cfg = [];
cfg.grid.warpmni    = 'yes';
%cfg.grid.resolution = resolution;
cfg.grid.template   = sourcemodel;
cfg.grid.nonlinear  = 'yes';
cfg.mri = mri;
sourcemodel = ft_prepare_sourcemodel(cfg);

% remove the mri-structure from grid.cfg
sourcemodel.cfg = rmfield(sourcemodel.cfg, 'mri');