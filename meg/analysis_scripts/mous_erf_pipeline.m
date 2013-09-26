

% subject list 2.5 2013
% subjectnames = { 'V1001'    'V1002'    'V1003'    'V1004'    'V1005'...
%     'V1007'    'V1008'    'V1009'    'V1010'    'V1011'    'V1012' ...
%     'V1013'    'V1015'    'V1016'    'V1017' ...    
%     'V1019'    'V1020'    'V1021'    'V1022'    'V1023'    'V1024' ...
%     'V1025'    'V1026'    'V1027'    'V1028'    'V1030'    'V1031' ...
%     'V1032'    'V1034'    'V1035'    'V1036'    'V1037'    'V1038' ...
%     'V1040'    'V1042'    'V1044'    'V1045'    'V1048' ...
%     'V1049'    'V1050'    'V1052'    'V1053'    'V1054'    'V1055' ...
%     'V1057'    'V1058'    'V1059'    'V1061'    'V1062'    'V1064' ...
%     'V1065'    'V1066'    'V1068'    'V1069'    'V1071' ...
%     'V1072'    'V1073'    'V1074'    'V1076'    'V1077'    'V1078' ...
%     'V1079'    'V1080'    'V1081'    'V1083'    'V1084'    'V1085' ...
%     'V1086'    'V1087'    'V1088'    'V1089'    'V1090'    'V1092' ...
%     'V1093'    'V1094'    'V1095'    'V1099'    'V1100'    'V1101' ...
%     'V1102'    'V1103'    'V1104'    'V1106'    'V1107' };

% Use Annika's list if subjectname is not defined in the workspace, else
% use the defined subjectname: this allows for use with qsub
if ~exist('subjectname', 'var')
  load MOUS/meg/subjects_OK_20130613.mat
elseif ~iscell(subjectname)
  subj = {subjectname};
else
  subj = subjectname;
end

if ~exist('rootdir', 'var')
  rootdir = '/home/language/annhul/MOUS/meg';
end

if ~exist('inputdata', 'var')
  length   = '02-1'; %means -0.2 to 1 sec
  wordType = 'all'; 
  trialfun = 'visual_word';
  inputdata  = ['meg_processed_{_preProcERF' trialfun '_' wordType '_' length 'ds}'];
  outputdata = ['meg_processed_{_erf_' trialfun '_' wordType '_' length 'ds'];
  outname1   = strcat(outputdata, '-ag}');
  outname2   = strcat(outputdata, '-pg}');
end

if ~exist('outputdata', 'var')
  error('you need to specify the name of the file that will contain the output data');
end

if ~exist('outname1', 'var')
  outname1 = strcat(outputdata, '-ag');
  outname2 = strcat(outputdata, '-pg');
end

for k = 1:numel(subj)
  subjectname = subj{k};
  
  % get the preprocessed data from the database
%   tmp  = mous_db_getdata(subjectname, inputdata);
%   if iscell(tmp)
%     data = tmp{1};
%   else
%     data = tmp;
%   end
%   clear tmp;
  load(fullfile(rootdir,subjectname,'erf',[subjectname,inputdata(4:end)]));
  

  % auditory data is apparently used, select whether to use the first
  % words, or the targets: first words are odd numbered, targets are even
  % numbered
  if ~isempty(strfind(inputdata, 'auditory'))
    % use the first words here
    %sel = find(mod(data.trialinfo(:,2),2)==1);
    sel = find(mod(data.trialinfo(:,2),2)==0);
    cfg.trials = sel;
    data = ft_preprocessing(cfg, data);
  end
  [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data);
  
  mous_db_putdata(subjectname, outname1, 'senWord_AG', 'seqWord_AG',rootdir);
  mous_db_putdata(subjectname, outname2, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG', 'stdev',rootdir);
end