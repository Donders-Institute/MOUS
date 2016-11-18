function mous_write_atlas(inputfile, filename, rgba)

if nargin==0  
  inputfile = 'atlas_conte69_8196reg_LR_brodmann_subparc';
  filename  = 'atlas_subparc.L.4k_fs_LR.label.gii';
end
if ischar(inputfile)
  load(inputfile);
elseif isstruct(inputfile)
  atlas = inputfile;
end

parc = cast(atlas.parcellation,'int32');
n    = numel(parc)./2;

% do the left hemisphere
g             = gifti;
g.cdata       = parc(1:n);
g.private.data{1}.data = parc(1:n);
sel           = match_str(atlas.parcellationlabel, atlas.parcellationlabel(unique(g.cdata)));
g.private.data{1}.data = cast(g.private.data{1}.data-min(g.private.data{1}.data),'int32')';%zero-based
g.private.data{1}.attributes.DataType = 'NIFTI_TYPE_INT32';
g.private.data{1}.attributes.Intent = 'NIFTI_INTENT_LABEL';
g.private.label(1).name = atlas.parcellationlabel(sel)';
g.private.label(1).key  = sel(:)'-min(sel);
if exist('rgba', 'var'),
  g.private.label(1).rgba = rgba(sel,:);
else
  g.private.label(1).rgba = rand(numel(g.private.label(1).key),4);
  g.private.label(1).rgba(:,4) = 1;
end
%g.labels = g.private.label(1);
save(g, filename);

% do the right hemisphere
g             = gifti;
g.cdata       = parc(n+(1:n));
g.private.data{1}.data = parc(n+(1:n));
sel           = match_str(atlas.parcellationlabel, atlas.parcellationlabel(unique(g.cdata)));
g.private.data{1}.data = cast(g.private.data{1}.data-min(g.private.data{1}.data),'int32')';%zero-based
g.private.data{1}.attributes.DataType = 'NIFTI_TYPE_INT32';
g.private.data{1}.attributes.Intent = 'NIFTI_INTENT_LABEL';
g.private.label(1).name = atlas.parcellationlabel(sel)';
g.private.label(1).key  = sel(:)'-min(sel);
if exist('rgba', 'var'),
  g.private.label(1).rgba = rgba(sel,:);
else
  g.private.label(1).rgba = rand(numel(g.private.label(1).key),4);
  g.private.label(1).rgba(:,4) = 1;
end
%g.labels = g.private.label(1);
save(g, strrep(filename, '.L.', '.R.'));
