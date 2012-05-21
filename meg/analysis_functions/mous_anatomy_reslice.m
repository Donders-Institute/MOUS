function [mri] = mous_anatomy_reslice(mri)

% [MRI] = MOUS_ANATOMY_RESLICE reslices the subject-specific
% T1-image of type type to ensure 1 mm isotropy and nice coordinate
% axes orientation.
%
% $Id: mous_anatomy_reslice.m 39 2012-05-08 11:12:46Z jansch $

cfg = [];
cfg.resolution = 1;
% if ~isempty(strfind(type, 'CTF'))
%   cfg.xrange     = [-100 144];
%   cfg.yrange     = [-90  90];
%   cfg.zrange     = [-50  149];
% elseif ~isempty(strfind(type, 'MNI'))
%   cfg.xrange     = [-90 90];
%   cfg.yrange     = [-120 135];
%   cfg.zrange     = [-140 100];
% else
%   error('unsupported input, should either be CTF or MNI space based');
% end
mri = ft_volumereslice(cfg, mri);
