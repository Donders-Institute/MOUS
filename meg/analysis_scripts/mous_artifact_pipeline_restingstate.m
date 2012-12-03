% this script contains the sequential steps for the artifact processing pipeline.
% for resting state data

% create directory that will contain the results
mous_db_makesubjdir(subjectname);

% extract the trial definition for the sentences
filename = mous_db_getfilename(subjectname, 'meg_raw_rest');

% define the epochs on which the artifacts will be detected
cfg          = [];
cfg.dataset  = filename{1};
cfg.trialdef.triallength = 2;
cfg          = ft_definetrial(cfg);
trl          = cfg.trl(2:end-1,:);

if 1,
  [cfgeog1, cfgeog2] = mous_artifact_eog(filename{1},        trl); % detect eog artifacts
  [cfgjump         ] = mous_artifact_squidjumps(filename{1}, trl); % detect squid jumps
  [cfgmuscle       ] = mous_artifact_muscle(filename{1},     trl); % detect muscle artifacts

  % put the results back into the database
  mous_db_putdata(subjectname, 'meg_artifact_cfg_restingstate', cfgeog1, cfgeog2, cfgjump, cfgmuscle); 
end

if 0,
  [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_blinks(filename{1},   trl);
  mous_db_putdata(subjectname, 'meg_artifact_dssblinks_restingstate', comp, avgcomp, avgpre, avgeog);
  
  %[comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_saccades(filename{1}, trl);
  %mous_db_putdata(subjectname, 'meg_artifactdsssaccades', comp, avgcomp, avgpre, avgeog);
end

