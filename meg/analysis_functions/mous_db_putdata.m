function mous_db_putdata(subject, type, varargin)

% MOUS_DB_PUTDATA saves data from specified subject and type to 
% the database
%
% $Id: mous_db_putdata.m 48 2012-05-30 14:21:15Z jansch $

if numel(varargin)>1
  % it could be that the root directory is specified as last input argument
  if isdir(varargin{end})
    rootdir = varargin{end};
    varargin = varargin(1:end-1);
  else
    rootdir = '';
  end
else
  rootdir = '';
end
  
[filename, st] = mous_db_getfilename(subject, type, 0, rootdir);
if st(1)
  warning('file %s exists, overwriting existing file', filename{1});
end

if numel(varargin)>1
  % save as a mat file
  str = ['save(''',filename{1},''','''];
  for k = 3:nargin
    str = [str inputname(k), ''','''];
    eval([inputname(k),'=varargin{k-2};']);
  end
  str = [str(1:end-2),');'];
  eval(str);
  cmd = ['chmod g+w ' filename{1}];
  system(cmd);
  return;
end

data = varargin{1};
fprintf('putting data to file %s\n', filename{1});
if ft_datatype(data, 'volume')
  % save volumetric data as nifti
  cfg = [];
  cfg.filetype  = 'nifti';
  cfg.parameter = 'anatomy';
  cfg.filename  = filename{1};
  ft_volumewrite(cfg, data);
elseif ishandle(data)
 if exist(filename{1},'file'), system(['rm -rf ',filename{1}]); end
 print(data, '-dpng', filename{1});
elseif ~isempty(strfind(type, 'headmodel'))
  % save headmodel data as mat-file and name variable 'vol'
  vol = data;
  save(filename{1}, 'vol');
elseif ~isempty(strfind(type, 'sourcemodel'))
  sourcemodel = data;
  save(filename{1}, 'sourcemodel');
elseif ~isempty(strfind(type, 'processed'))
  % save as a mat-file
  str = ['save(''',filename{1},''','''];
  str = [str inputname(3), ''','''];
  eval([inputname(3),'=varargin{1};']);
  str = [str(1:end-2),');'];
  eval(str);
  [p,n,e] = fileparts(filename{1});
  if ~isempty(e)
    cmd = ['chmod g+w ' filename{1}];
  else
    cmd = ['chmod g+w ' filename{1}, '.mat'];
  end
  system(cmd);
end
