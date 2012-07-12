% % This function performs group-level statistics for defined sensor clusters
% % JM, NL 7.6.2012
% freq/stat1 = Hanning tapers, <30Hz;  freq/stat2 = multitapers,    >30Hz

% full list
%subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         %'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         % 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};

% acceptable sub-list  N = 17
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1026' 'V1027' 'V1028' 'V1029'... 
            'V1030' 'V1031' 'V1033' 'V1034' 'V1036' 'V1037' 'V1044'};
 
% cleanest sub-list    N = 9
subjlist = {'V1013' 'V1024' 'V1028' 'V1029' 'V1030'...
            'V1031' 'V1033' 'V1034' 'V1044'};

%% (A) get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);
for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_05-3ds-pg']);

  %freq1{k} = TFRHann_Diff_PG;   % load data from the same condition from each subject; one condition per array.           
  %freq2{k} = TFRMult_Diff_PG;   
 
  freq1{k} = TFRHann_SenTar_PG;  % load sentences and sequences into 2 columns:      SenTar         SeqTar              % permuting between these 2 conditions
  freq2{k} = TFRMult_SenTar_PG;                                 %                 1 1 1 1 1 1       2 2 2 2 2 2         % cfg.ivar (independent variables)
  freq1{k+nsubj} = TFRHann_SeqTar_PG;                           %                 1 2 3 4 5 6       1 2 3 4 5 6         % cfg.uvar (units of observ.)
  freq2{k+nsubj} = TFRMult_SeqTar_PG;

end

%% (B) create empty powerspectra for permutation in next step - only if reading in data that has relative difference calculated between conditions
%  calculated relative difference between sen and seq: (A/B), so to do
%  for permutation make a second column that is empty, i.e. A/B has no difference

% freq1(nsubj+(1:nsubj)) = freq1;  % add another nsubj number of columns
% freq2(nsubj+(1:nsubj)) = freq2;
% for k = nsubj+(1:nsubj)          % from column 19+1, 19+2 ... i.e. 20 to 38 assign 0 (no difference powspctra)
%   freq1{k}.powspctrm(:) = 0;
%   freq2{k}.powspctrm(:) = 0;
% end

%% (C) Plot the data for both conditions    %note: run part (A) first

% different plots for low and high frequencies 
freqAll_Low     = ft_selectdata(freq1{:},'param','powspctrm','avgoverrpt','yes');  % Below 30Hz
freqAll_High    = ft_selectdata(freq2{:},'param','powspctrm','avgoverrpt','yes');  % Above 30Hz

% perform baseline correction 
cfgb                = [];
cfgb.baseline       = [-0.25 -0.15];  % don't read until zero because at zero time point is start of stimulus, and baseline will thus have have leakage from brain activity where stimulus is present
freqAll_Low_b     = ft_freqbaseline(cfgb, freqAll_Low);
freqAll_High_b    = ft_freqbaseline(cfgb, freqAll_High);

% plot
cfgp                = [];
cfgp.layout         = 'CTF275.lay';
cfgp.interactive    = 'yes';
cfgp.zlim           = 'maxabs';
figure; ft_multiplotTFR(cfgp,freqAll_Low_b);
figure; ft_multiplotTFR(cfgp,freqAll_High_b);


%% (D) plot data for one condition 

% for ivar: the first 17 cells are one condition (sent), and the next 17 cells are the other condition (seq)

selPtp = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17];  % select participants % used to select data of participants from one condition


% select data
    % sentences only
    freqSen_Low     = ft_selectdata(freq1{:},'param','powspctrm');                      % <30Hz
    freqSen_Low     = ft_selectdata(freqSen_Low,'avgoverrpt','yes','rpt',selPtp);  
    freqSen_High    = ft_selectdata(freq2{:},'param','powspctrm');                      % >30Hz
    freqSen_High    = ft_selectdata(freqSen_High,'avgoverrpt','yes','rpt',selPtp); 

    % sequences only
    freqSeq_Low     = ft_selectdata(freq1{:},'param','powspctrm','avgoverrpt','yes');
    freqSen_Low     = ft_selectdata(freqSeq_Low,'avgoverrpt','yes','rpt',selPtp+17);
    freqSeq_High    = ft_selectdata(freq2{:},'param','powspctrm','avgoverrpt','yes');
    freqSen_High    = ft_selectdata(freqSeq_High,'avgoverrpt','yes','rpt',selPtp+17);

% perform baseline correction
cfgb                = [];
cfgb.baseline       = [-0.25 -0.15];
freqSen_Low_b = ft_freqbaseline(cfgb, freqSen_Low); % default = absolute baseline normalization of data
freqSen_High_b = ft_freqbaseline(cfgb, freqSen_High);
freqSeq_Low_b = ft_freqbaseline(cfgb, freqSeq_Low); % default = absolute baseline normalization of data
freqSeq_High_b = ft_freqbaseline(cfgb, freqSeq_High);

% plot (p) dimord: chan_freq_time
cfgp.layout = 'CTF275.lay';
cfgp.interactive = 'yes';
cfgp.zlim = 'maxabs';
figure; ft_multiplotTFR(cfgp,freqSen_Low_b) 
figure; ft_multiplotTFR(cfgp,freqSen_High_b) 
figure; ft_multiplotTFR(cfgp,freqSeq_Low_b) 
figure; ft_multiplotTFR(cfgp,freqSeq_High_b) 


%% (E) choose subset of the participants if necessary. Ideally choose the appropriate subjlist so thatthis part does not need to be implemented
% this code can be used whether plotting for one or more conditions.
% Implemented after the first ft_selectdata is called e.g., ft_selectdata(freq1{:},'param','powspctrm');
    % search for matching strings in 2 lists
    % returns indices of matches present in each list
    [a,b] = match_str(subjlist(:),{'V1013' 'V1024' 'V1028' 'V1029' 'V1030' 'V1031' 'V1033' 'V1034' 'V1044'});
    % redefine freqDesc
    freqDesc=ft_selectdata(freq1{:},'param','powspctrm');
    % rpt = indices of replicates (subjects) to be retained for subsequent analysis
    freqDesc=ft_selectdata(freqDesc,'avgoverrpt','yes','rpt',a); %define over which rpt to average, here it is 9 of the 17

% combining baselined data from both conditions if necessary 
    freqb_allcdtn = freqb_Sen;
    freqb_allCdtn.powspctrm = freqb_Sen.powpsctrm+freqb_Seq.powspctrm; % this is the quick and dirty way
    freqb_allCdtn.powspctrm = mean([freqDescSen.powspctrm freqDescSeq.powspctrm]); % this is not it
    freqb_allCdtn.powspctrm = ft_selectdata();     % what about using ft_selectdata with 'avgoverrpt' 'avgoverfreq' 'avgovertime' all set to 'yes' ?

%% (F) perform cluster permutation statistics for different head areas, all frequencies

% main configuration
cfg = [];
cfg.avgoverchan      = 'yes';
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';  %  OR 'diff'
cfg.correctm         = 'cluster';      %  cfg.correctm = 'no' - do not apply multiple-comparison correction.  % Choose this for determining non-condition specified ROIs
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';   % how single samples belonging to a cluster are combined.
%cfg.minnbchan        = 2;
cfg.tail             = 0;
%cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 1000;       % number of swaps 
% cfg.numrandomization = 1;        % no swaps, don't do stats.  % FOR DETEMRINING NON-CONDITION SPECIFIC ROIs?
cfg.parameter        = 'powspctrm';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
cfg.neighbours       = {};  
cfg.design   = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar     = 2;
cfg.ivar     = 1;

% note for MOUS: if reading in TFR_Hann/MultDiff: do cfg.correctm = a local
% correction, but also need to do a bonferroni afterwards accounting that
% ft_freqstatistics is performed several times, once for each sensor-group.

%% (G) PERMUTE FOR Layout #2 on 8.6.2012
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

%%%%% choose cdtn for which to calculate stats

%loop through structure to do statistics for each cluster
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    statroi1(k) = ft_freqstatistics(cfg, freq1{:});
    statroi2(k) = ft_freqstatistics(cfg, freq2{:});
    statroi1(k).label = roi(k).label;
    statroi2(k).label = roi(k).label;
end

%%%%% PLOT
  
% LEFT HEMISPHERE --------------------------------------------------------
% under 30Hz
        % probabilities
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfront
title ('Lfront <30 prob')
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).prob));axis xy; colorbar; caxis ([0 0.1]); % Ltemp
title ('Ltemp <30 prob')
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfront
title ('Lpar <30 prob')
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).prob));axis xy; colorbar; caxis ([0 0.1]); % Ltemp
title ('Locc <30 prob')

        % statistics   
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).stat));axis xy; colorbar; caxis([-9 9]);   % Lfront
title ('Lfront <30 stat')
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).stat));axis xy; colorbar; caxis([-9 9]);   % Ltemp
title ('Ltemp <30 stat')
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).stat));axis xy; colorbar; caxis([-9 9]);   % Lpar
title ('Lpar <30 stat')
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).stat));axis xy; colorbar; caxis([-9 9]);  % Locc
title ('Locc <30 stat')

% over 30Hz
% Multitaper
        % probabilities
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfont
title ('Lfront >30 prob')
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).prob));axis xy; colorbar; caxis ([0 0.1]);  % Ltemp
title ('Ltemp >30 prob')
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).prob));axis xy; colorbar; caxis ([0 0.1]);  % Lfront
title ('Lpar >30 prob')
figure;imagesc(statroi2(4).time,statroi2(4).freq,shiftdim(statroi2(4).prob));axis xy; colorbar; caxis ([0 0.1]);  % Ltemp
title ('Locc >30 prob')

        % statistics
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).stat));axis xy; colorbar; caxis([-9 9]); % Lfront
title ('Lfront >30 stat')
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).stat));axis xy; colorbar; caxis([-9 9]); % Ltemp
title ('Ltemp >30 stat')
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).stat));axis xy; colorbar; caxis([-9 9]); % Lpar
title ('Lpar >30 stat')
figure;imagesc(statroi2(4).time,statroi2(4).freq,shiftdim(statroi2(4).stat));axis xy; colorbar; caxis([-9 9]); % Locc
title ('Locc >30 stat')

% RIGHT HEMISPHERE  -------------------------------------------------------------------------

% under 30Hz = statroi1
        % probabilities
figure;imagesc(statroi1(1).time,statroi1(5).freq,shiftdim(statroi1(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('Rfront <30 prob')
figure;imagesc(statroi1(2).time,statroi1(6).freq,shiftdim(statroi1(6).prob));axis xy; colorbar; caxis ([0 0.1]); % Rtemp
title ('Rtemp <30 prob')
figure;imagesc(statroi1(3).time,statroi1(7).freq,shiftdim(statroi1(7).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('Rpar <30 prob')
figure;imagesc(statroi1(4).time,statroi1(8).freq,shiftdim(statroi1(8).prob));axis xy; colorbar; caxis ([0 0.1]); % Rtemp
title ('Rocc <30 prob')

        % statistics   
figure;imagesc(statroi1(1).time,statroi1(5).freq,shiftdim(statroi1(5).stat));axis xy; colorbar; caxis([-9 9]);   % Rfront
title ('Rfront <30 stat')
figure;imagesc(statroi1(2).time,statroi1(6).freq,shiftdim(statroi1(6).stat));axis xy; colorbar; caxis([-9 9]);   % Rtemp
title ('Rtemp <30 stat')
figure;imagesc(statroi1(3).time,statroi1(7).freq,shiftdim(statroi1(7).stat));axis xy; colorbar; caxis([-9 9]);   % Rpar
title ('Rpar <30 stat')
figure;imagesc(statroi1(4).time,statroi1(8).freq,shiftdim(statroi1(8).stat));axis xy; colorbar; caxis([-9 9]);   % Rocc
title ('Rocc <30 stat')

% over 30Hz  = statroi2
% Multitaper
        % probabilities
figure;imagesc(statroi2(1).time,statroi2(5).freq,shiftdim(statroi2(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('Rfront >30 prob')
figure;imagesc(statroi2(2).time,statroi2(6).freq,shiftdim(statroi2(6).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rtemp
title ('Rtemp >30 prob')
figure;imagesc(statroi2(3).time,statroi2(7).freq,shiftdim(statroi2(7).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rpar
title ('Rpar >30 prob')
figure;imagesc(statroi2(4).time,statroi2(8).freq,shiftdim(statroi2(8).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rocc
title ('Rocc >30 prob')

        % statistics
figure;imagesc(statroi2(1).time,statroi2(5).freq,shiftdim(statroi2(5).stat));axis xy; colorbar; caxis([-9 9]);  % Rfront
title ('Rfront >30 stat')
figure;imagesc(statroi2(2).time,statroi2(6).freq,shiftdim(statroi2(6).stat));axis xy; colorbar; caxis([-9 9]);  % Rtemp
title ('Rtemp >30 stat')
figure;imagesc(statroi2(3).time,statroi2(7).freq,shiftdim(statroi2(7).stat));axis xy; colorbar; caxis([-9 9]);  % Rpar
title ('Rpar >30 stat')
figure;imagesc(statroi2(4).time,statroi2(8).freq,shiftdim(statroi2(8).stat));axis xy; colorbar; caxis([-9 9]);  % Rocc 
title ('Rocc >30 stat')

%% (H) PERMUTE FOR LAYOUT #3 on 6.7.2012
% No left right division for Occipital and central sensor-groups

roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC11','MLC12','MLF11','MLF12','MLF13','MLF14','MLF21','MLF22','MLF23','MLF24','MLF25','MLF31','MLF32','MLF33','MLF34','MLF35','MLF41','MLF42','MLF43','MLF44','MLF45','MLF46','MLF51','MLF52','MLF53','MLF54','MLF55','MLF61','MLF62','MLF63','MLF64','MLT11','MLT21','MLT31','MZC01','MZF02','MLC13','MLC14'};

roi(2).label    = 'LTemp';
roi(2).channel  = {'MLF56','MLF65','MLF66','MLF67','MLT12','MLT13','MLT14','MLT22','MLT23','MLT24','MLT25','MLT26','MLT32','MLT33','MLT34','MLT35','MLT36','MLT37','MLT41','MLT42','MLT43','MLT44','MLT45','MLT46','MLT47'};

roi(3).label    = 'LmedTemp'; 
roi(3).channel  = {'MLC15','MLC16','MLC17','MLC22','MLC23','MLC24','MLC25','MLC31','MLC32','MLO13','MLO14','MLO24','MLO34','MLP23','MLP33','MLP34','MLP35','MLP42','MLP43','MLP44','MLP45','MLP53','MLP54','MLP55','MLP56','MLP57','MLT15','MLT16','MLT27','MLC42'};

roi(4).label    = 'Cent(LR)';
roi(4).channel  = {'MLP21','MLP31','MLP32','MLP41','MLC21','MLC51','MLC52','MLC53','MLC54','MLC55','MLC61','MLC62','MLC63','MLP11','MLP12','MLP22','MZC03','MZPO1','MLC41','MRP21','MRP31','MRP32','MRP41','MRC21','MRC51','MRC52','MRC53','MRC54','MRC55','MRC61','MRC62','MRC63','MRP11','MRP12','MRP22','MZC02','MZC04','MRC41'};

roi(5).label    = 'Rfront';
roi(5).channel  = {'MRC11','MRC12','MRF11','MRF12','MRF13','MRF14','MRF21','MRF22','MRF23','MRF24','MRF25','MRF31','MRF32','MRF33','MRF34','MRF35','MRF41','MRF42','MRF43','MRF44','MRF45','MRF46','MRF51','MRF52','MRF53','MRF54','MRF55','MRF61','MRF62','MRF63','MRF64','MRT11','MRT21','MRT31','MZF01','MZF03','MRC13','MRC14'};

roi(6).label    = 'Rtemp';
roi(6).channel  = {'MRF56','MRF65','MRF66','MRF67','MRT12','MRT13','MRT14','MRT22','MRT23','MRT24','MRT25','MRT26','MRT32','MRT33','MRT34','MRT35','MRT36','MRT37','MRT41','MRT42','MRT43','MRT44','MRT45','MRT46','MRT47'};

roi(7).label    = 'RmedTemp';
roi(7).channel  = {'MRC15','MRC16','MRC17','MRC22','MRC23','MRC24','MRC25','MRC31','MRC32','MRO13','MRO14','MRO24','MRO34','MRP23','MRP33','MRP34','MRP35','MRP42','MRP43','MRP44','MRP45','MRP53','MRP54','MRP55','MRP56','MRP57','MRT15','MRT16','MRT27','MRC42'};

roi(8).label    = 'Occ(LR)';
roi(8).channel  = {'MLO11','MLO12','MLO21','MLO22','MLO23','MLO31','MLO32','MLO33','MLO41','MLO42','MLO43','MLO44','MLO51','MLO52','MLO53','MLP51','MLP52','MZO02','MRO11','MRO12','MRO21','MRO22','MRO23','MRO31','MRO32','MRO33','MRO41','MRO42','MRO43','MRO44','MRO51','MRO52','MRO53','MRP51','MRP52','MZO01','MZO03'};
 
% loop through structure to do statistics for each cluster
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    statroi1(k) = ft_freqstatistics(cfg, freq1{:});  %change structure name if necessary
    statroi2(k) = ft_freqstatistics(cfg, freq2{:});
    statroi1(k).label = roi(k).label;
    statroi2(k).label = roi(k).label;
end

% PLOT

% LEFT HEMISPHERE --------------------------------------------------------
% under 30Hz
        % probabilities
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfront
title ('Lfront <30 prob')
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).prob));axis xy; colorbar; caxis ([0 0.1]); % Ltemp
title ('Ltemp <30 prob')
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfront
title ('LmedTemp <30 prob')
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).prob));axis xy; colorbar; caxis ([0 0.1]); % Ltemp
title ('Cent(LR) <30 prob')

        % statistics   
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).stat));axis xy; colorbar; caxis([-9 9]);   % Lfront
title ('Lfront <30 stat')
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).stat));axis xy; colorbar; caxis([-9 9]);   % Ltemp
title ('Ltemp <30 stat')
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).stat));axis xy; colorbar; caxis([-9 9]);   % Lpar
title ('LmedTemp  <30 stat')
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).stat));axis xy; colorbar; caxis([-9 9]);  % Locc
title ('Cent(LR) <30 stat')

% over 30Hz
% Multitaper
        % probabilities
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfont
title ('Lfront >30 prob')
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).prob));axis xy; colorbar; caxis ([0 0.1]);  % Ltemp
title ('Ltemp >30 prob')
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).prob));axis xy; colorbar; caxis ([0 0.1]);  % Lfront
title ('LmedTemp  >30 prob')
figure;imagesc(statroi2(4).time,statroi2(4).freq,shiftdim(statroi2(4).prob));axis xy; colorbar; caxis ([0 0.1]);  % Ltemp
title ('Cent(LR) >30 prob')

        % statistics
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).stat));axis xy; colorbar; caxis([-9 9]); % Lfront
title ('Lfront >30 stat')
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).stat));axis xy; colorbar; caxis([-9 9]); % Ltemp
title ('Ltemp >30 stat')
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).stat));axis xy; colorbar; caxis([-9 9]); % Lpar
title ('LmedTemp >30 stat')
figure;imagesc(statroi2(4).time,statroi2(4).freq,shiftdim(statroi2(4).stat));axis xy; colorbar; caxis([-9 9]); % Locc
title ('Cent(LR) >30 stat')

% RIGHT HEMISPHERE  -------------------------------------------------------------------------

% under 30Hz = statroi1
        % probabilities
figure;imagesc(statroi1(1).time,statroi1(5).freq,shiftdim(statroi1(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('Rfront <30 prob')
figure;imagesc(statroi1(2).time,statroi1(6).freq,shiftdim(statroi1(6).prob));axis xy; colorbar; caxis ([0 0.1]); % Rtemp
title ('Rtemp <30 prob')
figure;imagesc(statroi1(3).time,statroi1(7).freq,shiftdim(statroi1(7).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('RmedTemp <30 prob')
figure;imagesc(statroi1(4).time,statroi1(8).freq,shiftdim(statroi1(8).prob));axis xy; colorbar; caxis ([0 0.1]); % Rtemp
title ('Occ(LR)<30 prob')

        % statistics   
figure;imagesc(statroi1(1).time,statroi1(5).freq,shiftdim(statroi1(5).stat));axis xy; colorbar; caxis([-9 9]);   % Rfront
title ('Rfront <30 stat')
figure;imagesc(statroi1(2).time,statroi1(6).freq,shiftdim(statroi1(6).stat));axis xy; colorbar; caxis([-9 9]);   % Rtemp
title ('Rtemp <30 stat')
figure;imagesc(statroi1(3).time,statroi1(7).freq,shiftdim(statroi1(7).stat));axis xy; colorbar; caxis([-9 9]);   % Rpar
title ('RmedTemp <30 stat')
figure;imagesc(statroi1(4).time,statroi1(8).freq,shiftdim(statroi1(8).stat));axis xy; colorbar; caxis([-9 9]);   % Rocc
title ('Occ(LR) <30 stat')

% over 30Hz  = statroi2
% Multitaper
        % probabilities
figure;imagesc(statroi2(1).time,statroi2(5).freq,shiftdim(statroi2(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title ('Rfront >30 prob')
figure;imagesc(statroi2(2).time,statroi2(6).freq,shiftdim(statroi2(6).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rtemp
title ('Rtemp >30 prob')
figure;imagesc(statroi2(3).time,statroi2(7).freq,shiftdim(statroi2(7).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rpar
title ('RmedTemp  >30 prob')
figure;imagesc(statroi2(4).time,statroi2(8).freq,shiftdim(statroi2(8).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rocc
title ('Occ(LR) >30 prob')

        % statistics
figure;imagesc(statroi2(1).time,statroi2(5).freq,shiftdim(statroi2(5).stat));axis xy; colorbar; caxis([-9 9]);  % Rfront
title ('Rfront >30 stat')
figure;imagesc(statroi2(2).time,statroi2(6).freq,shiftdim(statroi2(6).stat));axis xy; colorbar; caxis([-9 9]);  % Rtemp
title ('Rtemp >30 stat')
figure;imagesc(statroi2(3).time,statroi2(7).freq,shiftdim(statroi2(7).stat));axis xy; colorbar; caxis([-9 9]);  % Rpar
title ('RmedTemp  >30 stat')
figure;imagesc(statroi2(4).time,statroi2(8).freq,shiftdim(statroi2(8).stat));axis xy; colorbar; caxis([-9 9]);  % Rocc 
title ('Occ(LR) >30 stat')


%% cluster permutation statistics for whole head, all frequencies
%  involves creating a design matrix that has 2 rows:
%  row1 = condition (Hann vs. Mult); row2 = which subject's data
%  1 1 1 1 1 2 2 2 2 2
%  1 2 3 4 5 1 2 3 4 5

cfg = [];
%cfg.avgoverchan         = 'yes';
cfg.method              = 'montecarlo';
cfg.statistic           = 'depsamplesT';
cfg.tail                = 0;
cfg.alpha               = 0.025;
cfg.numrandomization    = 1000;  % use value of 0 if just want to get an idea of data
cfg.parameter           = 'powspctrm';
cfg.design              = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];  
cfg.ivar                = 1;  % independent variable: sent vs. seq
cfg.uvar                = 2;  % units of observation: subjects
stat1                   = ft_freqstatistics(cfg, freq1{:});  % statistics on entire array
stat2                   = ft_freqstatistics(cfg, freq2{:});

% plot 
cfg3            = [];
cfg3.parameter  = 'stat'; 
cfg3.interactive  = 'yes';
cfg3.channel      = 'all'; 
cfg3.layout       = 'CTF275.lay';
figure; ft_singleplotTFR(cfg3, stat1Lfront);   % not interactive because collapsed across channels
figure; ft_singleplotTFR(cfg3, stat2Lfront);