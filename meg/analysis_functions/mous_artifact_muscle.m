function [cfgmuscle] = mous_artifact_muscle(filename, trl, ntrial)

% $Id: mous_artifact_muscle.m 44 2012-05-16 10:42:21Z jansch $

% muscle artifacts
cfg                          = [];
cfg.trl                      = trl;
cfg.continuous               = 'yes';
cfg.dataset                  = filename;
cfg.memory                   = 'low';
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
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.interactive= 'yes';
cfg.artfctdef.type           = 'zvalue';
cfg.artfctdef.reject         = 'partial';

if nargin>2 && ntrial>0
  cfg.artfctdef.zvalue.method  = 'trial';
  cfg.artfctdef.zvalue.ntrial  = ntrial;
end
cfg       = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfgmuscle = ft_artifact_zvalue(cfg);
