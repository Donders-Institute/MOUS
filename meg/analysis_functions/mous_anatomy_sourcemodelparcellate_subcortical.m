function sourcemodel = mous_anatomy_sourcemodelparcellate_subcortical(subjectname, resolution)

mri          = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
mri.coordsys = 'ctf';
sourcemodel  = mous_anatomy_sourcemodel3D(mri, resolution);
sourcemodelin = sourcemodel;

atlasdir = '/opt/fsl_5.0.4/data/atlases/';
stdrddir = '/opt/fsl_5.0.4/data/standard/';

% Cerebellum
f_a = fullfile(atlasdir,'Cerebellum_MNIfnirt.xml');
f_m = fullfile(stdrddir,'MNI152_T1_1mm.nii.gz');
tmp = mous_anatomy_sourcemodelparcellate(subjectname,sourcemodelin,'filename_mri',f_m,'filename_atlas',f_a,'parcelparam','tissue');
tmp = reindex_parcellation(tmp);
for k = 1:numel(tmp.tissuelabel)
  tmp.tissuelabel{k} = ['Cerebellum ',tmp.tissuelabel{k}];
end

sourcemodel = tmp;

% Thalamus
f_a = fullfile(atlasdir,'Thalamus.xml');
tmp = mous_anatomy_sourcemodelparcellate(subjectname,sourcemodelin,'filename_mri',f_m,'filename_atlas',f_a,'parcelparam','tissue');
tmp = reindex_parcellation(tmp);
tmp = reindex_hemisphere(tmp);
tmp = reindex_parcellation(tmp);
for k = 1:numel(tmp.tissuelabel)
  tmp.tissuelabel{k} = ['Thalamus ',tmp.tissuelabel{k}];
end

% update the numbering
tmp.tissue(tmp.tissue>0) = tmp.tissue(tmp.tissue>0)+max(sourcemodel.tissue(:));

sourcemodel.tissue(tmp.tissue>0) = tmp.tissue(tmp.tissue>0);
sourcemodel.tissuelabel = [sourcemodel.tissuelabel;tmp.tissuelabel];

% Striatum
f_a = fullfile(atlasdir,'Striatum-Connectivity-7sub.xml');
tmp = mous_anatomy_sourcemodelparcellate(subjectname,sourcemodelin,'filename_mri',f_m,'filename_atlas',f_a,'parcelparam','tissue');
tmp = reindex_parcellation(tmp);
tmp = reindex_hemisphere(tmp);
tmp = reindex_parcellation(tmp); % just to be safe
for k = 1:numel(tmp.tissuelabel)
  tmp.tissuelabel{k} = ['Striatum ',tmp.tissuelabel{k}];
end

% update the numbering
tmp.tissue(tmp.tissue>0) = tmp.tissue(tmp.tissue>0)+max(sourcemodel.tissue(:));

sourcemodel.tissue(tmp.tissue>0) = tmp.tissue(tmp.tissue>0);
sourcemodel.tissuelabel = [sourcemodel.tissuelabel;tmp.tissuelabel];

% Juelich
f_a = fullfile(atlasdir,'Juelich.xml');
tmp = mous_anatomy_sourcemodelparcellate(subjectname,sourcemodelin,'filename_mri',f_m,'filename_atlas',f_a,'parcelparam','tissue');
tmp = reindex_parcellation(tmp);

% get everything that has to do with Amygdala, Hippocampus and Insula
sel = ~cellfun('isempty', strfind(tmp.tissuelabel, 'Insula'));
sel = sel | ~cellfun('isempty', strfind(tmp.tissuelabel, 'Amygdala'));
sel = sel | ~cellfun('isempty', strfind(tmp.tissuelabel, 'Hippocampus'));
tmp.tissue(~ismember(tmp.tissue,find(sel))) = 0;
tmp = reindex_parcellation(tmp);

% update the numbering
tmp.tissue(tmp.tissue>0) = tmp.tissue(tmp.tissue>0)+max(sourcemodel.tissue(:));

sourcemodel.tissue(tmp.tissue>0 & sourcemodel.tissue==0) = tmp.tissue(tmp.tissue>0 & sourcemodel.tissue==0);
sourcemodel.tissuelabel = [sourcemodel.tissuelabel;tmp.tissuelabel];

% redefine the insides
sourcemodel.inside  = find(sourcemodel.tissue > 0);
sourcemodel.outside = find(sourcemodel.tissue == 0);

function output = reindex_hemisphere(input)

left      = input.pos(:,2)>0;
right     = input.pos(:,2)<0;
undecided = input.pos(:,2)==0;

val       = unique(input.tissue(:));
tissue    = zeros(size(input.tissue));
tissuelabel = {};
cnt = 0;
for k = 2:numel(val)
  sel = input.tissue==val(k) & left;
  if ~isempty(sel)
    cnt = cnt+1;
    tissue(sel) = cnt;
    tissuelabel{end+1,1} = ['Left ',input.tissuelabel{k-1}];
  end
  sel = input.tissue==val(k) & right;
  if ~isempty(sel)
    cnt = cnt+1;
    tissue(sel) = cnt;
    tissuelabel{end+1,1} = ['Right ',input.tissuelabel{k-1}];
  end
end
output = input;
output.tissue = tissue;
output.tissuelabel = tissuelabel;

function output = reindex_parcellation(input)

% account for nans
input.tissue(~isfinite(input.tissue)) = 0;

val    = unique(input.tissue(:));
tissue = zeros(size(input.tissue));
for k = 1:numel(val)
  tissue(input.tissue==val(k)) = k-1;
end
output             = input;
output.tissue      = tissue;
output.tissuelabel = input.tissuelabel(val(2:end));