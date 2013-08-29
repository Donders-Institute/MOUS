function [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir)

% [filename, status, info] = mous_db_getfilename(subject, type)
%
% Input arguments:
%   subject = string that identifies subject, e.g. 'V1001', can be 'all'
%   type    = string that identifies the type of data, e.g. 'meg_ds'
%
% The following types are implemented:
%
%   'subjectname' (to be used in combination with subject = 'all'
%   'meg_raw'
%   'meg_raw_task'
%   'meg_raw_rest'
%   'meg_raw_pos'
%   'meg_raw_fidpic'
%   'meg_raw_log'             % presentation log file 
%   'meg_artifact_cfg'
%   'meg_artifactdssblinks'   %% FIXME meg_artifact_dssblinks
%   'meg_artifactdsssaccades' %% FIXME  meg_artifact_dsssaccades
%   'mri_dicom'
%   'mri_nifti'
%   'mri_coregMNI'
%   'meg_anatomy_coregCTF'
%   'meg_anatomy_coregCTFresliced'
%   'meg_anatomy_coregMNI'
%   'meg_anatomy_coregMNIresliced'
%   'meg_anatomy_coregMNIskullstrip'
%   'meg_anatomy_coregMNIskullstripmask'
%   'meg_anatomy_headmodel'
%   'meg_anatomy_sourcemodelfif'
%   'meg_anatomy_sourcemodel2D'
%   'meg_anatomy_sourcemodel3D_xxx'
%   'meg_anatomy_figure_xxx'
%   'meg_bfica_{xxx}'
%   'meg_processed_{xxx}' (fixed forms are erf, tfr and mne)
%   'meg_qualitycheck_{qc_general_rest}  / {qc_general_task}
%   'meg_qualitycheck_{qc_art}' % combined pdf of all artifacts
%   'meg_qualitycheck_{qc_artXXXX_task}' fixed forms: blink, sacc, jump, musc  % individual eps. files

%
% Output arguments:
%   filename = cell-array of strings returing the filename(s)
%   status   = vector of booleans indicating whether the file(s) exist
%   info     = struct-array giving additional info about the files

% $Id: mous_db_getfilename.m 48 2012-05-30 14:21:15Z jansch $

if nargin>2
  if ischar(infoflag) && strcmp(infoflag, 'info')
    infoflag = true;
  elseif infoflag~=1
    infoflag = false;
  end
else
  infoflag = false;
end

if nargin<4
  rootdir = [];
end

% throw a warning for the bad subjects. NOTE: consider making it an
% explicit error
badsubjects = {'V1014';'V1018';'V1041';'V1043';'V1047';'V1051';'V1056';'V1060';'V1082';'V1091';'V1096'};
if ischar(subject) && (strcmp(subject, 'allV') || strcmp(subject, 'all'))
  % 'all' is not consistent but kept for backward compatibility

  % request all visual subjects -> convert into cell-array and call function
  % recursively
  d = dir('/home/language/annhul/MOUS/meg/V*');
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir); 
  return;
elseif ischar(subject) && strcmp(subject, 'allA')
  % request all visual subjects -> convert into cell-array and call function
  % recursively
  d = dir('/home/language/annhul/MOUS/meg/A*');
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir); 
elseif ischar(subject) && strcmp(subject, 'allAV')
  % request all subjects -> convert into cell-array and call function
  % recursively
  d = dir('/home/language/annhul/MOUS/meg/V*');
  d = cat(1, d, dir('/home/language/annhul/MOUS/meg/A*'));
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir); 
elseif ischar(subject) && strcmp(subject, 'bad')
  % request all subjects classified as bad, hard coded
  filename = badsubjects;
  st   = [];
  info = [];
  return;
end

if iscell(subject)
  % call recursively
  
  filename = cell(0,1);
  st       = false(0,1);
  info     = struct([]);
  for k = 1:numel(subject)
      [tmpf, tmps, tmpi] = mous_db_getfilename(subject{k}, type, infoflag, rootdir);
      filename = cat(1,filename,tmpf);
      st       = cat(1,st,      tmps);
      info     = cat(1,info,    tmpi);
  end
  return;
end

% throw a warning for the bad subjects. NOTE: consider making it an
% explicit error
% V1041 has only 3 min worth of resting state, I'd say this is not a
% criterion for rejection
if ismember(subject, badsubjects)
  warning('subject %s is considered a BAD subjects', subject);
end

% determine the root directory, i.e. either Annika's or Julia's home-dir
type = tokenize(type, '_');
if isempty(rootdir)
  switch type{1}
    case 'subjectname'
      filename = subject;
      st       = nan;
      info     = struct([]);
      return;
    case 'meg'
      rootdir = '/home/language/annhul/MOUS/meg';
    case 'mri'
      rootdir = '/home/language/juludd/MOUS';
    otherwise
      error('unrecognized type requested');
  end
end

filename = {};
st       = false;

switch type{2}
  case {'raw' 'ds'}
    % MEG .ds directory
    D = [rootdir filesep subject filesep 'RAW' filesep];
    d = dir([D, '*.ds']);
    if numel(type)>2
      % some additional specification has been made
      for k = 1:numel(d)
        D2 = [rootdir filesep subject filesep 'RAW' filesep d(k).name];
        d2 = dir(D2);
        
        totalbytes(k) = sum([d2.bytes]);
      end
      % make the distinction of task versus rest based on the number of
      % bytes in the directory -> FIXME not foolproof if acquisition
      % crashed
      switch type{3}
        case 'task'
          % heuristic: totalbytes > 1e9
          [m,ix] = find(totalbytes>1e9);
          d = d(ix);
        case 'rest'
          % heuristic: totalbytes > .1e9 and <.7e9, does not work for V1012
          [m,ix] = find(totalbytes>0.1e9 & totalbytes<0.7e9);
          d = d(ix);
        case 'pos'
          % Polhemus .pos file
          D = [rootdir filesep subject filesep 'RAW' filesep];
          d = dir([D, '*.pos']);
        case 'fidpic'
          % Photograph of fiducials
          D = [rootdir filesep subject filesep 'RAW' filesep];
          d = dir([D, '*.JPG']);
        case 'log'
          D = [rootdir filesep subject filesep 'RAW' filesep];
          d = dir([D, '*.log']);    
        otherwise
      end
    end
  case {'artifactdssblinks' 'artifactdsssaccades'}
    D = [rootdir filesep subject filesep 'artifact' filesep];
    d = dir([D subject type{2} '.mat']);
    if isempty(d)
      d(1).name = [subject type{2} '.mat'];
    end
  case 'dicom'
    % T1 dicom
    D = [rootdir filesep 'rawdata' filesep subject filesep 'Structural' filesep];
    d = dir([D '*.IMA']);
  case 'nifti'
    D = [rootdir filesep 'preprocdata' filesep subject filesep 'Structural' filesep];
    d = dir([D 'str-' subject '-001.nii']);
  case 'coregMNI'
    D = [rootdir filesep 'preprocdata' filesep subject filesep 'Structural' filesep];
    d = dir([D 'cstr-' subject '-001.nii']);
    if isempty(d)
      %d(1).name = [subject 'coregMNI'];
      d(1).name = ['cstr-' subject '-001.nii'];
    end
  case 'anatomy'
    D = [rootdir filesep subject filesep 'anatomy' filesep];
    switch type{3}
      case 'coregCTF'
        d = dir([D subject 'coregCTF.nii']);
        if isempty(d)
          d(1).name = [subject 'coregCTF'];
        end
      case 'coregCTFresliced'
        d = dir([D subject 'coregCTFresliced.*']);
        if isempty(d)
          d(1).name = [subject 'coregCTFresliced'];
        end
      case 'coreginfo'
        d = dir([D subject 'coreginfo.mat']);
        if isempty(d)
          d(1).name = [subject 'coreginfo'];
        end
      case 'coregMNI'
        d = dir([D subject 'coregMNI.nii']);
        %d = dir([D 'cstr-' subject '-001.nii']);
        if isempty(d)
          d(1).name = [subject 'coregMNI'];
          %d(1).name = ['cstr-' subject '-001.nii'];
        end
      case 'coregMNIresliced'
        d = dir([D subject 'coregMNIresliced.*']);
        if isempty(d)
          d(1).name = [subject 'coregMNIresliced'];
        end
      case 'coregMNIskullstrip'
        d = dir([D subject 'coregMNIskullstrip.nii']);
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstrip'];
        end
        case 'coregMNIskullstripmask'
        d = dir([D subject 'coregMNIskullstripmask.nii']);
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstripmask'];
        end
      case 'headmodel'
        d = dir([D subject 'vol.mat']);
        if isempty(d)
          d(1).name = [subject 'vol'];
        end
      case 'sourcemodelfif'
        D = [D subject filesep 'bem' filesep];
        d = dir([D '*.fif']);
      case 'sourcemodel2D'
        if numel(type)==3, type{4} = ''; end
        d = dir([D subject 'sourcemodel2D' type{4} '.mat']);
        if isempty(d)
          d(1).name = [subject 'sourcemodel2D' type{4} '.mat'];
        end
      case 'sourcemodel3D'
        if numel(type)==3, type{4} = ''; end
        d = dir([D subject 'sourcemodel3D' type{4} '.mat']);
        if isempty(d)
          d(1).name = [subject 'sourcemodel3D' type{4},'.mat'];
        end
      case 'figure'
        d = dir([D subject 'figure_' type{4} '.png']);
        if isempty(d)
          d(1).name = [subject 'figure_' type{4}];
        end
      otherwise
        error('unrecognized type requested');
    end
  %case 'artifact'
  %  D = [rootdir filesep subject filesep 'other' filesep];
  %  switch type{3}
  %    case 'figure'
  %      d = dir([D subject 'figure_' type{4} '.png']);
  %      if isempty(d)
  %        d(1).name = [subject 'figure_' type{4}];
  %      end
  %    otherwise
  %      error('unrecognized type requested');
  %  end
    
  case 'processed'
    D = [rootdir filesep subject filesep];
    switch [type{3}(1) type{end}(end)]
      case '{}'
        %use everything between the {} as a suffix for the filename and
        %allow for underscores
        suff = '';
        for k = 3:numel(type)
          suff = [suff type{k} , '_'];
        end
        suff = suff(2:end-2);
        if (~isempty(strfind(suff, 'tfr'))) || (~isempty(strfind(suff, 'TFR')))
          D = [D 'tfr' filesep];
        elseif (~isempty(strfind(suff, 'erf'))) || (~isempty(strfind(suff, 'ERF')))
          D = [D 'erf' filesep];
        elseif (~isempty(strfind(suff, 'mne'))) || (~isempty(strfind(suff, 'MNE')))
          D = [D 'mne' filesep];
        else
          D = [D 'other' filesep];
        end
        d    = dir([D filesep subject suff '.mat']);
        if isempty(d)
          d(1).name = [subject suff];
        end
      otherwise
        error('unrecognized type requested');    
    end
  case {'bfica' 'artifact' 'corrmnebf' 'restingstate' 'qualitycheck' 'mne' 'preproc' 'other' 'erf'} %FIXME add the other ones also, so that the 'processed' can be removed
    D = [rootdir filesep subject filesep type{2} filesep];
    switch [type{3}(1) type{end}(end)]
      case '{}'
        %use everything between the {} as a suffix for the filename and
        %allow for underscores
        suff = '';
        for k = 3:numel(type)
          suff = [suff type{k} , '_'];
        end
        suff = suff(2:end-2);
        d = dir([D filesep subject suff '.mat']);
        if isempty(d)
          d(1).name = [subject suff];
        end
      otherwise
        % error('unrecognized type requested');    
        suff = '_';
        for k = 2:numel(type)
          suff = [suff type{k} , '_'];
        end
        suff = suff(1:end-1);
        d    = dir([D filesep subject suff '.mat']);
        if isempty(d)
          d(1).name = [subject suff];
        end
    end
  otherwise
    error('unrecognized type requested');
end

for k = 1:numel(d)
  filename{k} = fullfile(D,d(k).name);
end

if ~isempty(filename)
  for k = 1:numel(filename)
    st(k) = exist(filename{k}, 'file');
  end
end

if infoflag & ~isempty(filename)
  for k = 1:numel(filename)
    if st(k)
      info(k) = dir(filename{k});
    else
      info(k) = struct('name',[],'date',[],'bytes',[],'isdir',[],'datenum',[]);
    end
  end
else
  info = [];
end

