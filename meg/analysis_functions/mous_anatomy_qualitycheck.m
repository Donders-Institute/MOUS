function [h1,h2,h3,h4,h5,h6,h7] = mous_anatomy_qualitycheck(subjectname, varargin)

% MOUS_ANATOMY_QUALITYCHECK does a number of quality control checks on the
% ouput of the anatomy pipeline, mainly relying on visual inspection of a
% number of output figures and test files.
%
% Use as
%   mous_anatomy_qualitycheck(subjectname)
%
% For example
%   mous_anatomy_qualitycheck('V1020')
%
% See also MOUS_ANATOMY_PIPELINE, MOUS_ENSURE_UNITS

visible = ft_getopt(varargin, 'visible', 'on');

close all

headmodel     = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
sourcemodel2d = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D');
sourcemodel3d = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
mri           = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  

% [p, f, x] = fileparts(filename);
% 
% % check the content of the file
% fn = whos('-file', filename);
% fn = {fn.name};
% % if ~all(ismember({'filename' 'mri' 'fiducials' 'landmarks' 'transform' 'headmodel' 'sourcemodel2d' 'sourcemodel3d'}, fn))
% if ~all(ismember({'filename' 'fiducials' 'landmarks' 'transform' 'headmodel' 'sourcemodel2d' 'sourcemodel3d'}, fn))
%   error('not all required fields are present in the anatomy file');
% end
% 
% load(filename)

% ensure that they all are represented in a consistent coordinate system
% mri           = mous_ensure_coordsys(mri, transform, 'bti');
% fiducials     = mous_ensure_coordsys(fiducials, transform, 'bti');
% headmodel     = mous_ensure_coordsys(headmodel, transform, 'bti');
% sourcemodel2d = mous_ensure_coordsys(sourcemodel2d, transform, 'bti');
% sourcemodel3d = mous_ensure_coordsys(sourcemodel3d, transform, 'bti');

% ensure that they all have consistent units
mri           = mous_ensure_units(mri, 'mm');
%fiducials     = mous_ensure_units(fiducials, 'mm');
headmodel     = mous_ensure_units(headmodel, 'mm');
sourcemodel2d = mous_ensure_units(sourcemodel2d, 'mm');
sourcemodel3d = mous_ensure_units(sourcemodel3d, 'mm');

% define some helper functions
viewtop    = @() view(  0,  90);
viewbottom = @() view(180, -90);
viewleft   = @() view(180,   0);
viewright  = @() view(  0,   0);
viewfront  = @() view( 90,   0); % FIXME this might also be back

h1 = figure('visible',visible);
subplot(2,2,1); hold on; ft_plot_vol(headmodel), viewbottom();
subplot(2,2,2); hold on; ft_plot_vol(headmodel), viewtop();
subplot(2,2,3); hold on; ft_plot_vol(headmodel), viewleft();
subplot(2,2,4); hold on; ft_plot_vol(headmodel), viewright();
axis on
grid on
title(subjectname);

h2 = figure('visible',visible);
subplot(2,2,1); hold on; ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:)); viewbottom();
subplot(2,2,2); hold on; ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:)); viewtop();
subplot(2,2,3); hold on; ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:)); viewleft();
subplot(2,2,4); hold on; ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:)); viewright();
axis on
grid on
title(subjectname);

h3 = figure('visible',visible);
clear ft_plot_slice
subplot(2,2,1); hold on; ft_plot_slice(mri.anatomy, 'location', [0  0 60], 'orientation', [0 0 1], 'transform', mri.transform, 'intersectmesh', {sourcemodel2d headmodel.bnd}); viewtop();
subplot(2,2,2); hold on; ft_plot_slice(mri.anatomy, 'location', [0  0 20], 'orientation', [0 0 1], 'transform', mri.transform, 'intersectmesh', {sourcemodel2d headmodel.bnd}); viewtop();
subplot(2,2,3); hold on; ft_plot_slice(mri.anatomy, 'location', [0 20  0], 'orientation', [1 0 0], 'transform', mri.transform, 'intersectmesh', {sourcemodel2d headmodel.bnd}); viewfront();
subplot(2,2,4); hold on; ft_plot_slice(mri.anatomy, 'location', [0 20  0], 'orientation', [0 1 0], 'transform', mri.transform, 'intersectmesh', {sourcemodel2d headmodel.bnd}); viewright();
set(gcf, 'Renderer', 'zbuffer');
title(subjectname);

h4 = figure('visible',visible);
ft_plot_montage(mri.anatomy, 'location', [0 0 0], 'orientation', [0 0 1], 'transform', mri.transform, ...
  'slicerange', [-20 120], 'nslice', 16, 'intersectmesh', {sourcemodel2d headmodel.bnd}, 'intersectlinewidth', 1);
set(gcf, 'Renderer', 'zbuffer');
title(subjectname,'color','r');

h5 = figure('visible',visible);
ft_plot_montage(mri.anatomy, 'location', [0 0 0], 'orientation', [0 1 0], 'transform', mri.transform, ...
  'slicerange', [-60 60], 'nslice', 16, 'intersectmesh', {sourcemodel2d headmodel.bnd}, 'intersectlinewidth', 1);
set(gcf, 'Renderer', 'zbuffer');
title(subjectname,'color','r');

h6 = figure('visible',visible);
ft_plot_montage(mri.anatomy, 'location', [0 0 0], 'orientation', [1 0 0], 'transform', mri.transform, ...
  'slicerange', [-60 120], 'nslice', 16, 'intersectmesh', {sourcemodel2d headmodel.bnd}, 'intersectlinewidth', 1);
set(gcf, 'Renderer', 'zbuffer');
title(subjectname,'color','r');

% plot some figures to check the coregistration between volume conductor
% and cortical sheet
h7 = figure('visible',visible);
subplot(2,2,1);hold on;ft_plot_vol(headmodel, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(sourcemodel2d); view([0 0]);
subplot(2,2,2);hold on;ft_plot_vol(headmodel, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(sourcemodel2d); view([0 90]);
subplot(2,2,3);hold on;ft_plot_vol(headmodel, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(sourcemodel2d); view([90 0]);

mous_db_putdata(subjectname, 'meg_anatomy_figure_headmodel',           h1);
mous_db_putdata(subjectname, 'meg_anatomy_figure_sourcemodel3d',       h2);
mous_db_putdata(subjectname, 'meg_anatomy_figure_sourcemodel2d',       h3);
mous_db_putdata(subjectname, 'meg_anatomy_figure_sourcemodel2dslice1', h4);
mous_db_putdata(subjectname, 'meg_anatomy_figure_sourcemodel2dslice2', h5);
mous_db_putdata(subjectname, 'meg_anatomy_figure_sourcemodel2dslice3', h6);
mous_db_putdata(subjectname, 'meg_anatomy_figure_coreg',               h7);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function writetextfile(filename, str)
fid = fopen(filename, 'wt');
fwrite(fid, str);
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft_plot_fiducials(fiducials)
x = fiducials.nas(1);
y = fiducials.nas(2);
z = fiducials.nas(3);
plot3(x, y, z, 'b*');
x = fiducials.lpa(1);
y = fiducials.lpa(2);
z = fiducials.lpa(3);
plot3(x, y, z, 'b*');
x = fiducials.rpa(1);
y = fiducials.rpa(2);
z = fiducials.rpa(3);
plot3(x, y, z, 'b*');


