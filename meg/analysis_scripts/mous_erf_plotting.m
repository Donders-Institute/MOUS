
% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

clear all
%% SHORT


inputdata = 'meg_processed_{_erf_visual_word_all_02-1ds20130206-pg}';

data = mous_db_getdata('V1048', inputdata);

sen_CPG = data{1};
seq_CPG = data{3};

inputdata = 'meg_processed_{_erf_visual_word_all_02-1ds20130206-ag}';
data = mous_db_getdata('V1040', inputdata);
sen_AG = data{1};
seq_AG = data{2};

cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF273.lay';
%cfg.ylim = [-2e-13 2e-13];
figure(1); ft_multiplotER(cfg,sen_AG, seq_AG);
figure(2); ft_multiplotER(cfg,sen_CPG, seq_CPG);

figure(3);ft_movieplotER(cfg, sen_AG);
figure(4);ft_movieplotER(cfg, seq_AG);


%% LONG

ag = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF_targetword_05-3ds-ag.mat', subject, subject);
pg = sprintf('/home/language/annhul/MOUS/Processed/%s/ERF/%sERF_targetword_05-3ds-pg.mat', subject, subject);

load(ag) 
load(pg) 

cfg = [];
cfg.showlabels = 'yes'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF273.lay';
%cfg.ylim = [-2e-13 2e-13];
figure(1); ft_multiplotER(cfg,senTar_AG, seqTar_AG);
figure(2); ft_multiplotER(cfg,senTar_CPG, seqTar_CPG);

figure(3);ft_movieplotER(cfg, senTar_AG);
figure(4);ft_movieplotER(cfg, seqTar_AG);

cfg = [];
cfg.channel = 'MRT23';
cfg.ylim = [-5e-14 16e-14];

figure(3); ft_singleplotER(cfg, senWord_AG);
figure(4); ft_singleplotER(cfg, senWord_CPG);
cfg.channel = 'MLT25_dH';
figure(5); ft_singleplotER(cfg, senWord_PG);

