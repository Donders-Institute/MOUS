% % This function performs group-level statistics for defined sensor clusters
% % JM, NL 11.6.2012
% freq/stat1 = Hanning tapers, <30Hz;  freq/stat2 = multitapers,    >30Hz

% full list
%subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         %'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         % 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};

% acceptable sub-list  N = 17
subjlist = {'V1012' 'V1013' 'V1015' 'V1016' 'V1024'...
            'V1025' 'V1026' 'V1027' 'V1028' 'V1029'... 
            'V1030' 'V1031' 'V1033' 'V1034' 'V1036' 'V1037' 'V1044'};
 
% cleanest sub-list    N = 9
subjlist = {'V1013' 'V1024' 'V1028' 'V1029' 'V1030'...
            'V1031' 'V1033' 'V1034' 'V1044'};

%%  get the individual data for long time window
basedir = '/home/language/annhul/MOUS/Processed/';
for k = 1:numel(subjlist)
  %tmp = mous_db_getdata(subjlist{k}, 'meg_processed_...');
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF05-3ds-pg']);  % load data
  erfSenTar{k} = senTar_CPG;   %  assign the relevant conditions (CPG) to structure: same condition from each subject; one condition per array.           
  erfSeqTar{k} = seqTar_CPG;   
end

%% plot average for each ROI (without stats)

tmp1 = ft_selectdata(erfSenTar{:},'param','avg');  % 3D data
tmp2 = ft_selectdata(erfSeqTar{:},'param','avg');
%tmp1 = ft_selectdata(tmp1,'avgoverrpt','yes');

tlck_SenTar = tmp1;                                % 2D data
tlck_SenTar.dimord = 'chan_time';
tlck_SenTar.avg = squeeze(mean(tmp1.avg));

tlck_SeqTar = tmp2;
tlck_SeqTar.dimord = 'chan_time';
tlck_SeqTar.avg = squeeze(mean(tmp2.avg));

% cfg = [];
% cfg.parameter = 'avg';
% figure; ft_multiplotER(cfg,tlck_SenTar,tlck_SeqTar);

% define clusters
roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLC13','MLC14','MLC21','MLC22','MLC51','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02'};

roi(2).label    = 'Ltemp';
roi(2).channel  = {'MLC15','MLC16','MLC17','MLF56','MLF65','MLF66','MLF67','MLP43','MLP44','MLP45','MLP55','MLP56','MLP57','MLT12','MLT13','MLT14','MLT15','MLT16','MLT22','MLT23','MLT24','MLT25','MLT26','MLT27','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47','MLT51','MLT52','MLT53','MLT54','MLT55','MLT56','MLT57'};

roi(3).label    = 'Lpar';
roi(3).channel  = {'MLC23','MLC24','MLC25','MLC31','MLC32','MLC41','MLC42','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MLP23','MLP33''','MLP34','MLP35','MZC03'};

roi(4).label    = 'Locc'; 
roi(4).channel  = {'MLO11','MLO12','MLO13','MLO14','MLO21','MLO22','MLO23','MLO24','MLO31','MLO32','MLO33','MLO34','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP21','MLP31','MLP32','MLP41','MLP42','MLP51''','MLP52','MLP53','MLP54','MZO02','MZPO1'};

roi(5).label    = 'Rfront';
roi(5).channel  = {'MRC11','MRC12','MRC13','MRC14','MRC21','MRC22','MRC51','MRF11','MRF12','MRF13','MRF14','MRF21','MRF22','MRF23','MRF24','MRF25','MRF31','MRF32','MRF33','MRF34','MRF35','MRF41','MRF42','MRF43','MRF44','MRF45','MRF46','MRF51','MRF52','MRF53','MRF54','MRF55','MRF61','MRF62','MRF63','MRF64','MRT11','MRT21','MRT31','MZF01','MZF03'};

roi(6).label    = 'Rtemp';
roi(6).channel  = {'MRC15','MRC16','MRC17','MRF56','MRF65','MRF66','MRF67','MRP43','MRP44','MRP45','MRP55','MRP56','MRP57','MRT12','MRT13','MRT14','MRT15','MRT16','MRT22','MRT23','MRT24','MRT25','MRT26','MRT27','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47','MRT51','MRT52','MRT53','MRT54','MRT55','MRT56','MRT57'};

roi(7).label    = 'Rpar';
roi(7).channel  = {'MRC23','MRC24','MRC25','MRC31','MRC32','MRC41','MRC42','MRC52','MRC53','MRC54','MRC55','MRC61','MRC62','MRC63','MRP11','MRP12','MRP22','MRP23','MRP33','MRP34','MRP35','MZC02','MZC04'};

roi(8).label    = 'Rocc';
roi(8).channel  = {'MRO11','MRO12','MRO13','MRO14','MRO21','MRO22','MRO23','MRO24','MRO31','MRO32','MRO33','MRO34','MRO41','MRO42','MRO43','MRO44','MRO51','MRO52','MRO53','MRP21','MRP31','MRP32','MRP41','MRP42','MRP51','MRP52','MRP53','MRP54','MZO01','MZO03'};

% loop for plotting 
for k = 1:numel(roi)
    cfg = [];   
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    cfg.parameter = 'avg';
    %cfg.interactive = 'yes';
    figure; 
    ft_singleplotER(cfg,tlck_SenTar,tlck_SeqTar);
    axis ([-0.5 3.0 -1*1.0000e-14 9*1.0000e-14]);
    %axis ([1.1 1.4 -1*1.0000e-14 9*1.0000e-14]);
    title(roi(k).label);
    hold on; 
    line([300 300],[0 max(erfSenTar_Clust{3}.avg)])
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
cfg.numrandomization = 1000;       % number of swaps 
cfg.parameter        = 'trial';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
cfg.neighbours       = {};  

subj = numel(subjlist);
design = zeros(2,2*subj);
for i = 1:subj
  design(1,i) = i;
end
for i = 1:subj
  design(1,subj+i) = i;
end
design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;

cfg.design   = design;
cfg.uvar     = 1;
cfg.ivar     = 2;

% create loop to perform ft_timelockstatistics for each ROI.

% sensor clusters updated to layout #2 



%% cluster permutation statistics for whole head, all frequencies
%  involves creating a design matrix that has 2 rows:
%  row1 = condition (Hann vs. Mult); row2 = which subject's data
%  1 1 1 1 1 2 2 2 2 2
%  1 2 3 4 5 1 2 3 4 5

% currently this script doesn't identify any channels, and the iv/uv needs to be fixed   11.6.2012 NL

cfg = [];
cfg.channel             = {'MEG'};
%cfg.avgoverchan         = 'yes';
cfg.method              = 'montecarlo';
cfg.statistic           = 'depsamplesT';
cfg.tail                = 0;
cfg.alpha               = 0.025;
%cfg.numrandomization    = 1000;  % use value of 0 if just want to get an idea of data
cfg.parameter           = 'avg';
%cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.numrandomization = 500;
% specifies with which sensors other sensors can form clusters
cfg_neighb.method    = 'distance';
%cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, erfSenTar);

subj = numel(subjlist);
design = zeros(2,2*subj);
for i = 1:subj
  design(1,i) = i;
end
for i = 1:subj
  design(1,subj+i) = i;
end
design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;

cfg.design   = design;
cfg.uvar     = 1;
cfg.ivar     = 2;

stat_erf               = ft_timelockstatistics(cfg, erfSenTar{:}, erfSeqTar{:});  % statistics on entire array (instead of doing ft_timelockgrandaverage separately)

%% plot - for all channels

% plotting conditions as separate lines
tmp1 = ft_selectdata(erfSenTar{:},'param','avg');
tmp2 = ft_selectdata(erfSeqTar{:},'param','avg');

% Difference wave
ERF_Diff = stat_erf;
% ERF_Diff = stat1_erf.trial - stat2_erf.trial;   % sentences - sequences
% 
% figure;
% timestep        = 0.05;                  % seconds
% sampling_rate   = stat_erf.fsample;
% sample_count    = length(stat.time);
% j               = [0:timestep:1];       % temporal endpoints of ERP avg for each subplot
% m               = [1:timestep*sampling_rate:sample_count]; % temporal endpoint in MEG sample
% 
% pos_cluster_pvals = [stat.poscluster(:).prob];
% pos_signif_clust  = find(pos_cluster_pvals < stat.cfg.alpha);
% pos               = ismember(stat.posclusterslabmat, pos_signif_clust);
% 
% for k = 1:20;
%      subplot(4,5,k);   
cfg = [];   
cfg.layout='CTF275.lay';
%      cfg.xlim=[j(k) j(k+1)];   
%      cfg.zlim = [-1.0e-13 1.0e-13];   % comment out?
%      pos_int = all(pos(:, m(k):m(k+1)), 2);
%      cfg.highlight = 'on';
%      cfg.highlightchannel = find(pos_int);       
     %cfg.comment = 'xlim';   
cfg.parameter = 'stat';
cfg.interactive = 'yes';
    % cfg.commentpos = 'Sent vs. Seq ERF';   
ft_multiplotER(cfg, ERF_Diff);
%end


%%--------------------------------------------------------------------------------------------

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
cfg.numrandomization = 1000;       % number of swaps 
cfg.parameter        = 'trial';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
cfg.neighbours       = {};  
cfg.design   = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar     = 2;
cfg.ivar     = 1;


% sensor clusters updated to layout #2 on 8.6.2012
% Plotting for multiple statistical tests - loop

% define clusters
roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLC13','MLC14','MLC21','MLC22','MLC51','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02'};

roi(2).label    = 'Ltemp';
roi(2).channel  = {'MLC15','MLC16','MLC17','MLF56','MLF65','MLF66','MLF67','MLP43','MLP44','MLP45','MLP55','MLP56','MLP57','MLT12','MLT13','MLT14','MLT15','MLT16','MLT22','MLT23','MLT24','MLT25','MLT26','MLT27','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47','MLT51','MLT52','MLT53','MLT54','MLT55','MLT56','MLT57'};

roi(3).label    = 'Lpar';
roi(3).channel  = {'MLC23','MLC24','MLC25','MLC31','MLC32','MLC41','MLC42','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MLP23','MLP33''','MLP34','MLP35','MZC03'};

roi(4).label    = 'Locc'; 
roi(4).channel  = {'MLO11','MLO12','MLO13','MLO14','MLO21','MLO22','MLO23','MLO24','MLO31','MLO32','MLO33','MLO34','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP21','MLP31','MLP32','MLP41','MLP42','MLP51''','MLP52','MLP53','MLP54','MZO02','MZPO1'};

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
    statroi1(k) = ft_timelockstatistics(cfg, erfSenTar{:}); % sentences
    statroi2(k) = ft_timelockstatistics(cfg, erfSeqTar{:}); % sequenecs
    statroi1(k).label = roi(k).label;
    statroi2(k).label = roi(k).label;
end

