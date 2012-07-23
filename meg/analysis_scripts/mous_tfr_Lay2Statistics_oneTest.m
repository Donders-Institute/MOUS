% % THIS FUNCTION PERFORMS CLUSTER-BASED PERMUTATION TEST ON TFR DATA TO DETERMINE
% % WHETHER THE PRE-DEFINED SENSOR-GROUPS (lay2) ARE SIGNIFICANT IN DIFFERENCE
% BETWEEN TWO CONDITIONS (sentence vs. sequences)
% % JM, NL 7.6.2012


% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};
 
%% (A) get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

% baseline config.
% cfg = [];
% cfg.baseline = [-0.3 -0.2];
% cfg.baselinetype = 'relchange';

for k = 1:numel(subjlist)
  %load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_05-3ds-pg']);
  load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_Hann4under30_05-3ds-pg']);
  % load sentences and sequences into 2 columns
  freq1{k} = TFRHann_SenTar_PG;                                 %      SenTar         SeqTar              % permuting between these 2 conditions
  freq2{k} = TFRMult_SenTar_PG;                                 %   1 1 1 1 1 1       2 2 2 2 2 2         % cfg.ivar (independent variables)
  freq1{k+nsubj} = TFRHann_SeqTar_PG;                           %   1 2 3 4 5 6       1 2 3 4 5 6         % cfg.uvar (units of observ.)
  freq2{k+nsubj} = TFRMult_SeqTar_PG;
  
%   freq1_b{k} = ft_freqbaseline(cfg, freq1{k});
%   freq1_b{k+nsubj} = ft_freqbaseline(cfg,freq1{k+nsubj});
%   freq2_b{k} = ft_freqbaseline(cfg, freq2{k});
%   freq2_b{k+nsubj} = ft_freqbaseline(cfg,freq2{k+nsubj});
end

%% (B) define ROIs

%  Layout #2 on 8.6.2012
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

%% Get powspctrm from each ROI into one structure

% Average across subset of channels
% produces k structures, each one averaged over channels, but data from
% each participant is just appended (one after another), and sent (1:nsubj) and seq(nsubj+(1:nsubj) conditions are still separate
for k = 1:numel(roi)
  freq1_avgChan{k} = ft_selectdata(freq1{:},'param','powspctrm','avgoverchan','yes','channel',roi(k).channel);
  freq2_avgChan{k} = ft_selectdata(freq2{:},'param','powspctrm','avgoverchan','yes','channel',roi(k).channel);
end

% assign each averaged channel's data into one data structure "allpow" for ft_freqstatistics
% allocate space for data <30Hz
siz1 = size(freq1_avgChan{1}.powspctrm);          % size of each dimension of ROI's powspctrm: 32 1 12 61 (rpt_chan_freq_time) (just picked {1} because it's the same for all ROIs)
siz1(2) = numel(roi);                             % size(2) = # of channels --> numel(roi)
allPow1 = zeros(siz1);                            % 32 rows (16 sents, 16 seqs), 8 columns (each column is an average of a group of channels), 12 freqs, 61 timepoints

% allocate space for data >30Hz
siz2 = size(freq2_avgChan{1}.powspctrm);          
siz2(2) = numel(roi);                             
allPow2 = zeros(siz2);                           

% enter the data of other dimensions (ptps, time, freq) with its corresponding ROI into one structure
for k = 1:numel(roi)
  allPow1(:,k,:,:) = freq1_avgChan{k}.powspctrm;  
  allLabel1(k) = freq1_avgChan{k}.label(1);        % assign channel label 'mean(MLC11....)'; need to use label(1) even though only one entry
  allPow2(:,k,:,:) = freq2_avgChan{k}.powspctrm;
  allLabel2(k) = freq2_avgChan{k}.label(1);
end

%% ***WHY DON'T WE need to calculate sent-seq?***
% put into structure suitable for ft_freqstatistics  
% freq1 contains both sent and sequences: 32 rows (1:16 = sent, 17:32 = seq)
freq1 = freq1_avgChan{1};    % assign all the necessary fields
freq1.powspctrm = allPow1;   % freq1.powspctrm now contains the powpspctrm for each averaged sensor group (one in each struct)
freq1.label = allLabel1;

freq2 = freq1_avgChan{1};    % freq2 contains both sent and sequences: 32 rows (1:16 = sent, 17:32 = seq)
freq2.powspctrm = allPow2;   
freq2.label = allLabel2;

freqDummy1 = freq1;          % As freq1 has both conditions, freq2 is the dummy created for permutation to be possible
freqDummy1.powspctrm(:) = 0;

freqDummy2 = freq1;
freqDummy2.powspctrm(:) = 0;


%% (C) perform cluster permutation statistics for each pre-defined sensor-group

% main configuration
cfg = [];
%cfg.avgoverchan      = 'yes';
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';  %  OR 'diff'
cfg.correctm         = 'cluster';      %  cfg.correctm = 'no' - do not apply multiple-comparison correction.  % Choose this for determining non-condition specified ROIs
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';   % how single samples belonging to a cluster are combined.
cfg.latency          = [-inf 1];
%cfg.minnbchan        = 2;
cfg.tail             = 0;
%cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 2000;       % number of swaps 
cfg.parameter        = 'powspctrm';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
cfg.neighbours       = {};  
cfg.design           = [ones(1,nsubj) ones(1,nsubj)*2; 1:nsubj 1:nsubj];
cfg.uvar             = 2;
cfg.ivar             = 1;

statroi1 = ft_freqstatistics(cfg, freq1, freqDummy1);  % freq1_all_avg{:} - no need {:} because all subjects appended into one data structure
statroi2 = ft_freqstatistics(cfg, freq2, freqDummy2);
% statroi1.label = freq1.label;
% statroi2.label = freq2.label;

%loop through structure to do statistics for each cluster
%data given to ft_freqstatistics must be in a cell array.
% for k = 1:numel(roi)
%     cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
%     statroi1(k) = ft_freqstatistics(cfg, freq1, freqDummy);  % freq1_all_avg{:} - no need {:} because all subjects appended into one data structure
%     statroi2(k) = ft_freqstatistics(cfg, freq2, freqDummy);
%     statroi1(k).label = freq1.label;
%     statroi2(k).label = freq2.label;
% end
cd /home/language/annhul/MOUS/Processed/groupTFR;
save('Group_16ptp_SentvsSeqPerm_Lay2_noTest_Hann4Under30Hz_23July2012','statroi1','statroi2','nsubj','freq1','freq2','roi'); %freq1_b,freq2_b


%% (D) PLOT
  
% LEFT HEMISPHERE --------------------------------------------------------
% under 30Hz
        % probabilities
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).prob));axis xy; colorbar; caxis ([0 0.01]); % Lfront
title (strcat(statroi1(1).label,' <30 Prob'));
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).prob));axis xy; colorbar; caxis ([0 0.01]); % Ltemp
title (strcat(statroi1(2).label,' <30 Prob'));
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).prob));axis xy; colorbar; caxis ([0 0.01]); % Lfront
title (strcat(statroi1(3).label,' <30 Prob'));
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).prob));axis xy; colorbar; caxis ([0 0.01]); % Ltemp
title (strcat(statroi1(4).label,' <30 Prob'));
        
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

% figure;imagesc(statroi1(1).time,statroi1(5).freq,shiftdim(statroi1(5).prob));axis xy; colorbar; caxis ([0 0.0031]); % Rfront
% title ('Rfront <30 prob')
% figure;imagesc(statroi1(2).time,statroi1(6).freq,shiftdim(statroi1(6).prob));axis xy; colorbar; caxis ([0 0.0031]); % Rtemp
% title ('Rtemp <30 prob')
% figure;imagesc(statroi1(3).time,statroi1(7).freq,shiftdim(statroi1(7).prob));axis xy; colorbar; caxis ([0 0.0031]); % Rfront
% title ('Rpar <30 prob')
% figure;imagesc(statroi1(4).time,statroi1(8).freq,shiftdim(statroi1(8).prob));axis xy; colorbar; caxis ([0 0.0031]); % Rtemp
% title ('Rocc <30 prob')

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

