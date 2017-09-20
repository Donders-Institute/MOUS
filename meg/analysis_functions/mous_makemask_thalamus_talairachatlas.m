atlas=ft_read_atlas('/home/language/jansch/projects/mous/meg/templates/atlas_talairach_mni.mat');

% make a selection of the labels that pertain to the thalamus
sel = (~cellfun('isempty',strfind(atlas.tissuelabel,'Thalamus'))|~cellfun('isempty',strfind(atlas.tissuelabel,'Geniculum')))&cellfun('isempty',strfind(atlas.tissuelabel,'Mammillary'));
sel = find(sel);
ok  = false(size(sel));
for k = 1:numel(sel)
  tok = tokenize(atlas.tissuelabel{sel(k)}, '.');
  ok(k) = ~strcmp(tok{end},'*');
end
sel = sel(ok);

% mask the atlas
atlas.tissue(~ismember(atlas.tissue, sel)) = 0;

% re-index
for k = 1:numel(sel)
  atlas.tissue(atlas.tissue==sel(k)) = k;
end
atlas.tissuelabel = atlas.tissuelabel(sel);

[sourcemodelout] = mous_anatomy_sourcemodelparcellate(subjectname, sourcemodelin, 'atlas', atlas, 'parcelparam', 'tissue');