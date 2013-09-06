% mous_artifact_pipeline
% this script contains the sequential steps for the artifact processing pipeline.
% define the epochs on which the artifacts will be detected
%%% READ ME: If there are less than 240 trials, check on Big-U site whether
%%% subject has TWO files for task data (due to the MEG PC crashing halfway).
%%% If so there are two options:
% (1) the variable 'filename' will have 2 variables, and you can select the
% second one by changing <filename{1} to <filename{2}> in the script below
% and then proceed as usual.
% (2) variable 'filename' only has 1 variable, but if you manually go to
% the subject's directory ~annhul/MOUS/meg/A2XX/RAW you see 2 task files,
% then you should change the actual input to the second file's filename as follows
% <filename{1} = 'AXXX....ds'>
% You can then proceed as follow with selecting the code below the line
% that defines filename.

%% Artifact detection (Nietz stuff)
% create directory that will contain the results
mous_db_makesubjdir(subjectname);

% extract the trial definition for the sentences
filename = mous_db_getfilename(subjectname, 'meg_ds_task');

% replace the below 0 with an actual number, if a local averaging/std
% computation is required in mous_artifact_muscle
ntrials = 0;

cfg          = [];
cfg.dataset  = filename{1};
%cfg.trialfun = 'visual_sentence';
cfg.trialfun = 'auditory_sentence';
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
trl(:,1) = trl(:,1) - 0.2*1200;
trl(:,2) = trl(:,2) + 0.1*1200;

if 1,
  [cfgeog1       ] = mous_artifact_eogb(filename{1},        trl); % detect blinks
  [cfgeog2       ] = mous_artifact_eogs(filename{1},        trl); % detect saccades
  [cfgjump       ] = mous_artifact_squidjumps(filename{1}, trl); % detect squid jumps
  [cfgmuscle     ] = mous_artifact_muscle(filename{1},     trl, ntrials); % detect muscle artifacts

  % put the results back into the database
  mous_db_putdata(subjectname, 'meg_artifact_cfg', 'cfgeog1', 'cfgeog2', 'cfgjump', 'cfgmuscle',0); 
end

%% Artifact detection for Jan-Mathijs' stuff 
if 0,
  [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_blinks(filename{1},   trl);
  mous_db_putdata(subjectname, 'meg_artifact_dssblinks', 'comp', 'avgcomp', 'avgpre', 'avgeog');
  
  %[comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_saccades(filename{1}, trl);
  %mous_db_putdata(subjectname, 'meg_artifactdsssaccades', comp, avgcomp, avgpre, avgeog);
end

