function [seg, mask] = mous_anatomy_skullstrip(subjectname, threshold, center)

% [SEG, MASK] = MOUS_ANATOMY_SKULLSTRIP computes the skullstripped MRI based on
% the subject's anatomical MRI (coregMNI)
%
% $Id: mous_anatomy_skullstrip.m 39 2012-05-08 11:12:46Z jansch $

% segment the mri
%cfg        = [];
%cfg.output = 'skullstrip';
%cfg.smooth = 2;
%seg = ft_volumesegment(cfg, mri);

d   = '/home/language/annhul/MOUS/meg/';
str = ['/opt/fsl/bin/bet ',d,subjectname,'/anatomy/',subjectname,'coregMNI.nii ',d,subjectname,'/anatomy/',subjectname,'coregMNIskullstrip '];
str = [str,'-R -f ',num2str(threshold),' -c ', num2str(center),' -g 0 -m -v'];

system(str);
seg  = ft_read_mri([d,subjectname,'/anatomy/',subjectname,'coregMNIskullstrip.nii.gz']);
mask = ft_read_mri([d,subjectname,'/anatomy/',subjectname,'coregMNIskullstrip_mask.nii.gz']);
