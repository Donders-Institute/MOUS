function mous_erf_pipeline(subjectname, length, wordType)
% This script performs ERF analyses on preprocessed data for one subject
% To run across subjects use qsub

% NL, AH 1-6-2012. Mod: 9-17-2012 (NL)

%% Paramters
% Window length: long/short
% wordType = target/ allWords
if strcmp(length, 'short')
  %inputdata = 'meg_processed_{_preprocERFauditory_wordall02-1ds}';
  inputdata = 'meg_processed_{_preProcERFvisual_word_all_02-1ds}';
  
  
  %outputdata = 'meg_processed_{_erf_Firstword_02-1ds';
  outputdata = 'meg_processed_{_erf_visual_word_all_02-1ds';
  baseln = -0.2;
elseif strcmp(length,'long')
  inputdata = 'meg_processed_{_preprocERF_targetword_05-3ds}';
  outputdata = 'meg_processed_{_erf_targetword_05-3ds';
  baseln = -0.5;
end

% get the preprocessed data from the database
tmp = mous_db_getdata(subjectname, inputdata);
data = tmp{1};
clear tmp;
% data = mous_db_getdata(subjectname, 'meg_processed{rawERF05-3ds}');

%% Calculate the ERF
fprintf('Calculating ERF for subject %s for conditions SenTar and SeqTar\n', subjectname);

% Apply configurations for steps in analysis -------------------------

% for planar gradient computation
cfgplanar              = [];
cfgplanar.planarmethod = 'sincos';  
cfg_neighb.method      = 'distance'; 
cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data); 

% identify the trials for the conditions (ref: trialfun in mous_preprocessing pipeline)
% implement later in this script (or in a script at an earlier/latter stage
% to identify specific words e.g., noun only, target + 1)

if strcmp(wordType, 'target')
    sel1 = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6);   % sentences target word
    sel2 = find(data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);   % sequences target word
elseif strcmp(wordType,'allWords')  % all words in the sentence
    sel1 = find(data.trialinfo(:,2)==1 | data.trialinfo(:,2)==5 | data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 );  % sentences
    sel2 = find(data.trialinfo(:,2)==3 | data.trialinfo(:,2)==7 | data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);  % sequences
end

% cfg for condition specific analyses
cfg1                = [];       %  1 = sentences
cfg1.trials         = sel1;   
cfg1.vartrllength   = 2;

cfg2                = [];       %  2 = sequences
cfg2.trials         = sel2;   
cfg2.vartrllength   = 2;

% AG calculations  --------------------------------------------------
% timelock analysis for axial gradient data
senWord_AG           = ft_timelockanalysis(cfg1, data);
seqWord_AG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
cfg.baseline        = [baseln 0];
cfg.channel          = 'MEG';
senWord_AG           = ft_timelockbaseline(cfg, senWord_AG);
seqWord_AG           = ft_timelockbaseline(cfg, seqWord_AG);


% PG calculations ----------------------------------------------------
% convert data to planar gradient
data                = ft_megplanar(cfgplanar,data);

cfg1.trackcallinfo = 'no'; 
cfg2.trackcallinfo = 'no';

% timelock analysis for planar gradient data
senWord_PG           = ft_timelockanalysis(cfg1, data);
seqWord_PG           = ft_timelockanalysis(cfg2, data);

cfg                 = [];  
cfg.baseline        = [baseln 0];
cfg.channel          = 'MEG';

senWord_PG           = ft_timelockbaseline(cfg, senWord_PG);
seqWord_PG           = ft_timelockbaseline(cfg, seqWord_PG);

% combine planar gradient (CPG)
senWord_CPG          = ft_combineplanar([], senWord_PG);
seqWord_CPG          = ft_combineplanar([], seqWord_PG);


%% SAVE the data 

outname = strcat(outputdata, '-ag}');
mous_db_putdata(subjectname, outname, 'senWord_AG', 'seqWord_AG');
outname = strcat(outputdata, '-pg}');
mous_db_putdata(subjectname, outname, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG');
 
% %% Write number of accepted trials into text file
% <<<<<<< HEAD
 txtfile = sprintf('/home/language/annhul/MOUS/meg/%s/MeanNumAvgTrials%s_%s.txt',subjectname, outputdata(16:23), date);
% =======
 txtfile = sprintf('/home/language/annhul/MOUS/MeanNumAvgTrials_%s_%s.txt',outputdata(16:22), date);
% >>>>>>> 9c7d59defffa7fcef05830edcefb91819553d461
 fid = fopen(txtfile, 'a');
% 
 fprintf(fid, '%s %s SenWord mean:\t%d\t SD:\t%1.1f \tSeqWord mean:\t%d\t SD:\t%1.1f \n', ...
               datestr(now), subjectname, round(mean(senWord_AG.dof(1:end))), std(senWord_AG.dof(1:end)),round(mean(seqWord_AG.dof(1:end))), std(seqWord_AG.dof(1:end)));          
 fclose(fid);
% 
 fprintf('Updated number of averages file %s ', txtfile);
 cmd = ['chmod g+w ' txtfile];
 system(cmd);
