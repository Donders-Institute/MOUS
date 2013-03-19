function [mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, interactiveflag, refineflag)

% [MRI] = MOUS_ANATOMY_COREGCTF coregisters T1-weighted image
% to the coordinate system used in the MEG-data. this
% requires mri structure, and a Polhemus pos file.
%
% Use as 
%   mri = mous_anatomy_coregCTF(mri, pos)
%   [mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, 1)
%
% If the optional third input is set to 'true' a refined coregistration is
% performed, using all points from the polhemus file, weighting the most
% anterior and posterior points more heavily for the icp algorithm.
%
% $Id: mous_anatomy_coregCTF.m 39 2012-05-08 11:12:46Z jansch $

if nargin<2
  pos = [];
end
if nargin<3 || isempty(interactiveflag)
  interactiveflag = 1;
end
if nargin<4
  refineflag = 0;
end

if interactiveflag
  % do an initial coregistration
  cfg             = [];
  cfg.interactive = 'yes';
  mri = ft_volumerealign(cfg, mri);
  T   = mri.transform;
  
  if ~isempty(pos)
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
  end
end

if refineflag
  cfg           = [];
  cfg.method    = 'headshape';
  cfg.headshape = pos;
  cfg.weights   = ones(size(pos.pnt,1),1);
  cfg.weights(pos.pnt(:,1)>9 | pos.pnt(:,1)<-6) = 100;
  
  mri.coordsys  = 'ctf';
  mri           = ft_volumerealign(cfg, mri);

  shape        = struct(mri.cfg.headshape); % convert back from config object
  shapemri     = struct(mri.cfg.headshapemri);
else
  shape    = [];
  shapemri = [];
end