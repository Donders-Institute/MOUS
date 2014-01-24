function [bnd] = mous_anatomy_sourcemodel2D(bnd, mri1, mri2)

% write some documentation here

T   = mri1.transform/mri2.transform;
bnd = ft_convert_units(bnd, 'mm');
bnd = ft_transform_geometry(T, bnd);
bnd = ft_convert_units(bnd, 'cm');

bnd.pos = bnd.pnt;
bnd     = rmfield(bnd, 'pnt');


