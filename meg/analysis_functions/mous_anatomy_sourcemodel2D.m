function [bnd, h] = mous_anatomy_sourcemodel2D(bnd, mri1, mri2, vol)

% write some documentation here

T   = mri1.transform/mri2.transform;
bnd = ft_convert_units(bnd, 'mm');
bnd = ft_transform_geometry(T, bnd);
bnd = ft_convert_units(bnd, 'cm');

bnd.pos = bnd.pnt;
bnd     = rmfield(bnd, 'pnt');

% plot some figures to check the coregistration
h = figure;
subplot(2,2,1);hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([0 0]);
subplot(2,2,2);hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([0 90]);
subplot(2,2,3);hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([90 0]);
