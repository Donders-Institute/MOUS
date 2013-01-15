% $Id: mous_artifact_eog.m 44 2012-05-16 10:42:21Z jansch $

% vEOG
cfg                          = [];
cfg.trl                      = trl;
cfg.continuous               = 'yes';
cfg.dataset                  = filename;
cfg.artfctdef.zvalue.channel    = {'EEG058'};
cfg.artfctdef.zvalue.boxcar     = 0.2;
cfg.artfctdef.zvalue.hilbert    = 'no';
cfg.artfctdef.zvalue.bpfilter   = 'yes';
cfg.artfctdef.zvalue.bpfreq     = [1 10];
cfg.artfctdef.zvalue.bpfiltord  = 2;
cfg.artfctdef.zvalue.rectify    = 'yes';
cfg.artfctdef.zvalue.cutoff     = 4;
cfg.artfctdef.zvalue.fltpadding = 0;
cfg.artfctdef.zvalue.trlpadding = 0.1;
cfg.artfctdef.zvalue.artpadding = 0.1;
cfg.artfctdef.zvalue.interactive= 'yes';
cfg.artfctdef.type           = 'zvalue';
cfg.artfctdef.reject         = 'partial';

cfg    = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfgout = ft_artifact_zvalue(cfg);

% hEOG
cfg                          = [];
cfg.trl                      = trl;
cfg.continuous               = 'yes';
cfg.dataset                  = filename;
cfg    = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfg.artfctdef.zvalue.channel    = {'EEG057'};
cfg.artfctdef.zvalue.cutoff     = 4;
cfg.artfctdef.zvalue.fltpadding = 0;
cfg.artfctdef.zvalue.trlpadding = 0.1;
cfg.artfctdef.zvalue.artpadding = 0.1;
cfg.artfctdef.zvalue.interactive= 'yes';
cfg.artfctdef.zvalue.custom.funhandle = @mous_preproc_saccades;
cfg.artfctdef.zvalue.custom.varargin = [];
% cfg.artfctdef.zvalue.channel    = {'EEG057'};
% cfg.artfctdef.zvalue.medianfilter  = 'yes';
% cfg.artfctdef.zvalue.medianfiltord = 301;
% cfg.artfctdef.zvalue.absdiff       = 'yes';
% cfg.artfctdef.zvalue.bpfilter      = 'no';
% cfg.artfctdef.zvalue.demean        = 'yes';
% cfg.artfctdef.zvalue.boxcar        = 0.1;
cfgout2                      = ft_artifact_zvalue(cfg);