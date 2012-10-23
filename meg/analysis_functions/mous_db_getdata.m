function [data] = mous_db_getdata(subject, type, rootdir)

% MOUS_DB_GETDATA extracts data of a particular type from the
% from a specified subject
%
% $Id: mous_db_getdata.m 48 2012-05-30 14:21:15Z jansch $

if nargin<3
  rootdir = '';
end

[filename, st] = mous_db_getfilename(subject, type, 0, rootdir);
if ~st(1)
  error('the file %s does not exist', filename{1});
else
  fprintf('getting data from file %s\n', filename{1});
end

[p,n,ext] = fileparts(filename{1});
switch lower(ext)
  case {'.ima' '.mgz' '.nii' '.img'}
    data = ft_read_mri(filename{1});
  case {'.pos'}
    data = ft_read_headshape(filename{1});
  case {'.fif'}
    if ~isempty(strfind(type, 'sourcemodelfif'))
      data = ft_read_headshape(filename{1}, 'format', 'mne_source');
    end
  case {'.mat'}
    s = whos('-file', filename{1});
    tmp  = load(filename{1});
    for k = 1:numel(s)
      data{k} = tmp.(s(k).name);
      if isstruct(data{k})
        data{k}.varname = s(k).name;
      end
    end
    if numel(data)==1
      data = data{1};
    end
  case {'.png'}
    system(['eog ' filename{1} ' &']); %open figure in the background
  otherwise
end 
