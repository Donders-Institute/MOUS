function sourcemodel = mous_anatomy_sourcemodelparcellate_combined(subjectname, resolution)

sourcemodel1 = mous_anatomy_sourcemodelparcellate_cortical(subjectname);
sourcemodel1 = ft_convert_units(sourcemodel1, 'm');
sourcemodel2 = mous_anatomy_sourcemodelparcellate_subcortical(subjectname, resolution);
sourcemodel2 = ft_convert_units(sourcemodel2, 'm');

npnt1       = size(sourcemodel1.pos,1);
sourcemodel = sourcemodel1;
sourcemodel.inside = (1:npnt1)';

sourcemodel.pos     = [sourcemodel.pos;sourcemodel2.pos];
sourcemodel.inside  = [sourcemodel.inside(:);sourcemodel2.inside(:)+npnt1];
sourcemodel.outside = sourcemodel2.outside+npnt1;

% re-index the subcortical parcels, apart from the 0's
tmp = sourcemodel2.tissue;
tmp(tmp>0) = tmp(tmp>0) + max(sourcemodel.tissue(:));

sourcemodel.tissue      = [sourcemodel.tissue;tmp];
sourcemodel.tissuelabel = [sourcemodel.tissuelabel;sourcemodel2.tissuelabel];

% add another parcellation
sourcemodel.type    = zeros(size(sourcemodel.pos,1),1);
sourcemodel.type(1:npnt1)       = 1;
sourcemodel.type((npnt1+1):end) = 2;
sourcemodel.typelabel = {'cortex_mesh'; 'subcortex_grid'};
