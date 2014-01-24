function [sourcemodelout] = mous_anatomy_sourcemodelparcellate(subjectname, sourcemodelin, varargin)

% MOUS_ANATOMY_SOURCEMODELPARCELLATE parcellates a 3D sourcemodel using the
% automatic segmentation from freesurfer

% assume that the mri and atlas are in the same voxel space! THIS IS NOT
% GUARANTEED!!!!!
filename_mri   = ft_getopt(varargin, 'filename_mri',   fullfile('/project/3011020.09/MEG/',subjectname,'anatomy',subjectname,'mri','orig.mgz'));
filename_atlas = ft_getopt(varargin, 'filename_atlas', fullfile('/project/3011020.09/MEG/',subjectname,'anatomy',subjectname,'mri','aparc+aseg.mgz'));
parcelparam    = ft_getopt(varargin, 'parcelparam',    'aparc');
segmentationstyle = ft_getopt(varargin, 'segmentationstyle', 'indexed');
atlas          = ft_getopt(varargin, 'atlas');

if isempty(atlas)
  % read in the atlas
  atlas = ft_read_atlas(filename_atlas);
else
  % do nothing
end

% ensure mm units
sourcemodelin = ft_convert_units(sourcemodelin, 'mm');

% define the source positions in original voxel coordinates, using the
% MRI coregistered to the CTF coordinate system, the voxel coordinates are
% subsequently the same as in the coregMNI volume
mrictf  = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
vox2ctf = mrictf.transform;
voxpos1 = ft_warp_apply(inv(vox2ctf), sourcemodelin.pos);

% define the source positions in voxel coordinates, according to the MRI
% volumes after they have been processed by mri_convert. The world
% coordinate system is AC-PC based, and matches the one in the coregMNI
mrimni1 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
if isfield(atlas, 'anatomy')
  T = atlas.transform;
else
  mrimni2 = ft_read_mri(filename_mri);
  T = mrimni2.transform;
  clear mrimni2;
end
vox2vox = T\mrimni1.transform; %transforms from vox in 1 to vox in 2
voxpos  = ft_warp_apply(vox2vox, voxpos1);

% rename the labels if segmentationstyle = probabilistic
if strcmp(segmentationstyle, 'probabilistic')
  
  for k = 1:numel(atlas.([parcelparam,'label']))
    % replace dashes by underscores
    tmp = atlas.([parcelparam,'label']){k};
    tmp = strrep(tmp, '-', '_');
    tmp = strrep(tmp, ' ', '_');
    tmp = strrep(tmp, '3', 'thir');
    tmp = strrep(tmp, '4', 'four');
    tmp = strrep(tmp, '5', 'fif');
    atlas.([parcelparam,'label']){k} = tmp;
  end
    
  % label the points in the sourcemodel according to the closest atlas point.
  sourcemodelout = sourcemodelin;
  mask           = false(size(sourcemodelout.pos,1),1);
  for k = 1:numel(atlas.([parcelparam,'label']))
    sourcemodelout.(atlas.([parcelparam,'label']){k}) = mask;
  end
  
  dim      = atlas.dim;
  [x,y,z]  = ndgrid(1:dim(1),1:dim(2),1:dim(3));
  voxatlas = [x(:) y(:) z(:)];
  voxatlas(atlas.(parcelparam)==0,:)  = [];
  atlas.(parcelparam)(atlas.(parcelparam)==0) = [];
  clear x y z;
  for k = 1:size(voxpos,1)
    if any(sourcemodelin.inside==k)
      d = (voxatlas(:,1)-voxpos(k,1)).^2 + ...
        (voxatlas(:,2)-voxpos(k,2)).^2 + ...
        (voxatlas(:,3)-voxpos(k,3)).^2;
      
      % identify the points that are closer than 15 mm
      id = d<=15;
      
      % identify the label values
      val = setdiff(unique(atlas.(parcelparam)(id)),0);
      for m = 1:numel(val)
        sourcemodelout.(atlas.([parcelparam,'label']){val(m)})(k) = true;
      end
    else
      continue;
    end
  end
  
elseif strcmp(segmentationstyle, 'indexed')
  
  tmp     = sourcemodelin;
  tmp.pos = ft_warp_apply(sourcemodelin.params,ft_warp_apply(sourcemodelin.initial,sourcemodelin.pos),'individual2sn');
  
  cfg = [];
  cfg.interpmethod = 'nearest';
  cfg.parameter    = parcelparam;
  tmp              = ft_sourceinterpolate(cfg, atlas, tmp);
  
  sourcemodelout     = sourcemodelin;
  sourcemodelout.([parcelparam,'label']) = atlas.([parcelparam,'label']);
  sourcemodelout.(parcelparam) = tmp.(parcelparam)(:);
  
end