function mous_db_makesubjdir(subjectname, rootdir, subdir)

% MOUS_DB_MAKESUBJDIR creates a directory (with subdirectories) for a particular 
% named subject. 
%
% Use as 
%   mous_db_makesubjdir(subjectname, rootdir)
%
% Input arguments:
%   subjectname = string, name of the subject
%   rootdir     = string (optional) directory in which the directory will
%                 be created. Default = '/project/3011020.09/MEG'.

if nargin<2
  %rootdir = '/project/3011020.09/MEG';
  rootdir = '/project/3011020.09/processed';
end

if nargin<3
  subdir = {};
end

if isempty(subdir)
  subdir = {'multisetcca';'anatomy';'erf';'tfr';'corrmnebf';'mne';'bfica';'RAW';'artifact';'test';'other';'qualitycheck';'headposition';'restingstate';'megmri';};
end

if ischar(subdir)
  subdir = {subdir};
end

% create main level directory
existdir = ~isempty(dir([rootdir,filesep,subjectname]));
subjdir  = [rootdir,filesep,subjectname];
if ~existdir
  fprintf(['creating subjectname specific directory: ', subjdir,'\n']);
  mkdir(subjdir);
  cmd = ['chmod g+w ' subjdir];
  system(cmd);
end


% create sub directories
for k = 1:numel(subdir)
  existdir = ~isempty(dir([rootdir,filesep,subjectname,filesep,subdir{k}]));
  if ~existdir
    fprintf(['creating subjectname specific subdirectory: ',subjdir,filesep,subdir{k},'\n']);
    mkdir([subjdir,filesep,subdir{k}]);
    cmd = ['chmod g+w ' subjdir,filesep,subdir{k}];
    system(cmd);
  end
end
