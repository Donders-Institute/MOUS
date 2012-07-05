function [seg] = mous_anatomy_skullstrip(subjectname, threshold)

% [SEG] = MOUS_ANATOMY_SKULLSTRIP computes the skullstripped MRI based on
% the subject's anatomical MRI (coregMNI)
%
% $Id: mous_anatomy_skullstrip.m 39 2012-05-08 11:12:46Z jansch $

% segment the mri
%cfg        = [];
%cfg.output = 'skullstrip';
%cfg.smooth = 2;
%seg = ft_volumesegment(cfg, mri);

d   = '/home/language/annhul/MOUS/Processed/';
str = ['/opt/fsl/bin/bet ',d,subjectname,'/meg_anatomy/',subjectname,'coregMNI ',d,subjectname,'/meg_anatomy/',subjectname,'coregMNIskullstrip '];
str = [str,'-R -f ',num2str(threshold),' -g 0 -m'];

system(str);

