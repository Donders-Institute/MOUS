function [seg] = mous_anatomy_skullstrip(mri)

% [SEG] = MOUS_ANATOMY_SKULLSTRIP computes the skullstripped MRI based on
% the subject's anatomical MRI (coregMNIresliced)
%
% $Id: mous_anatomy_skullstrip.m 39 2012-05-08 11:12:46Z jansch $

% segment the mri
cfg        = [];
cfg.output = 'skullstrip';
cfg.smooth = 5;
seg = ft_volumesegment(cfg, mri);
