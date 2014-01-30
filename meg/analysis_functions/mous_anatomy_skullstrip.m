function [seg, mask] = mous_anatomy_skullstrip(subjectname, threshold, center, rootdir)

% [SEG, MASK] = MOUS_ANATOMY_SKULLSTRIP computes the skullstripped MRI based on
% the subject's anatomical MRI (coregMNI)
%
% $Id: mous_anatomy_skullstrip.m 39 2012-05-08 11:12:46Z jansch $

% segment the mri
%cfg        = [];
%cfg.output = 'skullstrip';
%cfg.smooth = 2;
%seg = ft_volumesegment(cfg, mri);

d   = rootdir;
t   = tempname;
str = ['/opt/fsl_5.0.4/bin/bet ',d,filesep,subjectname,'/anatomy/',subjectname,'coregMNI.nii ',t];%,d,filesep,subjectname,'/anatomy/',subjectname,'coregMNIskullstrip '];
str = [str,'-R -f ',num2str(threshold),' -c ', num2str(center),' -g 0 -m -v'];
delete(t);

system(str);
seg  = ft_read_mri([t,'-R.nii.gz']);
mask = ft_read_mri([t,'-R_mask.nii.gz']);
delete([t,'-R.nii.gz']);
delete([t,'-R_mask.nii.gz']);
