% This script performs ERF analyses on preprocessed data.  
% NL 1-6-2012

% get the preprocessed data from the database
% type of data: long or short window needS to be specified
% data = mous_db_getdata(subjectname, 'meg_processed{rawERF05-3ds}');
% %THESE HAVE NOT YET BEEN CALCULATED. NL 1-6-2012

subjectname = 'V1025';
data = mous_db_getdata(subjectname, 'meg_processed_{rawERF02-1ds}');

% for n = 1:length(subjects)   
% subjectname = subjects{n};

%% Calculate the ERF
fprintf('Calculating ERF for subject %s for conditions SenTar and SeqTar\n', subjectname);

% Apply configurations for steps in analysis -------------------------

% for planar gradient computation
cfgplanar              = [];
cfgplanar.planarmethod = 'sincos';  
cfg_neighb.method      = 'distance'; 
cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data); 

% identify the trials for the conditions (ref: trialfun in mous_preprocessing pipeline)
sel1 = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6);   % sentences
sel2 = find(data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);   % sequences

% cfg for condition specific analyses
cfg1                = [];       %  1 = sentences
cfg1.trials         = sel1;   
cfg1.vartrllength   = 2;

cfg2                = [];       %  2 = sequences
cfg2.trials         = sel1;   
cfg2.vartrllength   = 2;

% AG calculations  --------------------------------------------------
% timelock analysis for axial gradient data
senTar_AG           = ft_timelockanalysis(cfg1, data);
seqTar_AG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
cfg.baseline        = [-0.2 0];
cfg.channel          = 'MEG';
senTar_AG           = ft_timelockbaseline(cfg, senTar_AG);
seqTar_AG           = ft_timelockanalysis(cfg, seqTar_AG);



% PG calculations ----------------------------------------------------
% convert data to planar gradient
data                = ft_megplanar(cfgplanar,data);

% timelock analysis for planar gradient data
senTar_PG           = ft_timelockanalysis(cfg1, data);
seqTar_PG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
cfg.baseline        = [-0.2 0];
cfg.channel          = 'MEG';
senTar_PG           = ft_timelockbaseline(cfg, senTar_PG);
seqTar_PG           = ft_timelockanalysis(cfg, seqTar_PG);

% combine planar gradient (CPG)
senTar_CPG          = ft_combineplanar([], senTar_PG);
seqTar_CPG          = ft_combineplanar([], seqTar_PG);


%% SAVE the data 

mous_db_putdata(subjectname, 'meg_processed_{ERF02-1ds-ag}', senTar_AG, seqTar_AG);
mous_db_putdata(subjectname, 'meg_processed_{ERF02-1ds-pg}', senTar_PG, seqTar_PG);

%% Write number of accepted trials into text file
txtfile = '/home/language/annhul/MOUS/Processed/NumAcceptedAvg4ERF_Window02_1_partial_June5.txt';
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenTar %d  SeqTar %d \n', datestr(now), subjectname, senTar_AG.dof(1),seqTar_AG.dof(1));
fclose(fid);
fprintf('Updated number of averages file %s ', txtfile);


  
% 
cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF273.lay';
figure; ft_multiplotER(cfg,senTar_AG, seqTar_AG);
% figure; ft_multiplotER(cfg,senTar_CPG, seqTar_CPG);

% %ft_multiplotER(cfg,RCsent, MCsent, RCseq, MCseq);
% cfg.ylim = [-2e-13 2e-13];