function [h1, data1, h2, data2] = mous_anatomy_reregister_compare(subjectname, rootdir)

%% this function is used to check whether the fix in ft_volumerealign (r9096)
% has a noticeable effect on the quality of the coregistration. Before, the
% coregistration was not optimal, since the output of the icp algorithm was
% not passed on. Yet, if the manual initial coregistration was good enough
% this should not be too big of a deal (and it could work either way, if
% the subsequent icp step (especially with only few headshape points) moves
% the solution away from a visual OK solution

if nargin<2
  rootdir = '/project/3011020.09/MEG';
end

mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF', rootdir);
pos = mous_db_getdata(subjectname, 'meg_raw_pos');
mous_db_getdata(subjectname, 'meg_anatomy_coreginfo', rootdir);

data1.mri      = mri;
data1.shape    = shape;
data1.shapemri = shapemri;

h1 = makeplot(shape, shapemri);

[mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, shape, shapemri, 2);

[mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, 0, 1);
[mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, shape, shapemri, 1);
h2 = makeplot(shape, shapemri);

data2.mri      = mri;
data2.shape    = shape;
data2.shapemri = shapemri;


function h = makeplot(shape, shapemri)

% quality check for the coregistration between headshape and mri
headshape    = ft_convert_units(shape,    'mm');
headshapemri = ft_convert_units(shapemri, 'mm');

v = headshapemri.pnt;
f = headshapemri.tri;
[f,v]=reducepatch(f,v, 0.2);
headshapemri.pnt = v;
headshapemri.tri = f;

h = figure;
subplot('position',[0.01 0.51 0.48 0.48]);hold on;
ft_plot_mesh(headshapemri,'edgecolor','none','facecolor',[0.5 0.6 0.8],'fidcolor','y','facealpha',0.3);
ft_plot_headshape(headshape,'vertexsize',5); view(180,-90);
plot3([-130 130],[0 0],[0 0],'k');plot3([0 0],[-120 120],[0 0],'k');plot3([0 0],[0 0],[-100 150],'k');
subplot('position',[0.51 0.51 0.48 0.48]);hold on;
ft_plot_mesh(headshapemri,'edgecolor','none','facecolor',[0.5 0.6 0.8],'fidcolor','y','facealpha',0.3);
ft_plot_headshape(headshape,'vertexsize',5); view(0,90);
plot3([-130 130],[0 0],[0 0],'k');plot3([0 0],[-120 120],[0 0],'k');plot3([0 0],[0 0],[-100 150],'k');
subplot('position',[0.01 0.01 0.48 0.48]);hold on;
ft_plot_mesh(headshapemri,'edgecolor','none','facecolor',[0.5 0.6 0.8],'fidcolor','y','facealpha',0.3);
ft_plot_headshape(headshape,'vertexsize',5); view(90,0);
plot3([-130 130],[0 0],[0 0],'k');plot3([0 0],[-120 120],[0 0],'k');plot3([0 0],[0 0],[-100 150],'k');
subplot('position',[0.51 0.01 0.48 0.48]);hold on;
ft_plot_mesh(headshapemri,'edgecolor','none','facecolor',[0.5 0.6 0.8],'fidcolor','y','facealpha',0.3);
ft_plot_headshape(headshape,'vertexsize',5); view(0,0);
plot3([-130 130],[0 0],[0 0],'k');plot3([0 0],[-120 120],[0 0],'k');plot3([0 0],[0 0],[-100 150],'k');
axis on;
grid on;
set(gcf,'color','w')
