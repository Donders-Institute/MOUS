function [mri] = mous_anatomy_coregCTF(mri, pos)

% [MRI] = MOUS_ANATOMY_COREGCTF coregisters T1-weighted image
% to the coordinate system used in the MEG-data. this
% requires a set of dicom images, and a Polhemus pos file
%
% $Id: mous_anatomy_coregCTF.m 39 2012-05-08 11:12:46Z jansch $

% do an initial coregistration
cfg             = [];
cfg.interactive = 'yes';
mri = ft_volumerealign(cfg, mri);
T   = mri.transform;

% read in the Polhemus file
pos = ft_convert_units(pos, 'mm');

% get the fiducial info
fidu  = pos.fid;
nas   = fidu.pnt(strcmp(fidu.label,'nas'),:);
lcoil = fidu.pnt(strcmp(fidu.label,'Lcoil'),:);
rcoil = fidu.pnt(strcmp(fidu.label,'Rcoil'),:);

% convert the fiducials to voxels
cfg = [];
cfg.fiducial.nas = warp_apply(inv(T), nas);
cfg.fiducial.lpa = warp_apply(inv(T), lcoil);
cfg.fiducial.rpa = warp_apply(inv(T), rcoil);

% realign
mri  = ft_volumerealign(cfg, mri);
