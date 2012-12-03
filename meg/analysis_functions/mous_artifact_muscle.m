function [cfgmuscle] = mous_artifact_muscle(filename, trl)

% $Id: mous_artifact_muscle.m 44 2012-05-16 10:42:21Z jansch $

% muscle artifacts
cfg                          = [];
cfg.trl                      = trl;
cfg.continuous               = 'yes';
cfg.dataset                  = filename;
cfg.memory                   = 'low';

cfg.artfctdef.zvalue.method  = 'all';
cfg.artfctdef.zvalue.ntrial  = 10;

%cfg.artfctdef.zvalue.method  = 'trialdemean';
cfg.artfctdef.zvalue.ntrial  = 15;

cfg.artfctdef.zvalue.channel = {'MEG'};
cfg.artfctdef.zvalue.bpfilter = 'no';
cfg.artfctdef.zvalue.hilbert  = 'no';
cfg.artfctdef.zvalue.rectify  = 'yes';
cfg.artfctdef.zvalue.hpfilter = 'yes';
cfg.artfctdef.zvalue.hpfreq   = 80;
cfg.artfctdef.zvalue.cutoff     = 10;
cfg.artfctdef.zvalue.demean     = 'yes';
cfg.artfctdef.zvalue.boxcar     = 0.5;
cfg.artfctdef.zvalue.fltpadding = 0;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0.25; % 1 sec padding
cfg.artfctdef.zvalue.interactive= 'yes';
cfg.artfctdef.type           = 'zvalue';
cfg.artfctdef.reject         = 'partial';

cfg       = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfgmuscle = ft_artifact_zvalue(cfg);
