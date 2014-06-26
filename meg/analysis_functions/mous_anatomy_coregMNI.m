function [mri, T] = mous_anatomy_coregMNI(mri)

% [mri] = mous_anatomy_coregMI(mri) coregisters T1-weighted images
% to the MNI coordinate system.
%
% $Id: mous_anatomy_coregMNI.m 39 2012-05-08 11:12:46Z jansch $

% do the coregistration
cfg             = [];
cfg.interactive = 'yes';
cfg.coordsys    = 'spm';
mri = ft_volumerealign(cfg, mri);
T   = mri.transform;
