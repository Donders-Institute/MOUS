function sourcemodel = mous_anatomy_sourcemodelparcellate_cortical(subjectname)

sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');

%load atlas_conte69_8196reg_LR;
%sourcemodel.tissue = atlas.parcellation4;
%sourcemodel.tissuelabel = atlas.parcellation4label;
load atlas_conte69_8196reg_LR_brodmann_subparc;
sourcemodel.tissue      = atlas.parcellation;
sourcemodel.tissuelabel = atlas.parcellationlabel;
sourcemodel = reindex_parcellation(sourcemodel);


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