function source2d = mous_mne_3dto2d(source3d, varargin)

target = ft_getopt(varargin, 'target');
method = ft_getopt(varargin, 'method', 'fieldtrip');
parcellation = ft_getopt(varargin, 'parcellation', []);

switch method
  case 'fieldtrip'
    % this is the old way of doing it, use it as default
    if isempty(target)
      [p,f,e] = fileparts(which('mous_mne_3dto2d'));
      fname   = fullfile(p(1:end-18), 'templates', 'sourcemodel', 'canonicalmesh');
      load(fname);
      target = ft_convert_units(canonicalmesh, 'cm');
    end
    
    cfg              = [];
    cfg.parameter    = ft_getopt(varargin, 'parameter',    'avg.pow');
    cfg.interpmethod = ft_getopt(varargin, 'interpmethod', 'sphere_avg');
    cfg.sphereradius = ft_getopt(varargin, 'sphereradius', 1);
    source2d         = ft_sourceinterpolate(cfg, source3d, target);

    if ~isempty(parcellation)
      % do parcellation
      cfg = [];
      cfg.method    = ft_getopt(varargin, 'parcellationmethod', 'mean');
      cfg.parameter = ft_getopt(varargin, 'parameter', 'avg.pow');
      cfg.parcellation = 'parcellation';
      
      % assume the source2d positions to topologically match the
      % parcellatoin
      parcellation.pos = source2d.pos;
      
      source2d = ft_sourceparcellate(cfg, source2d, parcellation);
    end
  
  case 'wb'
    % this is the new way of doing it, use it when specified
    
    filename  = ft_getopt(varargin, 'filename');
    parameter = ft_getopt(varargin, 'parameter');
    
    if isempty(filename)
      error('when using workbench for the interpolation you need to supply a filename');
    end
    if isempty(parameter)
      error('you should supply a parameter for the interpolation');
    end
    [p,f,e]  = fileparts(filename);
    filename = fullfile(p,[f,'.nii']);
   
    % save the data as a nifti file
    cfg = [];
    cfg.filename = filename;
    cfg.filetype = 'nifti';
    cfg.parameter = parameter;
    ft_sourcewrite(cfg, source3d);
    
    % specify some filenames for the conversion
    niftiname  = filename;
    giftiname1 = strrep(filename, '.nii', '.L.gii');
    giftiname2 = strrep(filename, '.nii', '.R.gii');
    ciftiname  = strrep(filename, '.nii', '.dtseries.nii');
    
    [p,f,e] = fileparts(which('mous_mne_3dto2d'));
    targetleft = fullfile(p(1:end-18), 'templates', 'cortex.L.midthickness.4k_fs_LR.surf.gii');
    targetright = strrep(targetleft, '.L.', '.R.');
    
    wbpath = '/project/3011020.09/workbench/bin_rh_linux64';
    % potentially first (two) is baseline: [(-0.15,) -0.1, 0.25 0.35 0.45]
    % workbench assumes equal time steps therefore [-0.l, 0.25 0.35 0.45
    % will look like 0.25 0.35 0.45 0.55] 
    if isfield(source3d, 'time') && numel(source3d.time)>1
      tmp = find(sign(source3d.time) > 0);
      tstep  = sprintf('%2.2f',source3d.time(tmp(2))-source3d.time(tmp(1)));  
      %tstart = sprintf('%2.2f',source3d.time(tmp(1))); 
      tstart = sprintf('%2.2f',source3d.time(1));
      system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetleft, giftiname1));
      system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetright, giftiname2));
      system(sprintf('%s/wb_command -cifti-create-dense-timeseries %s -left-metric %s -right-metric %s -timestep %s -timestart %s', wbpath, ciftiname, giftiname1, giftiname2,tstep,tstart));
    else
      system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetleft, giftiname1));
      system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetright, giftiname2));
      system(sprintf('%s/wb_command -cifti-create-dense-timeseries %s -left-metric %s -right-metric %s', wbpath, ciftiname, giftiname1, giftiname2));
    end
    source2d = ciftiname;
    
    delete(niftiname);
    delete(giftiname1);
    delete(giftiname2);
    
  otherwise
    error('unknown method of interpolation requested');
end
