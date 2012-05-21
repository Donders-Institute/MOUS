% this script contains the sequential steps for the artifact processing pipeline.
%
% $Id: mous_artifact_pipeline.m 42 2012-05-16 10:38:10Z jansch $

% create directory that will contain the results
mous_db_makesubjdir(subjectname);

% extract the trial definition for the sentences
filename = mous_db_getfilename(subjectname, 'meg_ds_task');

cfg = [];
cfg.dataset  = filename{1};
cfg.trialfun = 'visual_sentence';
cfg = ft_definetrial(cfg);
trl = cfg.trl;

% detect eog artifacts
[cfgeog1, cfgeog2] = mous_artifact_eog(filename{1}, trl);

% detect squid jumps
[cfgjump]       = mous_artifact_squidjumps(filename{1}, trl);

% detect muscle artifacts
[cfgmuscle]       = mous_artifact_muscle(filename{1}, trl);

mous_db_putdata(subjectname, 'meg_artifactcfg', cfgeog1, cfgeog2, cfgjump, cfgmuscle); 