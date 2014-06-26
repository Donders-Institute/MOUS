function [mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, interactiveflag, refineflag, repositionflag)

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

if nargin>=4 && isstruct(interactiveflag)
  shape = interactiveflag;
  interactiveflag = 0;
  shapemri = refineflag;
  refineflag = 0;
else
  shape = [];
  shapemri = [];
end
if nargin<2
  pos = [];
end
if nargin<3
  interactiveflag = [];
end
if nargin<4
  refineflag = [];
end
if nargin<5
  repositionflag = [];
end
if isempty(interactiveflag)
  interactiveflag = 1;
end
if isempty(refineflag)
  refineflag = 0;
end
if isempty(repositionflag)
  repositionflag = 0;
end

if interactiveflag
  % do an initial coregistration
  cfg             = [];
  cfg.interactive = 'yes';
  cfg.coordsys    = 'ctf';
  mri = ft_volumerealign(cfg, mri);
  T   = mri.transform;
end

% refine the coregistration (optionally) based on the polhemus point cloud
if refineflag==1
  fid     = pos.fid;
  sel     = strcmp('lpa', fid.label) | strcmp('rpa', fid.label) | strcmp('nas', fid.label);
  pos.pnt = cat(1,pos.pnt, pos.fid.pnt(sel,:));
  
  cfg           = [];
  cfg.method    = 'headshape';
  cfg.headshape = pos;
  cfg.weights   = ones(size(pos.pnt,1),1);
  %cfg.weights(pos.pnt(:,1)>9 | pos.pnt(:,1)<-4) = 100;
  %cfg.weights(pos.pnt(:,3)<0 & cfg.weights>1)   = 200;
  cfg.weights(end-2:end,:) = 1;
  
  mri.coordsys  = 'ctf';
  mri           = ft_volumerealign(cfg, mri);

  shape        = struct(mri.cfg.headshape.headshape); % convert back from config object
  shapemri     = struct(mri.cfg.headshape.headshapemri);
elseif refineflag==2
  shape    = ft_convert_units(pos, 'mm');
  
  % extract skull surface from image
  tmpcfg        = [];
  tmpcfg.output = 'scalp';
  tmpcfg.smooth = 2;
  seg           = ft_volumesegment(tmpcfg, mri);
  
  tmpcfg             = [];
  tmpcfg.method      = 'singleshell';
  tmpcfg.numvertices = 20000;
  shapemri        = ft_prepare_headmodel(tmpcfg, seg);
  shapemri        = ft_convert_units(shapemri, 'mm');
  
else
  % do nothing here
end

% re-interpret the coordinate system by swapping the lpa and rpa (defining
% the coordinate system in the polhemus-file and thus by construction on
% the previously computed data objects, with the lcoil and rcoil (defining
% the coordinate system used during acquisition of MEG data.
if repositionflag==1 && ~isempty(pos)
  T   = mri.transform;
  pos = ft_convert_units(pos, 'mm');
  
  % get the fiducial info
  fidu  = pos.fid;
  nas   = fidu.pnt(strcmp(fidu.label,'nas'),:);
  lcoil = fidu.pnt(strcmp(fidu.label,'Lcoil'),:);
  rcoil = fidu.pnt(strcmp(fidu.label,'Rcoil'),:);
  
  % convert the fiducials to voxels
  cfg = [];
  cfg.fiducial.nas = ft_warp_apply(inv(T), nas);
  cfg.fiducial.lpa = ft_warp_apply(inv(T), lcoil);
  cfg.fiducial.rpa = ft_warp_apply(inv(T), rcoil);
  
  % realign
  mri   = ft_volumerealign(cfg, mri);
  
  % also realign the shape and the shapemri
  if ~isempty(shape)
    shape    = ft_transform_geometry(mri.transform/T, shape);
    shapemri = ft_transform_geometry(mri.transform/T, shapemri);
  end
elseif repositionflag==2 && ~isempty(pos)
  % transform back from a coil-based (i.e. ear canal) to a fiducial-based
  % coordinate system. Don't use this unless you know what you're doing
  T   = mri.transform;
  pos = ft_convert_units(pos, 'mm');
  
  % get the fiducial info
  if ~isempty(shape)
    fidu  = shape.fid;
  else
    error('going back to a coil based coordinate system requires a shape variable');
  end
  nas   = fidu.pnt(strcmp(fidu.label,'nas'),:);
  lcoil = fidu.pnt(strcmp(fidu.label,'Lcoil'),:);
  rcoil = fidu.pnt(strcmp(fidu.label,'Rcoil'),:);
  lpa   = fidu.pnt(strcmp(fidu.label,'lpa'),:);
  rpa   = fidu.pnt(strcmp(fidu.label,'rpa'),:);
  zpoint = [0 0 100];
  
  nas_vox = ft_warp_apply(inv(T), nas);
  lcoil_vox = ft_warp_apply(inv(T), lcoil);
  rcoil_vox = ft_warp_apply(inv(T), rcoil);
  lpa_vox = ft_warp_apply(inv(T), lpa);
  rpa_vox = ft_warp_apply(inv(T), rpa);
  zpoint_vox = ft_warp_apply(inv(T), zpoint);
  
  T_vox2coil = ft_headcoordinates(nas_vox, lcoil_vox, rcoil_vox, zpoint_vox, 'ctf');
  T_vox2fid  = ft_headcoordinates(nas_vox, lpa_vox, rpa_vox, zpoint_vox, 'ctf');
  
  % realign
  mri.transform = T_vox2fid;
  
  % also realign the shape and the shapemri
  if ~isempty(shape)
    shape    = ft_transform_geometry(mri.transform/T, shape);
    shapemri = ft_transform_geometry(mri.transform/T, shapemri);
  end
  
end

