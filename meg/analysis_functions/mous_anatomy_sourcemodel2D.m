function [bnd, h] = mous_anatomy_sourcemodel2D(bnd, mri1, mri2, vol)

% write some documentation here

T   = mri1.transform/mri2.transform;
bnd = ft_convert_units(bnd, 'mm');
bnd = ft_transform_geometry(T, bnd);
bnd = ft_convert_units(bnd, 'cm');

% plot some figures to check the coregistration
h(1) = figure;hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([0 0]);
h(2) = figure;hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([0 90]);
h(3) = figure;hold on;ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.5; ft_plot_mesh(bnd); view([90 0]);