% % THIS FUNCTION PRODUCES A DESCRIPTIVE PLOT ON ERF DATA TO DETERMINE
% % WHETHER THE PRE-DEFINED SENSOR-GROUPS (lay2) ARE DIFFERENT
% BETWEEN TWO CONDITIONS (sentence vs. sequences)

% cleanest sub-list    N = 9
% subjlist = {'V1013' 'V1024' 'V1028' 'V1029' 'V1030'...
%             'V1031' 'V1033' 'V1034' 'V1044'};

% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% (A) get the individual data for long time window

% cfg = [];
% cfg.baseline = [-0.25 -0.1];
% cfg.baselinetype = 'relchange';

basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);
for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-pg']);  % load data
%   erfSenTar{k} = senTar_CPG;   
%   erfSeqTar{k} = seqTar_CPG; 
%   
%   % baseline correction
%   erfSenTar{k} = ft_timelockbaseline(cfg, erfSenTar{k});
%   erfSeqTar{k} = ft_timelockbaseline(cfg, erfSeqTar{k});
  
  erfDiff{k} = senTar_CPG;
  erfDiff{k}.avg = (senTar_CPG.avg-seqTar_CPG.avg);
end


%% (B) average across subjects without stats

% long
tmp1 = ft_selectdata(erfSenTar{:},'param','avg');       % select data
tmp1.trial = tmp1.avg; tmp1 = rmfield(tmp1,'avg');      % switch .avg into .trial for ft_selectdata to work
AvgSenTar_L = ft_selectdata(tmp1,'avgoverrpt','yes','toilim',[-0.5 1.0]); % select specific time interval of interest

tmp2 = ft_selectdata(erfSeqTar{:},'param','avg');
tmp2.trial = tmp2.avg; tmp2 = rmfield(tmp2,'avg');
AvgSeqTar_L = ft_selectdata(tmp2,'avgoverrpt','yes','toilim',[-0.5 1.0]);

tmp3 = ft_selectdata(erfDiff{:},'param','avg');
tmp3.trial = tmp3.avg; tmp3 = rmfield(tmp3,'avg');
AvgErfDiff = ft_selectdata(tmp3,'avgoverrpt','yes','toilim',[-0.5 1.0]);


        %% (C - optional) time-locked data for single subject 

        tlck_SenTar = erfSenTar{9};   % no need to squeeze out the 'rpt' dimension because there's only 1 rpt present
        tlck_SeqTar = erfSeqTar{9};

        tlck_SenTar = erfSenTar{17};   % no need to squeeze out the 'rpt' dimension because there's only 1 rpt present
        tlck_SeqTar = erfSeqTar{17};% 
        
%% (D - optional) define clusters and plot
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

% graph config, set directory for saving
cfg = [];   
cfg.parameter   = 'trial';
cfg.xlim        = [-0.2 1.0];
cfg.ylim        = [-1e-14 6.5e-14];
cd /home/language/nielam/INTERNSHIP_FIGURES/

% loop for plotting 
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    figure; ft_singleplotER(cfg,AvgSenTar_M,AvgSeqTar_M);
    hold on
    line([-0.2 1],[0 0], 'Color','k','LineWidth',1);   % plot line at x=0, y=full length of y axis
    line([0 0],[-1e-14 6.5e-14], 'Color','k','LineWidth',1);
    set(gca,'YTick',[0 6e-14]);
    set(gca,'XTick',[0 0.25 0.5 1]);
    title(roi(k).label);
    saveas(gca,strcat('ERF_',roi(k).label,'.eps'),'epsc');
end

%% Can do a multiplot - all 275 sensors:
cfg = [];
cfg.showlabels  = 'yes'; 
cfg.fontsize    = 2; 
%cfg.interactive = 'yes';
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'trial';
%cfg.channel     = 'all';
%cfg.ylim = [-2e-1 2e-7];
figure; ft_multiplotER(cfg, AvgSenTar_L);  % -0.5 to 1.0s
figure; ft_singleplotER(cfg, AvgSenTar_L);

%% movieplot

cfg = [];
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF275.lay';
cfg.parameter   = 'trial';
cfg.ylim = [-2e-1 2e-7];
figure;ft_movieplotER(cfg, AvgSenTar_L);
figure;ft_movieplotER(cfg, AvgSeqTar_L);

%% topoplot

cfg = [];
cfg.fontsize    = 2;
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'trial';
cfg.zlim        = [-9e-15 9e-15];
cfg.xlim        = [0.25 0.5];        % one interval 
cfg.highlight          = 'on';                 
cfg.highlightchannel   = roi(3).channel;
figure;ft_topoplotER(cfg, AvgErfDiff);

%% overlapping intervals
start = (0:0.25:1);
stop  = (0.2:0.25:1.25);

% configuration
cfg             = [];
cfg.fontsize    = 2; 
cfg.interactive = 'yes';
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'trial';
cfg.zlim        = [-6.5e-14 6.5e-14];   % make green = no change

for k = 1:numel(start)
    cfg.xlim        = [start(k) stop(k)];
    cfg.zlim        = [-6e-14 6e-14];
    figure;ft_topoplotER(cfg, AvgSenTar_M);
    %saveas(fprintf('SenTar %d-%d'start(k) stop(k)),figure(k),'-eps');
end