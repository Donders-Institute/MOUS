function mous_anatomy_qualitycheck_coregistration(subjectname, rootdir, fidflag)

if nargin<2 || isempty(rootdir), rootdir = '/project/3011020.09/MEG'; end
if nargin<3 || isempty(fidflag), fidflag = 0; end

if fidflag
  mous_db_getdata(subjectname, 'meg_anatomy_coreginfo_fiducials', rootdir);
else
  mous_db_getdata(subjectname, 'meg_anatomy_coreginfo', rootdir);
end
  
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
mous_db_putdata(subjectname, 'meg_anatomy_figure_coreg2', h, rootdir);
