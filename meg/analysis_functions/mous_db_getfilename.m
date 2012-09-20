function [filename, st, info] = mous_db_getfilename(subject, type, infoflag)

% [filename, status, info] = mous_db_getfilename(subject, type)
%
% Input arguments:
%   subject = string that identifies subject, e.g. 'V1001', can be 'all'
%   type    = string that identifies the type of data, e.g. 'meg_ds'
%
% The following types are implemented:
%
%   'subjectname' (to be used in combination with subject = 'all'
%   'meg_ds'
%   'meg_ds_task'
%   'meg_ds_rest'
%   'meg_pos'
%   'meg_fidpic'
%   'meg_artifactcfg'
%   'meg_artifactdssblinks' 
%   'meg_artifactdsssaccades'
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
%   'meg_processed_{xxx}'
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

if ischar(subject) && strcmp(subject, 'all')
  % request all subjects -> convert into cell-array and call function
  % recursively
  d       = dir('/home/language/annhul/MOUS/Processed/V*');
  subject = {d.name};
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag);
  return;
end

if iscell(subject)
  % call recursively
  
  filename = cell(0,1);
  st       = false(0,1);
  info     = struct([]);
  for k = 1:numel(subject)
    [tmpf, tmps, tmpi] = mous_db_getfilename(subject{k}, type, infoflag);
    filename = cat(1,filename,tmpf);
    st       = cat(1,st,      tmps);
    info     = cat(1,info,    tmpi);
  end
  return;
end
  
% determine the base directory, i.e. either Annika's or Julia's home-dir
type = tokenize(type, '_');
switch type{1}
  case 'subjectname'
    filename = subject;
    st       = nan;
    info     = struct([]);
    return;
  case 'meg'
    basedir = '/home/language/annhul/MOUS/';
  case 'mri'
    basedir = '/home/language/juludd/MOUS/';
  otherwise
    error('unrecognized type requested');
end

filename = {};
st       = false;

switch type{2}
  case 'ds'
    % MEG .ds directory
    D = [basedir 'RAW' filesep subject filesep];
    d = dir([D, '*.ds']);
    if numel(type)>2
      % some additional specification has been made
      for k = 1:numel(d)
        D2 = [basedir 'RAW' filesep subject filesep d(k).name];
        d2 = dir(D2);
        
        totalbytes(k) = sum([d2.bytes]);
      end
      % make the distinction of task versus rest based on the number of
      % bytes in the directory -> FIXME not foolproof if acquisition
      % crashed
      switch type{3}
        case 'task'
          [m,ix] = max(totalbytes);
          d = d(ix);
        case 'rest'
        otherwise
      end
    end
  case 'pos'
    % Polhemus .pos file
    D = [basedir 'RAW' filesep subject filesep];
    d = dir([D, '*.pos']);
  case 'fidpic'
    % Photograph of fiducials
    D = [basedir 'RAW' filesep subject filesep];
    d = dir([D, '*.JPG']);
  case {'artifactcfg' 'artifactdssblinks' 'artifactdsssaccades'}
    D = [basedir 'Processed' filesep subject filesep 'other' filesep];
    d = dir([D subject type{2} '.mat']);
    if isempty(d)
      d(1).name = [subject type{2} '.mat'];
    end
  case 'dicom'
    % T1 dicom
    D = [basedir 'rawdata' filesep subject filesep 'Structural' filesep];
    d = dir([D '*.IMA']);
  case 'nifti'
    D = [basedir 'preprocdata' filesep subject filesep 'Structural' filesep];
    d = dir([D 'str-' subject '-001.nii']);
  case 'coregMNI'
    D = [basedir 'preprocdata' filesep subject filesep 'Structural' filesep];
    d = dir([D 'cstr-' subject '-001.nii']);
    if isempty(d)
      %d(1).name = [subject 'coregMNI'];
      d(1).name = ['cstr-' subject '-001.nii'];
    end
  case 'anatomy'
    D = [basedir 'Processed' filesep subject filesep 'meg_anatomy' filesep];
    switch type{3}
      case 'coregCTF'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregCTF.*']);
        if isempty(d)
          d(1).name = [subject 'coregCTF'];
        end
      case 'coregCTFresliced'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregCTFresliced.*']);
        if isempty(d)
          d(1).name = [subject 'coregCTFresliced'];
        end
      case 'coregMNI'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregMNI.*']);
        %d = dir([D 'cstr-' subject '-001.nii']);
        if isempty(d)
          d(1).name = [subject 'coregMNI'];
          %d(1).name = ['cstr-' subject '-001.nii'];
        end
      case 'coregMNIresliced'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregMNIresliced.*']);
        if isempty(d)
          d(1).name = [subject 'coregMNIresliced'];
        end
      case 'coregMNIskullstrip'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregMNIskullstrip.*']);
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstrip'];
        end
        case 'coregMNIskullstripmask'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'coregMNIskullstripmask.*']);
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstripmask'];
        end
      case 'headmodel'
        %D = '/home/coherence/jansch/public/';
        d = dir([D subject 'vol.*']);
        if isempty(d)
          d(1).name = [subject 'vol'];
        end
      case 'sourcemodelfif'
        D = [D subject filesep 'bem' filesep];
        d = dir([D '*.fif']);
      case 'sourcemodel2D'
        d = dir([D subject 'sourcemodel2D.*']);
        if isempty(d)
          d(1).name = [subject 'sourcemodel2D'];
        end
      case 'sourcemodel3D'
        if numel(type)==3, type{4} = ''; end
        d = dir([D subject 'sourcemodel3D' type{4} '.*']);
        if isempty(d)
          d(1).name = [subject 'sourcemodel3D' type{4}];
        end
      case 'figure'
        d = dir([D subject 'figure_' type{4} '.png']);
        if isempty(d)
          d(1).name = [subject 'figure_' type{4}];
        end
      otherwise
        error('unrecognized type requested');
    end
  case 'artifact'
    D = [basedir 'Processed' filesep subject filesep 'other' filesep];
    switch type{3}
      case 'figure'
        d = dir([D subject 'figure_' type{4} '.png']);
        if isempty(d)
          d(1).name = [subject 'figure_' type{4}];
        end
      otherwise
        error('unrecognized type requested');
    end
    
  case 'processed'
    D = [basedir 'Processed' filesep subject filesep];
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
          D = [D 'TFR/'];
        elseif (~isempty(strfind(suff, 'erf'))) || (~isempty(strfind(suff, 'ERF')))
          D = [D 'ERF/'];
        else
          D = [D 'other/'];
        end
        d    = dir([D subject suff '.mat']);
        if isempty(d)
          d(1).name = [subject suff];
        end
      otherwise
        error('unrecognized type requested');    
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

if infoflag && ~isempty(filename)
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