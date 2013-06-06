function [sourcemodelout] = mous_anatomy_sourcemodelparcellate(subjectname, sourcemodelin)

% MOUS_ANATOMY_SOURCEMODELPARCELLATE parcellates a 3D sourcemodel using the
% automatic segmentation from freesurfer

rootdir = '/home/language/jansch/public/mous';

% ensure mm units
sourcemodelin = ft_convert_units(sourcemodelin, 'mm');

% define the source positions in original voxel coordinates, using the
% MRI coregistered to the CTF coordinate system, the voxel coordinates are
% subsequently the same as in the coregMNI volume
mrictf  = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
vox2ctf = mrictf.transform;
voxpos  = warp_apply(inv(vox2ctf), sourcemodelin.pos);

% define the source positions in voxel coordinates, according to the MRI
% volumes after they have been processed by mri_convert. The world
% coordinate system is AC-PC based, and matches the one in the coregMNI
filename = fullfile('/home/language/annhul/MOUS/meg/',subjectname,'anatomy',subjectname,'mri','orig.mgz');
mrimni1 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
mrimni2 = ft_read_mri(filename);
vox2vox = mrimni2.transform\mrimni1.transform; %transforms from vox in 1 to vox in 2
voxpos  = warp_apply(vox2vox, voxpos);

% read in the atlas
filename = fullfile('/home/language/annhul/MOUS/meg/',subjectname,'anatomy',subjectname,'mri','aparc+aseg.mgz');
atlas    = ft_read_atlas(filename);
for k = 1:numel(atlas.aparclabel)
  % replace dashes by underscores
  tmp = atlas.aparclabel{k};
  tmp = strrep(tmp, '-', '_');
  tmp = strrep(tmp, '3', 'thir');
  tmp = strrep(tmp, '4', 'four');
  tmp = strrep(tmp, '5', 'fif');
  atlas.aparclabel{k} = tmp;
end

% label the points in the sourcemodel according to the closest atlas point.
sourcemodelout = sourcemodelin;
mask           = false(size(sourcemodelout.pos,1),1);
for k = 1:numel(atlas.aparclabel)
  sourcemodelout.(atlas.aparclabel{k}) = mask;
end

dim      = atlas.dim;
[x,y,z]  = ndgrid(1:dim(1),1:dim(2),1:dim(3));
voxatlas = [x(:) y(:) z(:)];
voxatlas(atlas.aparc==0,:)  = [];
atlas.aparc(atlas.aparc==0) = [];
clear x y z;
for k = 1:size(voxpos,1)
  if any(sourcemodelin.inside==k)
    d = (voxatlas(:,1)-voxpos(k,1)).^2 + ...
        (voxatlas(:,2)-voxpos(k,2)).^2 + ...
        (voxatlas(:,3)-voxpos(k,3)).^2;
    
    % identify the points that are closer than 15 mm
    id = d<=15;
    
    % identify the label values
    val = setdiff(unique(atlas.aparc(id)),0);
    for m = 1:numel(val)
      sourcemodelout.(atlas.aparclabel{val(m)})(k) = true;
    end
  else
    continue;
  end
end



% sourcemodelout.aparc = zeros(size(sourcemodelout.pos,1),1);
% sourcemodelout.label = {};
% 
% dim      = atlas.dim;
% [x,y,z]  = ndgrid(1:dim(1),1:dim(2),1:dim(3));
% voxatlas = [x(:) y(:) z(:)];
% voxatlas(atlas.aparc==0,:)  = [];
% atlas.aparc(atlas.aparc==0) = [];
% clear x y z;
% for k = 1:size(voxpos,1)
%   if any(sourcemodelin.inside==k)
%     d = (voxatlas(:,1)-voxpos(k,1)).^2 + ...
%         (voxatlas(:,2)-voxpos(k,2)).^2 + ...
%         (voxatlas(:,3)-voxpos(k,3)).^2;
%     [md, id] = min(d);
%     sourcemodelout.aparc(k) = atlas.aparc(id);
%   else
%     continue;
%   end
% end
% val = unique(sourcemodelout.aparc);
% val = setdiff(val, 0);
% aparc = sourcemodelout.aparc;
% for k = 1:numel(val)
%   % reindex the aparc values to run from 1 until the number of unique
%   % parcels
%   aparc(sourcemodelout.aparc==val(k)) = k;
% end
% sourcemodelout.aparc      = aparc;
% sourcemodelout.aparclabel = atlas.aparclabel(val);
