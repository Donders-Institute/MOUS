%%%%%%%%%%%%%%% Create MN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Covariance matrix
% Load erf raw fro covariance matrox
subjectname =  'V1012';
data = mous_db_getdata(subjectname, 'meg_processed_{rawERF02-1ds}');

% include both conditions (and all words?) and a longer time window for the
sel = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 |...
      data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8); 

% compute covariance matrix of the noise
cfg              = [];
cfg.trials         = sel;   
cfg.vartrllength = 2;
cfg.feedback     = 'textbar';
cfg.covariance   = 'yes';
%cfg.covariancewindow = [-inf 0]; % calculate the covariance matrix on the timepoints that are before the zero-time point in the trials 
cfg.covariancewindow = 'all';                                 
cfg.preproc.demean = 'yes';
cfg.channel          = 'MEG';
cfg.preproc.baselinewindow = [-inf 0];
tlck = ft_timelockanalysis(cfg, data);

%% 
% load the 2D grid
grid= mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');
% load the volume conductor model of the head
fname = mous_db_getfilename(subjectname,  'meg_anatomy_headmodel');
vol = ft_read_vol(fname{1});
  
%% Compute the leadfields

cfg         = [];
cfg.grad    = tlck.grad;
cfg.vol     = vol;
cfg.grid    = grid;
cfg.channel = 'MEG';
cfg.feedback = 'textbar';
grid        = ft_prepare_leadfield(cfg);

cfg                = [];
cfg.method         = 'mne';
cfg.vol            = vol;
cfg.grid           = grid;
cfg.mne.prewhiten  = 'yes';
cfg.mne.lambda     = 2;
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter = 'yes';
source             = ft_sourceanalysis(cfg, tlck);


%% Compute the MNE solution per condition
data = mous_db_getdata(subjectname, 'meg_processed_{ERF02-1ds-ag}');
cfg                 = [];
cfg.method          = 'mne';
cfg.vol             = vol;
cfg.grid.filter     = source.avg.filter;
cfg.mne.lambda      = 2;
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter  = 'yes';
mne_senTar          = ft_sourceanalysis(cfg, data{1});
mne_seqTar          = ft_sourceanalysis(cfg, data{2});

   

%% Visualization
% still frame
bnd= mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');

m=mne_senTar.avg.pow(:,150); % plotting the result at the 150th sample
ft_plot_mesh(bnd, 'vertexcolor', m);


% movie
cfg = [];
cfg.projectmom = 'yes';
sd_sentTar = ft_sourcedescriptives(cfg,mne_senTar);
sd_sentTar.tri = bnd.tri;
cfg = [];
cfg.mask = 'avg.pow';
ft_sourcemovie(cfg,sd_sentTar);

% edit getfilename and implment saving the solution 
%mous_db_putdata(subjectname, 'mne_solution', sd, source, grid, tlck);


  