
% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

clear all
%% SHORT


ag = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF02-1ds-ag.mat', subject, subject);
pg = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF02-1ds-pg.mat', subject, subject);

load(ag) 
load(pg) 

cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF273.lay';
%cfg.ylim = [-2e-13 2e-13];
figure(1); ft_multiplotER(cfg,senTar_AG, seqTar_AG);
figure(2); ft_multiplotER(cfg,senTar_CPG, seqTar_CPG);

figure(3);ft_movieplotER(cfg, senTar_AG);
figure(4);ft_movieplotER(cfg, seqTar_AG);


%% LONG

ag = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF_targetword_05-3ds-ag.mat', subject, subject);
pg = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF_targetword_05-3ds-pg.mat', subject, subject);

load(ag) 
load(pg) 

cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF273.lay';
%cfg.ylim = [-2e-13 2e-13];
figure(1); ft_multiplotER(cfg,senTar_AG, seqTar_AG);
figure(2); ft_multiplotER(cfg,senTar_CPG, seqTar_CPG);

figure(3);ft_movieplotER(cfg, senTar_AG);
figure(4);ft_movieplotER(cfg, seqTar_AG);


