%% THIS IS AN EXAMPLE SCRIPT
% sketches a strategy to identify artifacts

subjectname = 'A2035';
mous_db_getdata(subjectname, 'meg_erf_allwords_02-10-target-ag', '/project/3011020.09/annhul');
tlck = seqWord_AG;

cfgp.layout='CTF275.lay';
figure;ft_multiplotER(cfgp, tlck);

% identified channel: MLT41

% now use databrowser to manually identify this bad segment
f = mous_db_getfilename(subjectname, 'meg_ds_task');

mous_db_getdata(subjectname, 'meg_artifact_cfg');

trl = mous_defineTrial(f{1}, 0.2, 0.2, 'auditory_sentence');
trl = mous_artifact_remove(trl, f{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle});

cfg = [];
cfg.dataset = f{1};
cfg.trl     = trl;
cfg.channel = 'MLT41';
cfg.continuous = 'yes';
cfg.demean = 'yes';
data = ft_preprocessing(cfg);

cfgout    = ft_databrowser([], data);
cfgmanual.artfctdef = cfgout.artfctdef;
cfgmanual.artfctdef.type = 'visual';
mous_db_putdata('A2035', 'meg_artifact_cfg_manual', 'cfgmanual');


