function object = hcp_ensure_units(object, desired)

if ~isfield(object, 'unit')
  % this one returns a string
  object = ft_convert_units(object);
end

if strcmp(object.unit, desired)
  % nothing to do
else
  object = ft_convert_units(object, desired);
end
