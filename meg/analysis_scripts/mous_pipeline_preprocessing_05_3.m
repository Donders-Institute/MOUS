mous_db_makesubjdir(subjectname)

% get the filename of the raw data
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

% get the description of the artifacts
tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');

cfg = [];
cfg.dataset           = filename{1};
cfg.trialdef.prestim  = 0.5;              % baseline
cfg.trialdef.poststim = 3.0-1./1200;      % pad
cfg.trialfun          = 'visual_word';    % 1s duration from onset of target word
[cfg]                 = ft_definetrial(cfg);      % ft_definetrial defines trials which are created in cfg.trl which is a parameter for ft_preprocessing
trl                   = cfg.trl;

cfg         = [];
cfg.trl     = trl;
cfg.dataset = filename{1};
cfg.artfctdef.zvalue1.artifact = tmp{1}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue2.artifact = tmp{2}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue3.artifact = tmp{3}.artfctdef.zvalue.artifact;
cfg.artfctdef.zvalue4.artifact = tmp{4}.artfctdef.zvalue.artifact;
% cfg.artfctdef.visual.artifact  = cfg2.artfctdef.visual.artifact;  % %additional eyeblinks to be removed after first round of preprocessing
cfg.artfctdef.reject           = 'partial';
cfg.artfctdef.minlength        = 0.1;
cfg         = ft_rejectartifact(cfg);
trl         = cfg.trl;

% just focus on the target words
sel = mod(trl(:,5),2)==0;
trl = trl(sel,:);

data = mous_preprocessing(filename{1}, trl, 300, 'TFR');

mous_db_putdata(subjectname, 'meg_processed_{raw05-3ds}', data);