function mous_db_putdata(subject, type, varargin)

% MOUS_DB_PUTDATA saves data from specified subject and type to 
% the database.
%
% See also MOUS_DB_GETFILENAME, MOUS_WRITE_PROVENANCE

if numel(varargin)>1
  % it could be that the root directory is specified as last input argument
  if ischar(varargin{end}) && isdir(varargin{end})
    rootdir  = varargin{end};
    varargin = varargin(1:end-1);
  else
    rootdir = '';
  end
else
  rootdir = '';
end

% create the string that specifies the file name and check whether it
% already exists: FIXME now the default behavior is overwrite, this may
% need to be changed however
[filename, st] = mous_db_getfilename(subject, type, 0, rootdir);
filename       = filename{1};
if st(1)
  warning('file %s exists, overwriting existing file', filename);
end

% create empty data structure when more than one variable is to be saved,
% so that the file will be saved as mat-file.
if numel(varargin)>1
  data = [];
else
  data = varargin{1};
end

fprintf('putting data to file %s\n', filename);
if ft_datatype(data, 'volume')
  % save volumetric data as nifti
  cfg           = [];
  cfg.filetype  = 'nifti';
  cfg.parameter = 'anatomy';
  cfg.filename  = filename;
  ft_volumewrite(cfg, data);
  mous_write_provenance(filename);
  
elseif ishandle(data)
 if exist(filename,'file'), system(['rm -rf ',filename]); end
 print(data, '-dpng', filename, '-r500');
else
  % save as a mat-file
  
  % this function uses some local variables with a cryptical name to prevent
  % variable name collisions with the local copy of the input variables.
  filename_c9e61b166b = filename; clear filename
  
  [p, f, x] = fileparts(filename_c9e61b166b);
  if ~strcmp(x, '.mat')
    warning('appending the extension .mat');
    filename_c9e61b166b = fullfile(p, [f '.mat']);
  end
  clear p f x
  
  % get the anonymous input variables into the local workspace
  for index_c9e61b166b=1:length(varargin)
    setvariable(varargin{index_c9e61b166b}, evalin('caller', varargin{index_c9e61b166b}));
  end
  clear index_c9e61b166b
  
  save(filename_c9e61b166b, varargin{:});
  
  % write the corresponding provenance information
  mous_write_provenance(filename_c9e61b166b);

  [p,n,e] = fileparts(filename_c9e61b166b);
  if ~isempty(e)
    cmd = ['chmod g+w ' filename_c9e61b166b];
  else
    cmd = ['chmod g+w ' filename_c9e61b166b, '.mat'];
  end
  system(cmd);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to prevent an eval(sprintf(...))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setvariable(name, val)
assignin('caller', name, val)
