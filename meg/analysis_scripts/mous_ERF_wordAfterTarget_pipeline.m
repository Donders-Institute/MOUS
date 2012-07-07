function mous_ERF_wordAfterTarget_pipeline(subjectname, type)
% This script performs ERF analyses on preprocessed data.  
% NL 1-6-2012

% get the preprocessed data from the database
% type of data: long or short window needS to be specified
% data = mous_db_getdata(subjectname, 'meg_processed{rawERF05-3ds}');

type = 'short';

if strcmp(type, 'short')
  inputdata = 'meg_processed_{rawERF_tarplusOne_02-1ds}';
  outputdata = 'meg_processed_{ERF_tarplusOne_02-1ds';
  % outputdata = 'meg_processed_{ERF_tarplusTwo_02-1ds';
  baseln = -0.2;
elseif strcmp(type,'long')
  inputdata = 'meg_processed_{rawERF_tarplusOne_05-3ds}';
  %outputdata = 'meg_processed_{ERF05-3ds_';
  outputdata = 'meg_processed_{ERF_tarplusOne_05-3ds';
  % outputdata = 'meg_processed_{ERF_tarplusTwo_05-3ds';
  baseln = -0.5;
end    

data = mous_db_getdata(subjectname, inputdata);


%% Calculate the ERF
fprintf('Calculating ERF for subject %s for conditions SenTar and SeqTar\n', subjectname);

% Apply configurations for steps in analysis -------------------------

% for planar gradient computation
cfgplanar              = [];
cfgplanar.planarmethod = 'sincos';  
cfg_neighb.method      = 'distance'; 
cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data); 

% IDENTIFY TRIALS for the conditions (ref: trialfun in mous_preprocessing pipeline)

sel1 = find(data.trialinfo(:,2)==1 | data.trialinfo(:,2)==5);   % sentences target word
sel2 = find(data.trialinfo(:,2)==3 | data.trialinfo(:,2)==7);  

   
% cfg for condition specific analyses  
    % First word after target
    cfg1                = [];       %  1 = sentences
    cfg1.trials         = sel1;   
    cfg1.vartrllength   = 2;

    cfg2                = [];       %  2 = sequences
    cfg2.trials         = sel2; 
    cfg2.vartrllength   = 2;

% AG calculations  --------------------------------------------------
% timelock analysis for axial gradient data
senTarPlusOne_AG    = ft_timelockanalysis(cfg1, data);
seqTarPlusOne_AG    = ft_timelockanalysis(cfg2, data);
% senTarPlusTwo_AG    = ft_timelockanalysis(cfg3, data);
% seqTarPlusTwo_AG    = ft_timelockanalysis(cfg4, data);

cfg                 = [];  
cfg.baseline        = [baseln 0];
cfg.channel         = 'MEG';
senTarPlusOne_AG    = ft_timelockbaseline(cfg, senTarPlusOne_AG);
seqTarPlusOne_AG    = ft_timelockbaseline(cfg, seqTarPlusOne_AG);
% senTarPlusTwo_AG    = ft_timelockbaseline(cfg, senTarPlusTwo_AG);
% seqTarPlusTwo_AG    = ft_timelockbaseline(cfg, seqTarPlusTwo_AG);



% PG calculations ----------------------------------------------------
% convert data to planar gradient
data                = ft_megplanar(cfgplanar,data);

% timelock analysis for planar gradient data
senTarPlusOne_PG    = ft_timelockanalysis(cfg1, data);
seqTarPlusOne_PG    = ft_timelockanalysis(cfg2, data);
% senTarPlusTwo_PG    = ft_timelockanalysis(cfg3, data);
% seqTarPlusTwo_PG    = ft_timelockanalysis(cfg4, data);

cfg                 = [];  
cfg.baseline        = [baseln 0];
cfg.channel         = 'MEG';
senTarPlusOne_PG    = ft_timelockbaseline(cfg, senTarPlusOne_PG);
seqTarPlusOne_PG    = ft_timelockbaseline(cfg, seqTarPlusOne_PG);
% senTarPlusTwo_PG    = ft_timelockbaseline(cfg, senTarPlusTwo_PG);
% seqTarPlusTwo_PG    = ft_timelockbaseline(cfg, seqTarPlusTwo_PG);

% combine planar gradient (CPG)
senTarPlusOne_CPG   = ft_combineplanar([], senTarPlusOne_PG);
seqTarPlusOne_CPG   = ft_combineplanar([], seqTarPlusOne_PG);
% senTarPlusTwo_CPG   = ft_combineplanar([], senTarPlusTwo_PG);
% seqTarPlusTwo_CPG   = ft_combineplanar([], seqTarPlusTwo_PG);

%% SAVE the data 

outname = strcat(outputdata, '-ag}');
mous_db_putdata(subjectname,outname, senTarPlusOne_AG, seqTarPlusOne_AG); %senTarPlusTwo_AG, seqTarPlusTwo_AG);

outname = strcat(outputdata, '-pg}');
mous_db_putdata(subjectname, outname, senTarPlusOne_PG, seqTarPlusOne_PG, senTarPlusOne_CPG, seqTarPlusOne_CPG); % seqTarPlusTwo_CPG, senTarPlusTwo_PG, seqTarPlusTwo_PG, senTarPlusTwo_CPG, seqTarPlusTwo_CPG);

%% Write number of accepted trials into text file
txtfile = sprintf('/home/language/annhul/MOUS/Processed/MeanNumAcceptedAvg_%s_tarplusOne_6July2012.txt',outputdata(16:22));
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenTarPlusOne mean:%d \tSD:%1.1f  SeqTarPlusOne mean:%d \tSD:%1.1f   SenTarPlusTwo mean:%d \tSD:%1.1f  \tSeqTarPlusOne mean:%d \tSD:%1.1f\n', ...
       datestr(now), subjectname, round(mean(senTarPlusOne_AG.dof(1:end))),std(senTarPlusOne_AG.dof(1:end)),round(mean(seqTarPlusOne_AG.dof(1:end))),std(seqTarPlusOne_AG.dof(1:end)));
                                % round(mean(senTarPlusTwo_AG.dof(1:end))), std(senTarPlusTwo_AG.dof(1:end)),round(mean(seqTarPlusTwo_AG.dof(1:end))), std(seqTarPlusTwo_AG.dof(1:end)));
fclose(fid);
fprintf('Updated number of averages file %s ', txtfile);
cmd = ['chmod g+w ' txtfile];
system(cmd);
