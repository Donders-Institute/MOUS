function mous_createatlas

% THIS FUNCTION HAS BEEN WRITTEN IN AN ATTEMPT TO FIX AN ISSUE WHICH PROVED
% TO BE HARDLY POSSIBLE TO FIX. THE OUTPUT OF THIS FUNCTION (SAVED FILES
% ETC) HAVE NOT BEEN USED DOWNSTREAM.


% create a 8196_LR_reg node version based on the 32k Conte69 atlas to account for
% an inaccuracy in the previous atlas, due to the fact that this one was
% created from the 164k version of the Conte atlas, and this one was fishy.
% Yet, because all computations and cortical sheets are based on the 164k
% version of the topology the corrected 32k atlas needs to be remapped onto
% the 164k sheet, which then needs to be downsampled again.

atlasdir='/home/language/jansch/Conte69/32k_ConteAtlas_v2';

cd(atlasdir);
atlas = atlas_gii2mat('parcellations_VGD11b.L.32k_fs_LR.label.gii');
bnd   = ft_read_headshape({'Conte69.L.midthickness.32k_fs_LR.surf.gii' 'Conte69.R.midthickness.32k_fs_LR.surf.gii'});

atlasleft  = ft_read_atlas({'parcellations_VGD11b.L.32k_fs_LR.label.gii' 'Conte69.L.midthickness.32k_fs_LR.surf.gii'});
atlasright = ft_read_atlas({'parcellations_VGD11b.R.32k_fs_LR.label.gii' 'Conte69.R.midthickness.32k_fs_LR.surf.gii'});

% The left and right parcellations are not symmetric. the next steps make
% them symmetric. Given the spatial resolution of MEG this is not a big
% deal. Strategy: replace the non-matches with '???' if both are not
% ~'???', and replace the non-match from a pair where one is '???' with the
% label of the other one.
atlasleft.parcellation      = atlasleft.parcellation2;
atlasleft.parcellationlabel = atlasleft.parcellation2label;
atlasleft  = rmfield(atlasleft,  {'parcellation2' 'parcellation3' 'parcellation1' 'parcellation2label' 'parcellation3label' 'parcellation1label'});
atlasright.parcellation      = atlasright.parcellation2;
atlasright.parcellationlabel = atlasright.parcellation2label;
atlasright = rmfield(atlasright, {'parcellation2' 'parcellation3' 'parcellation1' 'parcellation2label' 'parcellation3label' 'parcellation1label'});
atlas.parcellation      = atlas.parcellation2;
atlas.parcellationlabel = atlas.parcellation2label;
atlas  = rmfield(atlas,  {'parcellation2' 'parcellation3' 'parcellation1' 'parcellation2label' 'parcellation3label' 'parcellation1label'});

sel = atlasleft.parcellation==1&atlasright.parcellation~=1;
atlasleft.parcellation(sel) = atlasright.parcellation(sel);
sel = atlasleft.parcellation~=1&atlasright.parcellation==1;
atlasright.parcellation(sel) = atlasleft.parcellation(sel);

C   = tri2connmat(atlasleft.tri);
sel = atlasleft.parcellation~=atlasright.parcellation;
for k = find(sel(:))'
  l = atlasleft.parcellation(k);
  r = atlasright.parcellation(k);
  
  L = atlasleft.parcellation(find(C(:,k)));
  R = atlasright.parcellation(find(C(:,k)));
  
  nl = sum(L==l);
  nr = sum(R==r);
  if nl>nr
    atlasright.parcellation(k) = l;
  elseif nr>nl
    atlasleft.parcellation(k) = r;
  elseif nl==nr
    % prefer the left over right, shouldn't matter too much
    atlasright.parcellation(k) = l;
  end
end
atlas.parcellation = [atlasleft.parcellation;atlasright.parcellation+43];

% now some wizardry is required to upsample the atlas to 164k meshes
% according to the Conte69 164k version, which was used as the target for
% the LR registration
clear all;

atlasdir2 = '/home/language/jansch/Conte69/Conte69_atlas_164k_wb';
cd(atlasdir2);

atlas = atlas_gii2mat('atlas_conte69.L.164k_fs_LR.label.gii');
bnd   = ft_read_headshape({'Conte69.L.midthickness.164k_fs_LR.surf.gii' 'Conte69.R.midthickness.164k_fs_LR.surf.gii'});


surfleft  = ft_read_headshape('Conte69.L.midthickness.164k_fs_LR.surf.gii');
surfright = ft_read_headshape('Conte69.R.midthickness.164k_fs_LR.surf.gii');

sphereleft  = ft_read_headshape('Sphere.164k.L.surf.gii');
sphereright = ft_read_headshape('Sphere.164k.R.surf.gii');

ft_hastoolbox('freesurfer',1);
write_surf('lh.midthickness',surfleft.pnt,surfleft.tri);
write_surf('lh.sphere',sphereleft.pnt,sphereleft.tri);
write_surf('rh.midthickness',surfright.pnt,surfright.tri);
write_surf('rh.sphere',sphereright.pnt,sphereright.tri);

% now the next step is to create a subdirectory 'mesh8196' with surf and
% bem, where the rh* and lh* need to be copied over into the surf
% directories. Next some mne wizardry creates the 8196 vertex mesh in the
% bem subfolder.

mesh8196 = ft_read_headshape(fullfile(atlasdir2,'mesh8196','bem','mesh8196-oct-6-src.fif'),'format','mne_source');
sel      = mesh8196.orig.inuse>0;

% merge the bnd with the atlas and subselect
bnd.parcellation = atlas.parcellation;
bnd.parcellationlabel = atlas.parcellationlabel;
atlas = bnd; clear bnd;

atlas.pnt = mesh8196.pnt;
atlas.tri = mesh8196.tri;
atlas.brainstructure = atlas.brainstructure(sel);
atlas.parcellation   = atlas.parcellation(sel);

% this atlas has been saved in
% ~/project/mous/meg/template/atlas_conte69_8196reg_LR, and the older
% version has been moved to corticalsheet_old_20141118, including the
% cortex_.... files: these need to be re-created, because the vertex to
% label mapping may be incorrect.



