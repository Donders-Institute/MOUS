function source2d = mous_mne_3dto2d(source3d, varargin)

target = ft_getopt(varargin, 'target');
method = ft_getopt(varargin, 'method', 'fieldtrip');

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
    system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetleft, giftiname1));
    system(sprintf('%s/wb_command -volume-to-surface-mapping %s %s %s -trilinear', wbpath, niftiname, targetright, giftiname2));
    system(sprintf('%s/wb_command -cifti-create-dense-timeseries %s -left-metric %s -right-metric %s', wbpath, ciftiname, giftiname1, giftiname2));
    
    source2d = ciftiname;
    
  otherwise
    error('unknown method of interpolation requested');
end
