function mous_ERF_pipeline(subjectname)
% This script performs ERF analyses on preprocessed data.  
% NL 1-6-2012

% get the preprocessed data from the database
% type of data: long or short window needS to be specified
% data = mous_db_getdata(subjectname, 'meg_processed{rawERF05-3ds}');
% %THESE HAVE NOT YET BEEN CALCULATED. NL 1-6-2012

%data = mous_db_getdata(subjectname, 'meg_processed_{rawERF02-1ds}');
data = mous_db_getdata(subjectname, 'meg_processed_{rawERF05-3ds}');
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
cfg2.trials         = sel2;   
cfg2.vartrllength   = 2;

% AG calculations  --------------------------------------------------
% timelock analysis for axial gradient data
senTar_AG           = ft_timelockanalysis(cfg1, data);
seqTar_AG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
%cfg.baseline        = [-0.2 0];
cfg.baseline        = [-0.5 0];
cfg.channel          = 'MEG';
senTar_AG           = ft_timelockbaseline(cfg, senTar_AG);
seqTar_AG           = ft_timelockbaseline(cfg, seqTar_AG);



% PG calculations ----------------------------------------------------
% convert data to planar gradient
data                = ft_megplanar(cfgplanar,data);

% timelock analysis for planar gradient data
senTar_PG           = ft_timelockanalysis(cfg1, data);
seqTar_PG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
%cfg.baseline        = [-0.2 0];
cfg.baseline        = [-0.5 0];
cfg.channel          = 'MEG';
senTar_PG           = ft_timelockbaseline(cfg, senTar_PG);
seqTar_PG           = ft_timelockbaseline(cfg, seqTar_PG);

% combine planar gradient (CPG)
senTar_CPG          = ft_combineplanar([], senTar_PG);
seqTar_CPG          = ft_combineplanar([], seqTar_PG);


%% SAVE the data 

%mous_db_putdata(subjectname, 'meg_processed_{ERF02-1ds-ag}', senTar_AG, seqTar_AG);
%mous_db_putdata(subjectname, 'meg_processed_{ERF02-1ds-pg}', senTar_PG, seqTar_PG, senTar_CPG, seqTar_CPG);

mous_db_putdata(subjectname, 'meg_processed_{ERF05-3ds-ag}', senTar_AG, seqTar_AG);
mous_db_putdata(subjectname, 'meg_processed_{ERF05-3ds-pg}', senTar_PG, seqTar_PG, senTar_CPG, seqTar_CPG);

%% Write number of accepted trials into text file
txtfile = '/home/language/annhul/MOUS/Processed/MeanNumAcceptedAvg4ERF_Window05_3_partial_June12.txt';
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenTar mean:%d \tSD:%1.1f  \tSeqTar mean:%d \tSD:%1.1f \n', ...
              datestr(now), subjlist{k}, round(mean(senTar_AG.dof(1:end))), std(senTar_AG.dof(1:end)),round(mean(seqTar_AG.dof(1:end))), std(seqTar_AG.dof(1:end)));
fclose(fid);
fprintf('Updated number of averages file %s ', txtfile);

cmd = ['chmod g+w ' txtfile];
system(cmd);


  
% 
% cfg = [];
% cfg.showlabels = 'no'; 
% cfg.fontsize = 6; 
% cfg.interactive = 'yes';
% cfg.layout = 'CTF273.lay';
% figure; ft_multiplotER(cfg,senTar_AG, seqTar_AG);
% figure; ft_multiplotER(cfg,senTar_CPG, seqTar_CPG);

% %ft_multiplotER(cfg,RCsent, MCsent, RCseq, MCseq);
% cfg.ylim = [-2e-13 2e-13];