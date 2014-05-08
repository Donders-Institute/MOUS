function mous_drawparcel(sourcemodel, atlas, label)

% MOUS_DRAWPARCEL draws a sourcemodel (cortical sheet) with the
% parcels specified in the input, based on atlas (Brodmann
% parcellation).
%
% Use as:
%   mous_drawparcel(sourcemodel, atlas, label)
%
% Input arguments:
%   sourcemodel = structure defining a cortical sheet
%   atlas = parcellation of the sourcemodel (currently only support for
%   Brodmann parcellation from caret)
%   label = string or cell-array, of named labels to visualize

if ischar(label)
  label = {label};
end

sel = match_str(atlas.parcellationlabel, label);
dum = atlas.parcellation;
dum(~ismember(dum,sel)) = nan;
 
figure;hold on;
if isfield(sourcemodel, 'sulc')
  s = sourcemodel.sulc-min(sourcemodel.sulc)+1;
  s = s./max(s+0.5);
  ft_plot_mesh(sourcemodel, 'edgecolor', 'none', 'vertexcolor', repmat(s(:),[1 3]));
else
  ft_plot_mesh(sourcemodel, 'edgecolor', 'none', 'vertexcolor', [0.5 0.5 0.5]);
end
ft_plot_mesh(sourcemodel, 'edgecolor', 'none', 'vertexcolor', dum);
  


