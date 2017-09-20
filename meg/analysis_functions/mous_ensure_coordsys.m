function object = hcp_ensure_coordsys(object, transform, desired)

if ~isfield(object, 'coordsys')
  % this one returns an updated structure
  object = ft_determine_coordsys(object);
end

if strcmp(object.coordsys, desired)
  % nothing to do
else
  T = transform.(sprintf('%s2%s', object.coordsys, desired));
  object = ft_transform_geometry(T, object);
  object.coordsys = desired;
end
