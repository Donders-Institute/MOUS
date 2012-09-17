% % THIS FUNCTION PERFORMS CLUSTER-BASED PERMUTATION TEST ON ERF DATA TO DETERMINE
% % WHETHER THE PRE-DEFINED SENSOR-GROUPS (lay2) ARE SIGNIFICANT IN DIFFERENCE
% BETWEEN TWO CONDITIONS (sentence vs. sequences)
% % JM, NL 11.6.2012

% full list
%subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         %'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         % 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};
       
% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% (A) get the individual data for long time window
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);
for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-pg']);  % load data
  erf{k}       = senTar_CPG;  
  erf{k+nsubj} = seqTar_CPG;                                      
end

%% perform cluster permutation statistics for different head areas, all frequencies

% main configuration
cfg = [];
%cfg.latency          = [0 1.8];   % duration of interests 
%cfg.frequency        = [20 20];   % frequency band of interest
cfg.avgoverchan      = 'yes';
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';  %  OR 'diff'
cfg.correctm         = 'cluster';  % do bonferroni at next stage, for doing ft_freqstatistics x16.
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';   % how single samples belonging to a cluster are combined.
%cfg.minnbchan        = 2;
cfg.tail             = 0;
%cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 2000;       % number of swaps 
cfg.parameter        = 'trial';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
cfg.neighbours       = {};  
cfg.design   = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar     = 2;
cfg.ivar     = 1;


%% sensor groups for layout #2 on 8.6.2012
% Plotting for multiple statistical tests - loop

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

% create cfg for freqstatistics 
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    statroi1(k) = ft_timelockstatistics(cfg, erf{:}); % 
    statroi1(k).label = roi(k).label;
end

%% plot
for k = 1:numel(roi)   %% singleplotER doesn't work!
    cfg = [];
    cfg.showlabels = 'no'; 
    cfg.fontsize = 6; 
    cfg.channel = roi(k).channel;
    cfg.layout = 'CTF275.lay';
    cfg.zlim   = 'maxabs';
    figure; ft_singleplotER(cfg,statroi1(k).stat); %(1:nsubj),statroi1(nsubj+(1:nsubj)));
end

for k = 1:numel(roi)
    figure; plot(statroi1(k).time(61:511),statroi1(k).stat(61:511));
    %title (statroi1(k).label)
end 

for k = 1:numel(roi)
    figure; plot(statroi1(k).time(61:511),statroi1(k).prob(61:511));
    %title (statroi1(k).label)
end 

%%

% LEFT HEMISPHERE --------------------------------------------------------
% probabilities
for k = 1:4
    figure; plot(statroi1(k).time(61:511),statroi1(k).prob(61:511));
    %title (statroi1(k).label)
end 

% statistics
for k = 1:4
    figure; plot(statroi1(k).time(61:511),statroi1(k).stat(61:511));
    %title (statroi1(k).label)
end 
        
% RIGHT HEMISPHERE --------------------------------------------------------
% probabilities
for k = 5:8
    figure; plot(statroi1(k).time(61:511),statroi1(k).prob(61:511));
    %title (statroi1(k).label)
end 

% statistics
for k = 5:8
    figure; plot(statroi1(k).time(61:511),statroi1(k).stat(61:511));
    %title (statroi1(k).label)
end 
        