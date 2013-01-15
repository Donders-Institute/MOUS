
%%%%%%%%%%%%%%% Create MN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   
% list ={ 'V1004'  'V1005'    'V1007'    'V1010'    'V1011'    'V1012' ...
%        'V1013'    'V1015'    'V1016'    'V1017'    'V1019'    'V1020'    'V1021'    'V1022' ...
%        'V1024'    'V1025'    'V1026'    'V1027'    'V1028'    'V1029'    'V1030'    'V1031'    'V1032' ...
%        'V1033'    'V1034'    'V1035'    'V1036'    'V1037'    'V1038'    'V1039'    'V1040'    'V1042' ...
%       'V1044'    'V1045'    'V1046'    'V1049'    'V1050'    'V1052'    'V1066'    'V1067'    'V1068' ...
%       'V1071'    'V1072'    'V1077'    'V1078'    'V1079'};
% 


% Always exlcuded V1014 V1018 V1043 V1051 V1056 V1060 V1082   

% for k= 1:length(subjlist)
%    subjectname = subjlist{k};

%% Covariance matrix
% Load preprocessed rawERF for covariance matrix
% data is filtered and artefacts are removed, all stim conditions are then
% selected for the actual covariance matrix
data = mous_db_getdata(subjectname, 'meg_processed_{preProcERFvisual_word_all_02-1ds}');


% include both conditions (targets only)
%sel = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 |...
 %     data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8); 
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
data = mous_db_getdata(subjectname,'meg_processed_{ERFvisual_word_Allwords_02-1ds-ag}');
%data  = mous_db_getdata(subjectname, 'meg_processed_{ERF02-1ds-ag}');

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
mous_db_putdata(subjectname, 'meg_processed_{MNE02-1ds_Allwords_Seq_20121126}',sd_Seq , source_seq, grid, tlck);
mous_db_putdata(subjectname, 'meg_processed_{MNE02-1ds_Allwords_Sent_20121126}',sd_Sent, source_sent,  grid, tlck);
%end


%% Visualization
% still frame
% 
% m=mne_senTar.avg.pow(:,150); % plotting the result at the 150th sample
% ft_plot_mesh(bnd, m);


% movie
% %figure;plot(sd1.time,sd1.avg.pow2')
% % 
%      subjectname = 'V1017';
%      [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_target_Seq_20121122}');
%      load(filename{1})
%      [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_target_Sent_20121122}');
%      load(filename{1})
% % sd_Seq.pos_sur = sd_Seq.pos;
% % sd_Sent.pos_sur = sd_Sent.pos;
% sd_Seq.pos = sd_Seq.pos_infl;
% sd_Sent.pos = sd_Sent.pos_infl;
%         figure
%         cfg = [];
%         cfg.funparameter = 'avg.dspm';
%         ft_sourcemovie(cfg,sd_Sent, sd_Seq);
% % % %    
%  
% 


% sdDIFF = sd1;
% sdDIFF.avg.pow2 = sd1.avg.pow2 - sd2.avg.pow2;
% sdDIFF.pos = sd1.pos;
%   figure
%    cfg = [];
%    cfg.funparameter = 'avg.pow2';
%    ft_sourcemovie(cfg,sdDIFF);
   

  