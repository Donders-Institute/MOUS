function [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir)

% [filename, status, info] = mous_db_getfilename(subject, type)
%
% Input arguments:
%   subject = string that identifies subject, e.g. 'V001', can be
%   'all','subjectname' (lists all the subjectnames)
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

% This section is for backward compatibility purposes: reorganization of 
% the data, has led to new subject names, as well as a different directory
% layout. This is needed to accommodate the data for RDM.
success = false;
try
  [filename, st, info] = mous_db_getfilename_new(subject, type, infoflag, rootdir);
  success = true;
  if numel(filename)==1 && st==0
    % the file does not seem to exist, so try with the fallback function
    success = false;
  end
catch
  filename = [];
end
if isempty(filename)
  success = false;
end

% too bad, but discontinue the fallback, because things get too messy with
% the data reorganization etc.
% if success 
%   return;
% else
%   [filename, st, info] = mous_db_getfilename_old(subject, type, infoflag, rootdir);
% end

% ----------------------------------------------------
% create as a subfunction, to avoid infinite recursion
function [filename, st, info] = mous_db_getfilename_new(subject, type, infoflag, rootdir)

% throw a warning for the bad subjects. NOTE: consider making it an
% explicit error
% these reflect subjects in which there was problem with the MEG data, but
% does not consider issues in the MRI (whereby MEG data was still fine)

% JM has updated this list 20140908 based on the SitePage on BigU, named
% Subject Replacements
badsubjects = {'V1014';'V1018';'V1021';'V1023';'V1041';'V1043';'V1047';'V1051';'V1056';'V1060';'V1067';'V1082';'V1091';'V1096';'V1112';...
               'A2001';'A2012';'A2018';'A2022';'A2023';'A2026';'A2043';'A2044';'A2045';'A2048';'A2054';'A2060';'A2074';'A2081';'A2082';'A2087';'A2093';...
               'A2100';'A2107';'A2112';'A2115';'A2118';'A2123';'AP02'};
           
           
% subjects with more than one dataset because MEG acquisition PC crashed           
% 'V1006';'V1090';'A2011';'A2036';'A2062';'A2063';'A2076';'A2084'
% in the above list are 2 subjects who's file are too small to be
% considered as a task dataset by the heuristic. Therefore they are hard coded 
% A2052 is an exception, no crash happened, but the first recording was
% very bad so we started again.
cannotdetectdatasetsubjects = {'A2052';'A2062';'A2063';'A2115'};
          
if ischar(subject) && (strcmp(subject, 'allV') || strcmp(subject, 'all'))
  % 'all' is not consistent but kept for backward compatibility

  % request all visual subjects -> convert into cell-array and call function
  % recursively
  if isempty(rootdir)
    rootdir = '/project/3011020.09/processed';
  end
  d       = dir(fullfile(rootdir,'V*'));
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  subject = setdiff(subject, badsubjects);
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir); 
  return;
elseif ischar(subject) && strcmp(subject, 'allA')
  % request all auditory subjects -> convert into cell-array and call function
  % recursively
  if isempty(rootdir)
    rootdir = '/project/3011020.09/processed';
  end
  d = dir(fullfile(rootdir,'A*'));
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  subject = setdiff(subject, badsubjects);
  [filename, st, info] = mous_db_getfilename(subject, type, infoflag, rootdir); 
elseif ischar(subject) && strcmp(subject, 'allAV')
  % request all subjects -> convert into cell-array and call function
  % recursively
  if isempty(rootdir)
    rootdir = '/project/3011020.09/processed';
  end
  d = dir(fullfile(rootdir,'V*'));
  d = cat(1, d, dir(fullfile(rootdir,'A*')));
  subject = {d.name};  % because d has multiple elements, so do subject; elements are strings
  subject = setdiff(subject, badsubjects);
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
      if iscell(tmpf)
        filename = cat(1,filename,tmpf(:));
      else
        filename = cat(1,filename,tmpf);
      end
      st       = cat(1,st,      tmps(:));
      info     = cat(1,info,    tmpi(:));
  end
  return;
end

% create the new naming convention
%subject = strrep(subject,'A','sub-');
%subject = strrep(subject,'V','sub-');

% throw a warning for the bad subjects. NOTE: consider making it an
% explicit error
% V1041 has only 3 min worth of resting state, I'd say this is not a
% criterion for rejection
if ismember(subject, badsubjects)
  warning('subject %s is considered a BAD subjects', subject);
end

% determine the root directory of the database 
% note that the type string always starts with 'meg_', 'mri_', or is 'subjectname
type = tokenize(type, '_');
switch type{1}
  case 'subjectname'
    filename = subject;
    st       = nan;
    info     = struct([]);
    return;
  case 'scenario'
%     [filename, st, info] = mous_db_getfilename(subject, 'meg_raw_log');
%     for k = 1:numel(filename)
%       [~,filename{k},~] = fileparts(filename{k});
%       filename{k} = strrep(filename{k},'-MEG-MOUS-', '');
%       filename{k} = filename{k}(end-3:end);
%     end
%     if numel(filename)==1
%     elseif numel(filename)>1 && ~all(strcmp(filename,filename{1}))
%       filename = {'NA'};
%       st = true; % otherwise the function recurses into an error
%     else
%     
%     end
      list = {'A2002' '2'
        'A2003' '3'
        'A2004' '4'
        'A2005' '5'
        'A2006' '1'
        'A2007' '1'
        'A2008' '2'
        'A2009' '1'
        'A2010' '4'
        'A2011' '5'
        'A2013' '1'
        'A2014' '2'
        'A2015' '3'
        'A2016' '4'
        'A2017' '5'
        'A2019' '1'
        'A2020' '2'
        'A2021' '3'
        'A2024' '6'
        'A2025' '1'
        'A2027' '3'
        'A2028' '4'
        'A2029' '5'
        'A2030' '6'
        'A2031' '3'
        'A2032' '2'
        'A2033' '3'
        'A2034' '4'
        'A2035' '5'
        'A2036' 'nan'
        'A2037' '1'
        'A2038' '2'
        'A2039' '3'
        'A2040' '4'
        'A2041' '5'
        'A2042' '6'
        'A2046' '4'
        'A2047' '5'
        'A2049' '1'
        'A2050' '2'
        'A2051' '5'
        'A2052' '4'
        'A2053' '5'
        'A2055' '1'
        'A2056' '2'
        'A2057' '3'
        'A2058' '4'
        'A2059' '5'
        'A2061' '1'
        'A2062' '2'
        'A2063' '3'
        'A2064' '4'
        'A2065' '1'
        'A2066' '6'
        'A2067' '1'
        'A2068' '2'
        'A2069' '3'
        'A2070' '4'
        'A2071' '3'
        'A2072' '6'
        'A2073' '5'
        'A2075' '3'
        'A2076' '4'
        'A2077' '5'
        'A2078' '6'
        'A2079' '1'
        'A2080' '2'
        'A2083' '5'
        'A2084' '6'
        'A2085' '1'
        'A2086' '2'
        'A2088' '4'
        'A2089' '5'
        'A2090' '6'
        'A2091' '1'
        'A2092' '2'
        'A2094' '4'
        'A2095' '5'
        'A2096' '6'
        'A2097' '1'
        'A2098' '2'
        'A2099' '3'
        'A2101' '6'
        'A2102' '2'
        'A2103' '4'
        'A2104' '6'
        'A2105' '3'
        'A2106' '2'
        'A2108' '6'
        'A2109' '3'
        'A2110' '4'
        'A2111' '3'
        'A2113' '4'
        'A2114' '4'
        'A2116' '6'
        'A2117' '6'
        'A2119' '2'
        'A2120' '6'
        'A2121' '5'
        'A2122' '6'
        'A2124' '3'
        'A2125' '5'
        'V1001' '1'
        'V1002' '2'
        'V1003' '3'
        'V1004' '3'
        'V1005' '5'
        'V1006' '6'
        'V1007' '2'
        'V1008' '2'
        'V1009' '4'
        'V1010' '4'
        'V1011' '5'
        'V1012' '6'
        'V1013' '1'
        'V1015' '3'
        'V1016' '4'
        'V1017' '5'
        'V1019' '1'
        'V1020' '2'
        'V1022' '4'
        'V1024' '6'
        'V1025' '1'
        'V1026' '3'
        'V1027' '3'
        'V1028' '4'
        'V1029' '5'
        'V1030' '6'
        'V1031' '1'
        'V1032' '2'
        'V1033' '3'
        'V1034' '6'
        'V1035' '5'
        'V1036' '6'
        'V1037' '3'
        'V1038' '2'
        'V1039' '3'
        'V1040' '4'
        'V1042' '6'
        'V1044' '2'
        'V1045' '3'
        'V1046' '4'
        'V1048' '6'
        'V1049' '1'
        'V1050' '2'
        'V1052' '4'
        'V1053' '5'
        'V1054' '6'
        'V1055' '1'
        'V1057' '3'
        'V1058' '4'
        'V1059' '5'
        'V1061' '1'
        'V1062' '2'
        'V1063' '3'
        'V1064' '4'
        'V1065' '5'
        'V1066' '6'
        'V1068' '2'
        'V1069' '3'
        'V1070' '4'
        'V1071' '5'
        'V1072' '6'
        'V1073' '1'
        'V1074' '2'
        'V1075' '3'
        'V1076' '4'
        'V1077' '5'
        'V1078' '6'
        'V1079' '1'
        'V1080' '2'
        'V1081' '3'
        'V1083' '5'
        'V1084' '6'
        'V1085' '1'
        'V1086' '2'
        'V1087' '3'
        'V1088' '4'
        'V1089' '5'
        'V1090' '6'
        'V1092' '2'
        'V1093' '3'
        'V1094' '4'
        'V1095' '5'
        'V1097' '1'
        'V1098' '2'
        'V1099' '4'
        'V1100' '1'
        'V1101' '5'
        'V1102' '6'
        'V1103' '1'
        'V1104' '2'
        'V1105' '1'
        'V1106' '4'
        'V1107' '5'
        'V1108' '5'
        'V1109' '1'
        'V1110' '2'
        'V1111' '6'
        'V1113' '6'
        'V1114' '5'
        'V1115' '5'
        'V1116' '1'
        'V1117' '3'};
    filename = list(strcmp(list(:,1),subject),2);
    st = true;
    info = [];
    return;  
  case {'meg' 'mridti'}
    if isempty(rootdir)
      rootdir = '/project/3011020.09';
    end
  case 'mri'
    if isempty(rootdir)
      rootdir = '/project/3011020.09/MRI';
    end
  otherwise
    error('unrecognized type requested');
end

filename = {};
st       = false;

switch type{2}
  case {'raw' 'ds'}
    % MEG .ds directory
    D = fullfile(rootdir,'raw',subject,'meg');
    %d = dir([D, '/*/*/*.ds']);
    d = dir([D,'/*.ds']);
    % FIXME:  crashes if there are no files in RAW directory, need to
    % circumvent this
    if numel(type)>2 
      % some additional specification has been made
      for k = 1:numel(d)
        D2 = fullfile(d(k).folder,d(k).name);
        d2 = dir(D2);
        totalbytes(k) = sum([d2.bytes]);
      end
      % make the distinction of task versus rest based on the number of
      % bytes in the directory 
      switch type{3}
        case 'task'
          % exception cases where MEG acquisition crashed
          if any(ismember(subject, cannotdetectdatasetsubjects))
            d = datasets_exceptions(subject,D2);
          else
            % heuristic: totalbytes > 1e9
            [m,ix] = find(totalbytes>1e9);
            d = d(ix);         
          end
        case 'rest'
          % heuristic: totalbytes > .1e9 and <.7e9, doesnt work for 4 subjs
          [m,ix] = find(totalbytes>0.1e9 & totalbytes<0.7e9);
          if strcmp(subject, 'V1012')
            ix = ix(2); % according to the notes, subject fell asleep during 1st resting
          end
          if strcmp(subject, 'A2036') % m/ix are empty
            ix = 1;
          end
          if strcmp(subject, 'A2061')
            ix = ix(2);
          end
          if strcmp(subject, 'V1025')
            ix = 1;
          end
          if ~isempty(ix)
            d = d(ix);
          else
            clear d;
            d(1).folder = '';
            d(1).name   = sprintf('restingstatedoesnotseemtoexistforsubject%s',subject);
          end
        case 'pos'
          % Polhemus .pos file
          D = fullfile(rootdir,'raw',subject,'meg');
          d = dir([D, '/*.pos']);
        case 'fidpic'
          % Photograph of fiducials
          D = fullfile(rootdir,'raw',subject,'meg');
          d = dir([D, '/*.JPG']);
        case 'log'
          if any(ismember(subject, cannotdetectdatasetsubjects))
            d = datasets_exceptions(subject,D2);
          else
            % heuristic: totalbytes > 1e9
            [m,ix] = find(totalbytes>1e9);
            d = d(ix);         
          end
          d = dir([d(1).folder, '/*.log']);    
        otherwise
      end
    end
  case {'artifactdssblinks' 'artifactdsssaccades'}
    D = [rootdir filesep subject 'meg' filesep 'artifact' filesep];
    d = fullfile(D, [subject type{2} '.mat']);
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
  case 'freesurfer'
    D = fullfile(rootdir,'processed',subject,'mri_dti','tracula'); %-> this is the Freesurfer output from BIG
    d = dir(fullfile(D, 'mri', 'T1.mgz'));
  case 'anatomy'
    D = fullfile(rootdir,'processed',subject,'meg','anatomy');
    switch type{3}
      case 'freesurfer'
        % load the freesurfer T1 image from the meg/anatomy folder
        d = dir(fullfile(D, subject, 'mri', 'T1.mgz'));
      case 'coregCTF'
        d = dir(fullfile(D, [subject 'coregCTF.nii']));
        if isempty(d)
          d(1).name = [subject 'coregCTF'];
        end
      case 'coregCTFresliced'
        d = dir(fullfile(D, [subject 'coregCTFresliced.*']));
        if isempty(d)
          d(1).name = [subject 'coregCTFresliced'];
        end
      case 'coreginfo'
        if numel(type)>3
          d = dir(fullfile(D, [subject 'coreginfo_',type{4},'.mat']));
        else
          d = dir(fullfile(D, [subject 'coreginfo.mat']));
        end
        if isempty(d)
          if numel(type)>3
            d(1).name = [subject 'coreginfo_' type{4}];
          else
            d(1).name = [subject 'coreginfo'];
          end
        end
      case 'coregMNI'
        d = dir(fullfile(D, [subject 'coregMNI.nii']));
        %d = dir([D 'cstr-' subject '-001.nii']);
        if isempty(d)
          d(1).name = [subject 'coregMNI'];
          %d(1).name = ['cstr-' subject '-001.nii'];
        end
      case 'coregMNIresliced'
        d = dir(fullfile(D, [subject 'coregMNIresliced.*']));
        if isempty(d)
          d(1).name = [subject 'coregMNIresliced'];
        end
      case 'coregMNIskullstrip'
        d = dir(fullfile(D, [subject 'coregMNIskullstrip.nii']));
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstrip'];
        end
        case 'coregMNIskullstripmask'
        d = dir(fullfile(D, [subject 'coregMNIskullstripmask.nii']));
        if isempty(d)
          d(1).name = [subject 'coregMNIskullstripmask'];
        end
      case 'headmodel'
        d = dir(fullfile(D, [subject 'vol.mat']));
        if isempty(d)
          d(1).name = [subject 'vol'];
        end
      case 'sourcemodelfif'
        D = fullfile(D,subject,'bem');
        d = dir(fullfile(D, '*src.fif'));
      case 'sourcemodelfifreg'
        D = [D subject filesep 'bem' filesep];
        d = dir([D '*src_reg.fif']);
      case 'sourcemodel2D'
        if numel(type)==3, type{4} = ''; end
        d = dir(fullfile(D, [subject 'sourcemodel2D' type{4} '.mat']));
        if isempty(d)
          d(1).name = [subject 'sourcemodel2D' type{4} '.mat'];
        end
      case 'sourcemodel2Dsurfreg'
        if numel(type)==3, type{4} = ''; end
        d = dir(fullfile(D, [subject 'sourcemodel2Dsurfreg' type{4} '.mat']));
        if isempty(d)
          d(1).name = [subject 'sourcemodel2Dsurfreg' type{4} '.mat'];
        end
      case 'sourcemodel3D'
        if numel(type)==3, type{4} = ''; end
        d = dir(fullfile(D, [subject 'sourcemodel3D' type{4} '.mat']));
        if isempty(d)
          d(1).name = [subject 'sourcemodel3D' type{4},'.mat'];
        end
      case 'figure'
        d = dir(fullfile(D, [subject 'figure_' type{4} '.png']));
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
  %      d = dir(fullfile(D, [subject 'figure_' type{4} '.png']);
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
  %case {'bfica' 'artifact' 'corrmnebf' 'restingstate' 'qualitycheck' 'mne' 'preproc' 'other' 'erf'} %FIXME add the other ones also, so that the 'processed' can be removed
  otherwise
    if endsWith(rootdir, '3011020.09') || endsWith(rootdir, '3011020.09/')
      D = fullfile(rootdir,'processed',subject,'meg',type{2});
    else
      D = fullfile(rootdir,subject,type{2});
    end
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
          d(1).folder = D;
        end
    end
  %otherwise
  %  error('unrecognized type requested');
end

for k = 1:numel(d)
  filename{k} = fullfile(d(k).folder,d(k).name);
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
