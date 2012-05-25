function [grid] = mous_anatomy_sourcemodel3Dnonlin(mri, resolution)

% create the grid
cfg = [];
cfg.grid.warpmni    = 'yes';
cfg.grid.resolution = resolution;
cfg.grid.nonlinear  = 'yes';
cfg.mri = mri;
grid = ft_prepare_sourcemodel(cfg);

% remove the mri-structure from grid.cfg
grid.cfg = rmfield(grid.cfg, 'mri');