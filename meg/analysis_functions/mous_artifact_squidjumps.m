function [cfgout] = mous_artifact_squidjumps(filename, trl)

% $Id: mous_artifact_squidjumps.m 44 2012-05-16 10:42:21Z jansch $

% SQUID jumps
cfg                              = [];
cfg.trl                          = trl;
cfg.continuous                   = 'yes';
cfg.dataset                      = filename;
cfg.memory                       = 'low';
cfg.artfctdef.zvalue.channel       = {'MEG'};
cfg.artfctdef.zvalue.medianfilter  = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.cutoff        = 100;
cfg.artfctdef.zvalue.absdiff       = 'yes';
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0.1;
cfg.artfctdef.zvalue.artpadding    = 0.1;
cfg.artfctdef.zvalue.interactive   = 'yes';
cfg.artfctdef.type                 = 'zvalue';
cfg.artfctdef.reject               = 'partial';

cfg    = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfgout = ft_artifact_zvalue(cfg);
