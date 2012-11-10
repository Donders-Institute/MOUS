function sourcemodel = prepareTemplategrid(resolution)

fname   = '/home/language/jansch/matlab/mri/templateMRI.nii';
mri     = ft_read_mri(fname);
mri.coordsys = 'spm';

cfg             = [];
segment         = ft_volumesegment(cfg, mri);

cfg             = [];
cfg.method      = 'singleshell';
headmodel       = ft_prepare_headmodel(cfg ,segment);

for k = 1:numel(resolution)
  
  res         = resolution(k);
  pnt         = headmodel.bnd.pnt;
  tri         = headmodel.bnd.tri;
  nrm         = normals(pnt, tri, 'vertex');
  pnt         = pnt - nrm*res*1.5;
  
  tmpheadmodel = headmodel;
  tmpheadmodel.bnd.pnt = pnt;
  tmpheadmodel.bnd.tri = tri;
  
  minpnt     = min(pnt,[],1);
  maxpnt     = max(pnt,[],1);
  
  %x-coords is the left-right axis in this coordinate frame:
  %ensure symmetricity
  xlim   = max(abs(minpnt(1)), maxpnt(1)) + res*2;
  xgrid  = sort([-0.5*res:-res:-xlim 0.5*res:res:xlim]);
  
  sens.coilori = [0 0 1];
  sens.coilpos = [0 0 20];
  sens.chanpos = [0 0 20];
  sens.chanori = [0 0 1];
  sens.label   = {'chan01'};
  sens.tra     = 1;
  
  cfg            = [];
  cfg.grid.xgrid = xgrid;
  cfg.grid.ygrid = (floor(minpnt(2))-res):res:(maxpnt(2)+res);
  cfg.grid.zgrid = (floor(minpnt(3))-res):res:(maxpnt(3)+res);
  sourcemodel{k} = ft_prepare_sourcemodel(cfg, tmpheadmodel, sens);
  sourcemodel{k} = ft_convert_units(sourcemodel{k});
end
