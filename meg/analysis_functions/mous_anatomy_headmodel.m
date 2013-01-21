function [vol] = mous_anatomy_headmodel(mri, thr)

% MOUS_ANATOMY_HEADMODEL computes the singleshell volume conductor
% model, based on the segmentation of the subject's anatomical MRI
%
% $Id: mous_anatomy_headmodel.m 39 2012-05-08 11:12:46Z jansch $ 

if nargin==1
  thr = 0.5;
end

% segment the mri
cfg = [];
cfg.output = 'brain';
cfg.brainthreshold = thr;
seg = ft_volumesegment([], mri);

% create the vol
cfg = [];
cfg.method = 'singleshell';
vol = ft_prepare_headmodel(cfg, seg);
