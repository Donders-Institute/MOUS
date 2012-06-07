function [filename, st] = mous_db_getfilename(subject, type)

% [filename] = mous_db_getfilename(subject, type)
%
% subject = string that identifies subject, e.g. 'V1001'
% type    = string that identifies the type of data, e.g. 'meg_ds'
%
% filename = cell-array of strings returing the filename(s)
%
% $Id: mous_db_getfilename.m 48 2012-05-30 14:21:15Z jansch $

if iscell(subject)
  % call recursively
  
  filename = cell(0,1);
  st       = false(0,1);
  for k = 1:numel(subject)
    [tmpf, tmps] = mous_getfilename(subject{k}, type);
    filename = cat(1,filename,tmpf);
    st       = cat(1,st,      tmps);
  end
  return;
end
  
% determine the base directory, i.e. either Annika's or Julia's home-dir
type = tokenize(type, '_');
switch type{1}
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
  case 'artifactcfg'
    D = [basedir 'Processed' filesep subject filesep 'other' filesep];
    d = dir([D subject 'artifactcfg.mat']);
    if isempty(d)
      d(1).name = [subject 'artifactcfg.mat'];
    end
  case 'dicom'
    % T1 dicom
    D = [basedir 'rawdata' filesep subject filesep 'Structural' filesep];
    d = dir([D '*.IMA']);
  case 'nifti'
    D = [basedir 'SPM5preprocdata' filesep subject filesep 'Structural' filesep];
    d = dir([D 'str-' subject '-001.nii']);
  case 'coregMNI'
    D = [basedir 'SPM5preprocdata' filesep subject filesep 'Structural' filesep];
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
        d = dir([D subject 'figure*.png']);
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
        if ~isempty(strfind(suff, 'tfr'))
          D = [D 'TFR/'];
        elseif ~isempty(strfind(suff, 'ERF'))
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
