
%% Plot TFR
% multiplot
cfg = [];
cfg.interactive  = 'yes';
cfg.channel      = 'all';   % 'all' is the default.
cfg.showlabels   = 'yes';	
cfg.layout       = 'CTF275.lay';
cfg.ylim         = [5 30];
%  cfg.zlim         = 'maxabs';

% LESS 30Hz 
figure; ft_multiplotTFR(cfg, TFRHann_Diff_PG);     
title('<30 TFRHann_Diff_PG');

figure; ft_multiplotTFR(cfg, TFRMult_Diff_PG);   
title('>30 TFRMult_Diff_PG');

%% Plot ERFs

cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF275.lay';
figure; ft_multiplotER(cfg,SentTar, SeqTar);

% %ft_multiplotER(cfg,RCsent, MCsent, RCseq, MCseq);

%% single channel plot: ERF / TFR

cfg.channel = 'MLT37';
figure; ft_topoplotER(cfg, TFRHann_Diff_PG);

%% sensor clusters (channels)

%% Layout 2

% define clusters
roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLC13','MLC14','MLC21','MLC22','MLC51','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02'};

roi(2).label    = 'Ltemp';
roi(2).channel  = {'MLC15','MLC16','MLC17','MLF56','MLF65','MLF66','MLF67','MLP43','MLP44','MLP45','MLP55','MLP56','MLP57','MLT12','MLT13','MLT14','MLT15','MLT16','MLT22','MLT23','MLT24','MLT25','MLT26','MLT27','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47','MLT51','MLT52','MLT53','MLT54','MLT55','MLT56','MLT57'};

roi(3).label    = 'Lpar';
roi(3).channel  = {'MLC23','MLC24','MLC25','MLC31','MLC32','MLC41','MLC42','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MLP23','MLP33','MLP34','MLP35','MZC03'};

roi(4).label    = 'Locc'; 
roi(4).channel  = {'MLO11','MLO12','MLO13','MLO14','MLO21','MLO22','MLO23','MLO24','MLO31','MLO32','MLO33','MLO34','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP21','MLP31','MLP32','MLP41','MLP42','MLP51','MLP52','MLP53','MLP54','MZO02','MZPO1'};

roi(5).label    = 'Rfront';
roi(5).channel  = {'MRC11','MRC12','MRC13','MRC14','MRC21','MRC22','MRC51','MRF11','MRF12','MRF13','MRF14','MRF21','MRF22','MRF23','MRF24','MRF25','MRF31','MRF32','MRF33','MRF34','MRF35','MRF41','MRF42','MRF43','MRF44','MRF45','MRF46','MRF51','MRF52','MRF53','MRF54','MRF55','MRF61','MRF62','MRF63','MRF64','MRT11','MRT21','MRT31','MZF01','MZF03'};

roi(6).label    = 'Rtemp';
roi(6).channel  = {'MRC15','MRC16','MRC17','MRF56','MRF65','MRF66','MRF67','MRP43','MRP44','MRP45','MRP55','MRP56','MRP57','MRT12','MRT13','MRT14','MRT15','MRT16','MRT22','MRT23','MRT24','MRT25','MRT26','MRT27','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47','MRT51','MRT52','MRT53','MRT54','MRT55','MRT56','MRT57'};

roi(7).label    = 'Rpar';
roi(7).channel  = {'MRC23','MRC24','MRC25','MRC31','MRC32','MRC41','MRC42','MRC52','MRC53','MRC54','MRC55','MRC61','MRC62','MRC63','MRP11','MRP12','MRP22','MRP23','MRP33','MRP34','MRP35','MZC02','MZC04'};

roi(8).label    = 'Rocc';
roi(8).channel  = {'MRO11','MRO12','MRO13','MRO14','MRO21','MRO22','MRO23','MRO24','MRO31','MRO32','MRO33','MRO34','MRO41','MRO42','MRO43','MRO44','MRO51','MRO52','MRO53','MRP21','MRP31','MRP32','MRP41','MRP42','MRP51','MRP52','MRP53','MRP54','MZO01','MZO03'};



%% Layout 3

% No left right division for Occipital and central sensor-groups

roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02','MLC13','MLC14'};

roi(2).label    = 'LTemp';
roi(2).channel  = {'MLF56','MLF65','MLF66','MLF67','MLT12','MLT13','MLT14','MLT22','MLT23','MLT24','MLT25','MLT26','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47'};

roi(3).label    = 'LmidTemp'; 
roi(3).channel  = {'MLC15','MLC16','MLC17','MLC22','MLC23','MLC24','MLC25','MLC31','MLC32','MLO13','MLO14','MLO24','MLO34','MLP23','MLP33','MLP34','MLP35','MLP42','MLP43','MLP44','MLP45','MLP53','MLP54','MLP55','MLP56','MLP57','MLT15','MLT16','MLT27','MLC42'};

roi(4).label    = 'Rfront';
roi(4).channel  = {'MRC11','MRC12','MRF11','MRF12','MRF13','MRF14','MRF21','MRF22','MRF23','MRF24','MRF25','MRF31','MRF32','MRF33','MRF34','MRF35','MRF41','MRF42','MRF43','MRF44','MRF45','MRF46','MRF51','MRF52','MRF53','MRF54','MRF55','MRF61','MRF62','MRF63','MRF64','MRT11','MRT21','MRT31','MZF01','MZF03','MRC13','MRC14'};

roi(5).label    = 'Rtemp';
roi(5).channel  = {'MRF56','MRF65','MRF66','MRF67','MRT12','MRT13','MRT14','MRT22','MRT23','MRT24','MRT25','MRT26','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47'};

roi(6).label    = 'RmidTemp';
roi(6).channel  = {'MRC15','MRC16','MRC17','MRC22','MRC23','MRC24','MRC25','MRC31','MRC32','MRO13','MRO14','MRO24','MRO34','MRP23','MRP33','MRP34','MRP35','MRP42','MRP43','MRP44','MRP45','MRP53','MRP54','MRP55','MRP56','MRP57','MRT15','MRT16','MRT27','MRC42'};

roi(7).label    = 'Cent(LR)';
roi(7).channel  = {'MLP21','MLP31','MLP32','MLP41','MLC21','MLC51','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MZC03','MZPO1','MLC41','MRP21','MRP31','MRP32','MRP41','MRC21','MRC51','MRC52','MRC53','MRC54','MRC55','MRC61','MRC62','MRC63','MRP11','MRP12','MRP22','MZC02','MZC04','MRC41'};

roi(8).label    = 'Occ(LR)';
roi(8).channel  = {'MLO11','MLO12','MLO21','MLO22','MLO23','MLO31','MLO32','MLO33','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP51','MLP52','MZO02','MRO11','MRO12','MRO21','MRO22','MRO23','MRO31','MRO32','MRO33','MRO41','MRO42','MRO43','MRO44','MRO51','MRO52','MRO53','MRP51','MRP52','MZO01','MZO03'};

%% temporal sensor-groups including  channels on the edge
roi(2).label    = 'LTemp';
roi(2).channel  = {'MLF56','MLF65','MLF66','MLF67','MLT12','MLT13','MLT14','MLT22','MLT23','MLT24','MLT25','MLT26','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47','MLT51','MLT52','MLT53','MLT54','MLT55','MLT56','MLT57'};

roi(5).label    = 'Rtemp';
roi(5).channel  = {'MRF56','MRF65','MRF66','MRF67','MRT12','MRT13','MRT14','MRT22','MRT23','MRT24','MRT25','MRT26','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47' 'MRT51','MRT52','MRT53','MRT54','MRT55','MRT56','MRT57'};

