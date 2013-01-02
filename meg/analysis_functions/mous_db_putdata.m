
 function mous_db_putdata(subject, type, varargin)

% MOUS_DB_PUTDATA saves data from specified subject and type to 
% the database.
%
% Use as 
%   mous_db_putdata(subject, type, 'var1', 'var2', ...);
%   mous_db_putdata(subject, type, 'var1', 'var2', ..., overwriteflag);
%   mous_db_putdata(subject, type, 'var1', 'var2', rootdir);
%   mous_db_putdata(subject, type, 'var1', ..., rootdir, overwriteflag);
%
% where
%   subject = string, denoting the subject
%   type    = string, denoting the type of the file
%   rootdir = string, denoting the root directory of the results (defaults
%                     to Annika's home dir).
%   overwriteflag = boolean, 0 or 1 (default 1): overwrite the file if it
%                   already exists, otherwise move the already existing
%                   file to another file, appending the date and time at
%                   which the backup was made to the original filename
%
% See also MOUS_DB_GETFILENAME, MOUS_WRITE_PROVENANCE, SAVE

overwriteflag = true;
if numel(varargin)>1
  if (isnumeric(varargin{end}) || islogical(varargin{end})) && istrue(varargin{end})
    overwriteflag = true;
    varargin      = varargin(1:end-1);
  elseif (isnumeric(varargin{end}) || islogical(varargin{end})) && ~istrue(varargin{end})
    overwriteflag = false;
    varargin      = varargin(1:end-1);
  else
    % all other cases: default behavior
    overwriteflag = true;
  end
end

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
if st(1) && overwriteflag
  warning('file %s exists, overwriting existing file', filename);
elseif st(1) && ~overwriteflag
  %c       = clock;
  [p,f,e] = fileparts(filename);
  %newfilename = fullfile(p,sprintf('%s%04.0f%02.0f%02.0f%02.0f%02.0f%s',f,c(1),c(2),c(3),c(4),c(5),e));
  %newfilename = fullfile(p,f,'v',newVersion);
  d = dir(filename);
  fullstr = strtok(d.date);
  oldVersionDate = [fullstr(1:2) fullstr(4:6) fullstr(end-3:end)]; % rename older file with the day it was created ( usually = last date modified)
  newfilename = [p filesep f oldVersionDate e];
  %newtype     = sprintf('%s%04.0f%02.0f%02.0f%02.0f%02.0f%s',type,c(1),c(2),c(3),c(4),c(5));
  warning('file %s exists, creating back-up of %s as %s', filename, filename, newfilename);
  system(['mv ',filename,' ',newfilename]);
  mous_write_provenance(newfilename);
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
