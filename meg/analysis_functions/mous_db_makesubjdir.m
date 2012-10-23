function mous_db_makesubjdir(subjectname, rootdir)

% MOUS_DB_MAKESUBJDIR creates a directory (with subdirectories) for a particular 
% named subject. 
%
% Use as 
%   mous_db_makesubjdir(subjectname, rootdir)
%
% Input arguments:
%   subjectname = string, name of the subject
%   rootdir     = string (optional) directory in which the directory will
%                 be created. Default = '/home/language/annhul/MOUS/meg/'.

if nargin<2
  rootdir = '/home/language/annhul/MOUS/meg/';
end

% create main level directory
existdir = ~isempty(dir([rootdir,subjectname]));
subjdir  = [rootdir,subjectname];
if ~existdir
  fprintf(['creating subjectname specific directory: ', subjdir,'\n']);
  mkdir(subjdir);
  cmd = ['chmod g+w ' subjdir];
  system(cmd);
end

subdir = {'anatomy';'erf';'tfr';'mne';'bfica';'RAW';'artifact';'test';'other'};

% create sub directories
for k = 1:numel(subdir)
  existdir = ~isempty(dir([rootdir,subjectname,filesep,subdir{k}]));
  if ~existdir
    fprintf(['creating subjectname specific subdirectory: ',subjdir,filesep,subdir{k},'\n']);
    mkdir([subjdir,filesep,subdir{k}]);
    cmd = ['chmod g+w ' subjdir,filesep,subdir{k}];
    system(cmd);
  end
end
