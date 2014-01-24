
%%%%%%%%%%%%%%% Create MN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   
% subjlist  26.11 2012
% subj = {'V1004' 'V1005' 'V1007' 'V1010' 'V1011' 'V1012' 'V1015' 'V1016' 'V1017'...
%         'V1019' 'V1020' 'V1021' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
%         'V1030' 'V1032' 'V1034' 'V1036' 'V1037' 'V1039' 'V1042' ...
%         'V1044' 'V1045' 'V1046' 'V1049' 'V1050' 'V1052' 'V1066' 'V1067' 'V1068' 'V1071' ...
%         'V1072' 'V1077'}; 

% %subjlist 9.4 2013 %  'V1001'      
%    subj = { 'V1001'  'V1002'    'V1003'    'V1004'    'V1005'    'V1007'    'V1008'    'V1009'    'V1010' ...
%     'V1011'    'V1012'    'V1013'     'V1015'    'V1016'    'V1017'    'V1019'    'V1020'    'V1021' ...
%     'V1023'    'V1024'    'V1025'    'V1026'    'V1027'    'V1028'    'V1030'    'V1031'    'V1032'    'V1033' ...
%     'V1034'    'V1035'    'V1036'    'V1037'    'V1038'    'V1039'    'V1040'    'V1042'    'V1044' ...
%     'V1045'    'V1048'    'V1049'    'V1050'    'V1052'    'V1053'    'V1054'    'V1055'    'V1057'    'V1059' ...
%     'V1061'    'V1062'    'V1063'    'V1064'    'V1065'    'V1066'    'V1068'    'V1069'   'V1070' ...
%     'V1071'    'V1072'    'V1074'    'V1075'    'V1076'    'V1077'    'V1078'    'V1079'    'V1080' ...
%     'V1081'    'V1083'    'V1084'    'V1085'    'V1086'    'V1087'    'V1090'    'V1093'    'V1094'    'V1095' ...
%     'V1098'    'V1100'    'V1101'    'V1102'    'V1103'    'V1104'    };

% subject list 2.5 2013 84 subj
% subj = { 'V1001'    'V1002'    'V1003'    'V1004'    'V1005'...
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
    
% Always exlcuded V1014 V1018 V1043 V1051 V1056 V1060 V1082 

%visual final data set
load MOUS/meg/subjects_OK_20130613.mat
% 

% % auditory run 13. 8 2013
%  subj = { 'A2001'  'A2003'  'A2004'  'A2005' ...  
%           'A2006'  'A2007'  'A2008'  'A2009'  'A2010' ...  
%           'A2012'  'A2013'  'A2015'  'A2018'  'A2019' ... 
%            'A2021'  'A2023' 'A2025'  'A2026'  'A2027' ...
%            'A2029'};


for k= 1:numel(subj)
    subjectname = subj{k};

%% Covariance matrix
% Load preprocessed rawERF for covariance matrix
% data is filtered and artefacts are removed, all stim conditions are then
% selected for the actual covariance matrix
%data = mous_db_getdata(subjectname, 'meg_processed_{preProcERFvisual_word_all_02-1ds}');

tmp = mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}');
data = tmp{1};   

% auditory version
data = mous_db_getdata(subjectname, 'meg_processed_{_preProcERFauditory_word_02-1ds}');

% include both conditions (targets only)
% sel = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 |...
%      data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8); 
 
% % include both conditions (first word aud.)
% sel = find(data.trialinfo(:,2)==1 | data.trialinfo(:,2)==5 |...
%      data.trialinfo(:,2)==3 | data.trialinfo(:,2)==7); 
  
 % all words  
sel = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 |...
       data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8 |...
   data.trialinfo(:,2)==1 | data.trialinfo(:,2)==3 |...
    data.trialinfo(:,2)==5 | data.trialinfo(:,2)==7 );

% compute covariance matrix of the noise
cfg              = [];
%cfg.trials         = sel;   
cfg.vartrllength = 2;
cfg.feedback     = 'textbar';
cfg.covariance   = 'yes';
cfg.covariancewindow = [-inf 1]; % calculate the covariance matrix on the timepoints that are before the zero-time point in the trials 
%cfg.covariancewindow = 'all';                                 
cfg.preproc.demean = 'yes';
%cfg.channel          = 'MEG';
cfg.keeptrials = 'no';
cfg.preproc.baselinewindow = [-inf 0];
tlck = ft_timelockanalysis(cfg, data);

%% 
% load the 2D grid
grid= mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  %having grid here and below is confusing
if ~isfield(grid, 'pos') && isfield(grid, 'pnt')
  grid.pos = grid.pnt;
  grid = rmfield(grid, 'pnt');
end

% load the volume conductor model of the head
fname = mous_db_getfilename(subjectname,  'meg_anatomy_headmodel');
vol = ft_read_vol(fname{1});
  
%% Compute the leadfields

% Forward solution  

cfg         = [];
cfg.grad    = tlck.grad;
cfg.vol     = vol;
cfg.grid    = grid;
cfg.channel = 'MEG';
cfg.feedback = 'textbar';
grid        = ft_prepare_leadfield(cfg);  %having grid here and above is confusing

%% Compute MNE for each condition
%data = mous_db_getdata(subjectname, 'meg_processed_{ERF_targetword_02-1ds-ag}');
%data = mous_db_getdata(subjectname, 'meg_processed_{ERFvisual_word_targetword_02-1ds-ag}');
%data = mous_db_getdata(subjectname,'meg_processed_{ERFvisual_word_Allwords_02-1ds-ag}');
data = mous_db_getdata(subjectname,'meg_processed_{_erf_visual_word_all_02-1ds-ag}');
data = mous_db_getdata(subjectname, 'meg_processed_{_erf_auditory_word_target_02-1ds-ag-orgBase}');
%data = mous_db_getdata(subjectname, 'meg_processed_{_erf_auditory_word_first_02-1ds-ag-orgBase}');


data1 = data{1}; % sentTar_AG
data1.cov = tlck.cov; % add the covariance computed from both conditions
data2 = data{2}; % seqTar_AG
data2.cov = tlck.cov;

cfg                = [];
cfg.method         = 'mne';
cfg.vol            = vol;
cfg.grid           = grid;
cfg.mne.prewhiten  = 'yes';
cfg.mne.lambda     = 3; % used to be 2
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter = 'yes';
source_sent            = ft_sourceanalysis(cfg, data1);
source_seq            = ft_sourceanalysis(cfg, data2);

cfg            = [];
cfg.demean     = 'yes';
cfg.projectmom = 'yes';
cfg.zscore     = 'no';
sd_Sent            = ft_sourcedescriptives(cfg, source_sent);
sd_Seq            = ft_sourcedescriptives(cfg, source_seq);



%% Surfaces & saving 

bndinflated = mous_inflatedmesh(subjectname);
%source1.pos = bndinflated.pos;
%sd1            = ft_sourcedescriptives(cfg, source1);
%sd1.pos = bndinflated.pos;

bnd     = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');

sd_Sent.tri = bnd.tri;
sd_Sent.pos = bnd.pos; % surface
sd_Sent.pos_infl = bndinflated.pos; % inflated 

sd_Seq.tri = bnd.tri;
sd_Seq.pos = bnd.pos; % surface
sd_Seq.pos_infl = bndinflated.pos; % inflated 

% do the normalisation to get a 'dSPM'
npnt = size(sd_Sent.pos,1);
sd_Sent.avg.dspm = spdiags(1./sd_Sent.avg.noise,0,npnt,npnt)*sd_Sent.avg.pow;
sd_Seq.avg.dspm = spdiags(1./sd_Seq.avg.noise,0,npnt,npnt)*sd_Seq.avg.pow;


% save the solution
mous_db_putdata(subjectname, 'meg_processed_{MNE02-1ds_target_Seq}','sd_Seq' , 'source_seq', 'grid', 'tlck');
mous_db_putdata(subjectname, 'meg_processed_{MNE02-1ds_target_Sent}','sd_Sent', 'source_sent',  'grid', 'tlck');

end


%% Visualization
% still frame
% 
% m=mne_senTar.avg.pow(:,150); % plotting the result at the 150th sample
% ft_plot_mesh(bnd, m);


% movie
% %figure;plot(sd1.time,sd1.avg.pow2')
% 
%      subjectname = 'V1022';
%               [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent}');
%               load(filename{1})
%               [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq}');
%               load(filename{1})
% % sd_Seq.pos_sur = sd_Seq.pos;
% % sd_Sent.pos_sur = sd_Sent.pos;
%          sd_Seq.pos = sd_Seq.pos_infl;
%          sd_Sent.pos = sd_Sent.pos_infl;
%           figure
%           cfg = [];
%           cfg.funparameter = 'avg.dspm';
%           ft_sourcemovie(cfg,sd_Sent, sd_Seq);
% % % %    
 



% sdDIFF = sd1;
% sdDIFF.avg.pow2 = sd1.avg.pow2 - sd2.avg.pow2;
% sdDIFF.pos = sd1.pos;
%   figure
%    cfg = [];
%    cfg.funparameter = 'avg.pow2';
%    ft_sourcemovie(cfg,sdDIFF);
   

  