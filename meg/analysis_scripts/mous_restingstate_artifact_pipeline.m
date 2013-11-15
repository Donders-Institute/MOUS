% this script contains the sequential steps for the artifact processing pipeline.

% create directory that will contain the results
%mous_db_makesubjdir(subjectname, rootdir);

% extract the trial definition for the sentences
filename = mous_db_getfilename(subjectname, 'meg_ds_rest');

% replace the below 0 with an actual number, if a local averaging/std
% computation is required in mous_artifact_muscle
ntrials = 0;

hdr  = ft_read_header(filename{1});
%nsmp = hdr.nSamples*hdr.nTrials; 
nsmp = 365000; % replaces the previous, it seems that there is a consistent spike at ~368000
clear trl;
trl(:,1) = (301:2400:(nsmp-2700))';
trl(:,2) = (2700:2400:(nsmp-300))';
trl(:,3) = 0;

if 1,
  [cfgeog1, cfgeog2] = mous_artifact_eog(filename{1},        trl); % detect eog artifacts
  [cfgjump         ] = mous_artifact_squidjumps(filename{1}, trl); % detect squid jumps
  [cfgmuscle       ] = mous_artifact_muscle(filename{1},     trl, ntrials); % detect muscle artifacts

  % put the results back into the database
  mous_db_putdata(subjectname, 'meg_artifact_cfg_restingstate', 'cfgeog1', 'cfgeog2', 'cfgjump', 'cfgmuscle'); 
end

if 0,
  [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_blinks(filename{1},   trl);
  mous_db_putdata(subjectname, 'meg_artifact_dssblinks', 'comp', 'avgcomp', 'avgpre', 'avgeog');
  
  %[comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_saccades(filename{1}, trl);
  %mous_db_putdata(subjectname, 'meg_artifactdsssaccades', comp, avgcomp, avgpre, avgeog);
end

