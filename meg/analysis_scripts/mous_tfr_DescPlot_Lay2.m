% % THIS FUNCTION PRODUCES A DESCRIPTIVE PLOT ON ERF DATA TO DETERMINE
% % WHETHER THE PRE-DEFINED SENSOR-GROUPS (lay2) ARE DIFFERENT
% BETWEEN TWO CONDITIONS (sentence vs. sequences)

% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% (A) get the individual data for long time window

% baseline correction config
cfg = [];
cfg.baseline = [-0.25 -0.15];
cfg.baselinetype = 'relchange';

basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);
for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_Hann4under30_05-3ds-pg']);  % load data
  % for single condition plots
  freqHann1{k} = TFRHann_SenTar_PG;   
  freqHann2{k} = TFRHann_SeqTar_PG; 
  freqMult1{k} = TFRMult_SenTar_PG;   
  freqMult2{k} = TFRMult_SeqTar_PG; 
  % baseline correction
  freqHann1_b{k} = ft_freqbaseline(cfg, freqHann1{k});
  freqHann2_b{k} = ft_freqbaseline(cfg,freqHann2{k});
  freqMult1_b{k} = ft_freqbaseline(cfg, freqMult1{k});
  freqMult2_b{k} = ft_freqbaseline(cfg,freqMult2{k});
  
  % for difference plots
  freqDiffHann{k} = TFRHann_Diff_PG;
  freqDiffMult{k} = TFRMult_Diff_PG;
end

%% B:  Define clusters

roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLC13','MLC14','MLC21','MLC22','MLC51','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02'};

roi(2).label    = 'Ltemp';
roi(2).channel  = {'MLC15','MLC16','MLC17','MLF56','MLF65','MLF66','MLF67','MLP43','MLP44','MLP45','MLP55','MLP56','MLP57','MLT12','MLT13','MLT14','MLT15','MLT16','MLT22','MLT23','MLT24','MLT25','MLT26','MLT27','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47','MLT51','MLT52','MLT53','MLT54','MLT55','MLT56','MLT57'};

roi(3).label    = 'Lpar';
roi(3).channel  = {'MLC23','MLC24','MLC25','MLC31','MLC32','MLC41','MLC42','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MLP23','MLP33','MLP34','MLP35','MZC03'};

roi(5).label    = 'Rfront';
roi(5).channel  = {'MRC11','MRC12','MRC13','MRC14','MRC21','MRC22','MRC51','MRF11','MRF12','MRF13','MRF14','MRF21','MRF22','MRF23','MRF24','MRF25','MRF31','MRF32','MRF33','MRF34','MRF35','MRF41','MRF42','MRF43','MRF44','MRF45','MRF46','MRF51','MRF52','MRF53','MRF54','MRF55','MRF61','MRF62','MRF63','MRF64','MRT11','MRT21','MRT31','MZF01','MZF03'};

% nonsignificant for MSc
roi(4).label    = 'Locc'; 
roi(4).channel  = {'MLO11','MLO12','MLO13','MLO14','MLO21','MLO22','MLO23','MLO24','MLO31','MLO32','MLO33','MLO34','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP21','MLP31','MLP32','MLP41','MLP42','MLP51','MLP52','MLP53','MLP54','MZO02','MZPO1'};

roi(6).label    = 'Rtemp';
roi(6).channel  = {'MRC15','MRC16','MRC17','MRF56','MRF65','MRF66','MRF67','MRP43','MRP44','MRP45','MRP55','MRP56','MRP57','MRT12','MRT13','MRT14','MRT15','MRT16','MRT22','MRT23','MRT24','MRT25','MRT26','MRT27','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47','MRT51','MRT52','MRT53','MRT54','MRT55','MRT56','MRT57'};

roi(7).label    = 'Rpar';
roi(7).channel  = {'MRC23','MRC24','MRC25','MRC31','MRC32','MRC41','MRC42','MRC52','MRC53','MRC54','MRC55','MRC61','MRC62','MRC63','MRP11','MRP12','MRP22','MRP23','MRP33','MRP34','MRP35','MZC02','MZC04'};

roi(8).label    = 'Rocc';
roi(8).channel  = {'MRO11','MRO12','MRO13','MRO14','MRO21','MRO22','MRO23','MRO24','MRO31','MRO32','MRO33','MRO34','MRO41','MRO42','MRO43','MRO44','MRO51','MRO52','MRO53','MRP21','MRP31','MRP32','MRP41','MRP42','MRP51','MRP52','MRP53','MRP54','MZO01','MZO03'};

%% C: average across subjects (and channels) without stats

% SINGLE CONDITION
    % <30Hz
    tmp1 = ft_selectdata(freqHann1_b{:},'param','powspctrm');       % select data
    AvgSenTarH = ft_selectdata(tmp1,'avgoverrpt','yes','toilim',[-0.2 1]); % select specific time interval of interest

    tmp2 = ft_selectdata(freqHann2_b{:},'param','powspctrm');
    AvgSeqTarH = ft_selectdata(tmp2,'avgoverrpt','yes','toilim',[-0.2 1]);

    % > 30Hz
    tmp1 = ft_selectdata(freqMult1_b{:},'param','powspctrm');       % select data
    AvgSenTarM = ft_selectdata(tmp1,'avgoverrpt','yes','toilim',[-0.2 1]); % select specific time interval of interest

    tmp2 = ft_selectdata(freqMult2_b{:},'param','powspctrm');
    AvgSeqTarM = ft_selectdata(tmp2,'avgoverrpt','yes','toilim',[-0.2 1]);

% DIFFERENCE
    % <30Hz
    tmp3 = ft_selectdata(freqDiffHann{:},'param','powspctrm','avgoverrpt','yes','toilim',[-0.2 1]);  
    for k = 1:numel(roi)
        AvgDiffHann{k} = ft_selectdata(tmp3,'avgoverchan','yes','channel',roi(k).channel);               
    end 

    % >30Hz
    tmp4 = ft_selectdata(freqDiffMult{:},'param','powspctrm');
    AvgDiffMult = ft_selectdata(tmp4,'avgoverrpt','yes','toilim',[-0.2 1]);
        
%% (C - optional) define clusters and plot TFR

cd /home/language/nielam/INTERNSHIP_FIGURES/
print = [1 2 3 5];

%% single condition plot
for k = print(1:end)
    cfg             = [];
    cfg.parameter   = 'powspctrm';
    cfg.channel     = roi(k).channel;
    cfg.zlim        = [-0.2 0.2];
    cfg.ylim        = [4 30];
    cfg.colorbar    = 'no';
    figure; ft_singleplotTFR(cfg,AvgSenTarH);
    %title(strcat(roi(k).label,' Sent'));
    set(gca,'YTick',[5 10 15 20 25 30]);
    set(gca,'XTick',[0 0.25 0.50 0.75 1]);
    saveas(gca,strcat('TFR',roi(k).label,'Sent','.eps'),'epsc');
    figure; ft_singleplotTFR(cfg,AvgSeqTarH);
    %title(strcat(roi(k).label,' Seq'));
    set(gca,'YTick',[5 10 15 20 25 30]);
    set(gca,'XTick',[0 0.25 0.50 0.75 1]);
    saveas(gca,strcat('TFR',roi(k).label,'Seq','.eps'),'epsc');
end 

%% Difference plots 
% TFR plot
%  With a mask in order to focus on significant areas
for k = print(1:end)
    cfg               = [];   
    %cfg.channel      = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    cfg.parameter     = 'powspctrm';
    cfg.zlim         = [-0.2 0.2];
    cfg.ylim        = [4 30];
    cfg.colorbar    = 'no';
    cfg.maskstyle     = 'opacity';
    cfg.maskparameter = 'mask';                                   % field in the data (AvgDiffHann) where mask is stored                   
    AvgDiffHann{k}.mask = double(statroi1.prob(k,:,:) < 0.025);   % determines the data used for masking; %use double() otherwise assignment remains as boolean and values are difficult to manipulate      
    AvgDiffHann{k}.mask(AvgDiffHann{k}.mask == 0)=0.5;            % take the probability values that were 0 and make them 0.5
    figure; ft_singleplotTFR(cfg,AvgDiffHann{k});   
    set(gca,'YTick',[5 10 15 20 25 30]);
    set(gca,'XTick',[0 0.25 0.50 0.75 1]);
    saveas(gca,strcat('TFR',roi(k).label,'DiffStatplot','.eps'),'epsc');
    %title(roi(k).label) 
end

% topoplot  

cfg             = [];   
cfg.layout      = 'CTF275.lay';
cfg.highlightchannel = roi(k).channel;    % change accordingly 
cfg.highlight = 'on';
cfg.parameter   = 'powspctrm';
cfg.zlim        = [-.2 .2];
cfg.ylim        = [10 20];
cfg.xlim        = [0 1];               % change according to significant duration in roi(k).channel
figure; ft_topoplotTFR(cfg,tmp3)                                                                       % how to implement this plotting command
title(roi(k).label) 


%% topoplot

cfg             = [];
cfg.fontsize    = 2; 
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'powspctrm';
cfg.zlim        = [-0.03 0.03];
cfg.xlim        = [-0.25:0.25:1];
%cfg.colorbar    = 'SouthOutside';
cfg.contournum  = 0;                % turn off coutour lines
cfg.marker      = 'off';            % turn off individual sensor markers
cfg.comment     = 'no';           % maybe after i know each time frame / save 2 versions: one with time
figure; ft_topoplotTFR(cfg, AvgSenTarM); title('higherFreq Sen');
figure; ft_topoplotTFR(cfg, AvgSeqTarM); title('higherFreq Seq');
%cfg.ylim        = [4 7];
%cfg.ylim        = [8 12];
%cfg.ylim       = [13 30];
figure; ft_topoplotTFR(cfg, AvgSenTarH); title('lowerFreq Sen');
figure; ft_topoplotTFR(cfg, AvgSeqTarH); title('lowerFreq Seq');


cd /home/language/nielam/INTERNSHIP_FIGURES/
saveas(gca,strcat('TFR_',enterName.label,'.eps'),'epsc');

%% plot overlapping time windows:
start = (-0.25:0.25:1);
stop  = (0:0.25:1.25);

% configuration
cfg             = [];
cfg.fontsize    = 5; 
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'powspctrm';
cfg.zlim        = [-0.15 0.15];

for k = 1:5 %numel(start)
    cfg.xlim = [start(k) stop(k)];
    figure;ft_topoplotTFR(cfg, AvgSenTarH);
end
   
for k = 1:5 %1:numel(start)
    cfg.xlim = [start(k) stop(k)];
    figure;ft_topoplotER(cfg, AvgSeqTarH);
end

%% movieplot
cfg = [];
cfg.fontsize    = 3; 
cfg.interactive = 'yes';
cfg.layout      = 'CTF275.lay';
cfg.parameter   = 'powspctrm';

figure;ft_movieplotTFR(cfg, AvgSenTarH);
figure;ft_movieplotTFR(cfg, AvgSeqTarH);
figure;ft_movieplotTFR(cfg, AvgSenTarM);
figure;ft_movieplotTFR(cfg, AvgSeqTarM);

%% Multiplot - all 275 sensors:
cfg = [];
cfg.showlabels = 'no'; 
cfg.fontsize = 6; 
cfg.interactive = 'yes';
cfg.layout = 'CTF275.lay';
figure; ft_multiplotTFR(cfg,AvgSenTarH);
figure; ft_multiplotTFR(cfg,AvgSeqTarH);

