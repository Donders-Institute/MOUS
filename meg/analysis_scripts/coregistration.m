% This script describes how to do the coregistration of the anatomical MRI with
% the coordinate system that is used by the MEG-scanner.
%
% The procedure consists of 2 steps:
% 1 Coregistration of the MRI with the anatomical landmarks that can be inter-
%    actively found in the anatomical image. This gives an approximate
%    coregistration, because the fiducials on which the coordinate system is 
%    based that is used in the MEG-scanner are in the ear canals.
% 2 Coregistation to the ear canal based fiducials, using the information from
%    the polhemus file. This can be achieved because the ear canal fiducials
%    are defined in the anatomical landmarks based coordinate system.


% read in the mri
filename = 's120116092449STD131221107523235034-0003-00002-000256-01.nii';
mri = ft_read_mri(filename);
% FIXME there is no vitamine E marker that defines the right, so we have to 
% rely on the coordinate transformation matrix in the nifti file.
% What is the definition of the axes? It could be LAS or RAS 
%
% According to Julia, if no flip is introduced by the Dicom2nifti conversion
% it is LAS

%---- coregistration step 1
% be sure to also mark a point with a positive z-coordinate (pressing 'z')
% to ensure correct orientation of the z-axis (preventing left-right flip)
cfg = [];
cfg.method = 'interactive';
mri2 = ft_volumerealign(cfg, mri);

% check whether this is OK
ft_determine_coordsys(mri2);

%---- coregistration step 2

% read in the polhemus data
hs = ft_read_headshape('p004.pos');

% express the coordinates in mri voxel space (needed for ft_volumerealign)
hs = ft_transform_geometry(inv(mri2.transform), ft_convert_units(hs, 'mm'));

cfg = [];
cfg.method = 'fiducial';
cfg.fiducial.nas = hs.fid.pnt(strcmp('nas',   hs.fid.label),:);
cfg.fiducial.lpa = hs.fid.pnt(strcmp('Lcoil', hs.fid.label),:);
cfg.fiducial.rpa = hs.fid.pnt(strcmp('Rcoil', hs.fid.label),:);
mri3 = ft_volumerealign(cfg, mri2);



