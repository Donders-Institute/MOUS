% % Use condition-nonspecific permutation to determine ROIs for TFRs
  % Test for a difference between sentences and sequences using these ROIs
% % JM, NL 7.6.2012

% full list
%subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         %'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         % 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};

% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% PART ONE: determine ROIs        
%% (A) get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

cfg = [];
cfg.baseline = [-0.3 -0.2];
cfg.baselinetype = 'relchange';

for k = 1:numel(subjlist)
  %load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_05-3ds-pg']);
   load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_Hann4under30_05-3ds-pg']);

  % combine conditions and do a baseline correction
  freq1_comb{k} = TFRHann_SenTar_PG; 
  freq1_comb{k}.powspctrm = ((TFRHann_SenTar_PG.powspctrm + TFRHann_SeqTar_PG.powspctrm)./2);  
  freq1_comb{k} = ft_freqbaseline(cfg, freq1_comb{k});
  
  freq2_comb{k} = TFRMult_SenTar_PG; 
  freq2_comb{k}.powspctrm = ((TFRMult_SenTar_PG.powspctrm + TFRMult_SeqTar_PG.powspctrm)./2);  
  freq2_comb{k} = ft_freqbaseline(cfg, freq2_comb{k});
end

%% (B) create empty powerspectra for permutation in next step 

freq1_comb(nsubj+(1:nsubj)) = freq1_comb;  % add another nsubj number of columns
freq2_comb(nsubj+(1:nsubj)) = freq2_comb;
for k = nsubj+(1:nsubj)          
  freq1_comb{k}.powspctrm(:) = 0;
  freq2_comb{k}.powspctrm(:) = 0;
end

%% (C) cluster permutation statistics for whole head, all frequencies

cfg = [];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';  %  OR 'diff'
cfg.correctm         = 'no';      %  cfg.correctm = 'no' - do not apply multiple-comparison correction.  % Choose this for determining non-condition specified ROIs
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';   % how single samples belonging to a cluster are combined.
cfg.latency          = [-inf 1];
%cfg.minnbchan        = 2;
cfg.tail             = 0;
%cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 2000;       % number of swaps 
% cfg.numrandomization = 1;        % no swaps, don't do stats.  % FOR DETEMRINING NON-CONDITION SPECIFIC ROIs?
cfg.parameter        = 'powspctrm';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
%cfg.neighbours       = {};  
cfg.design           = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar             = 2;
cfg.ivar             = 1;
stat1                = ft_freqstatistics(cfg, freq1_comb{:});  % statistics on entire array
stat2                = ft_freqstatistics(cfg, freq2_comb{:});

% plot 
% under 30Hz
cfg2            = [];
cfg2.layout     = 'CTF275.lay';
cfg2.interactive = 'yes';
cfg2.parameter  = 'stat2';
cfg2.zlim       = 'maxabs';
stat1.stat2                         = stat1.stat;  % assign "stat1.stat" to a different field so that changes can be applied without overwriting
stat1.stat2(stat1.prob>=0.005)      = 0;           % 'turn off' all freq-time points which are greater than 0.005. Somewhat of an arbitrary value but shouldn't be bigger than 0.01 because a multiple-comparision control not performed
figure; ft_multiplotTFR(cfg2, stat1)

% over 30Hz
stat2.stat2                         = stat2.stat;  % assign "stat1.stat" to a different field so that changes can be applied without overwriting
stat2.stat2(stat1.prob>=0.005)      = 0;           % 'turn off' all freq-time points which are greater than 0.005. Somewhat of an arbitrary value but shouldn't be bigger than 0.01 because a multiple-comparision control not performed
figure; ft_multiplotTFR(cfg2, stat2);

% -------------------------------------------------------------------------------------------
%% PART 2: statistical test between conditions using condition non-specific determined ROIs
%% Load data into appropriate design matrix structure
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

% configuration to control for baseline for each condition
% cfg = [];
% cfg.baseline = [-0.3 -0.1];
% cfg.baselinetype = 'absolute';

for k = 1:numel(subjlist)
  %load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_05-3ds-pg']);
  load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_Hann4under30_05-3ds-pg']);
  
  % load sentences and sequences into 2 columns
  freq1{k} = TFRHann_SenTar_PG;                                 %      SenTar         SeqTar              % permuting between these 2 conditions
  freq2{k} = TFRMult_SenTar_PG;                                 %   1 1 1 1 1 1       2 2 2 2 2 2         % cfg.ivar (independent variables)
  freq1{k+nsubj} = TFRHann_SeqTar_PG;                           %   1 2 3 4 5 6       1 2 3 4 5 6         % cfg.uvar (units of observ.)
  freq2{k+nsubj} = TFRMult_SeqTar_PG;
  
  % control for baseline
%   freq1_b{k} = ft_freqbaseline(cfg, freq1{k});
%   freq1_b{k+nsubj} = ft_freqbaseline(cfg,freq1{k+nsubj});
%   freq2_b{k} = ft_freqbaseline(cfg, freq2{k});
%   freq2_b{k+nsubj} = ft_freqbaseline(cfg,freq2{k+nsubj});
end
%% define ROIs - based on multitapers for <30 and >30Hz

% define clusters
% roi(1).label    = 'Lfront';
% roi(1).channel  = {'MLC16', 'MLC17', 'MLF46', 'MLF55', 'MLF56', 'MLF65', 'MLF66', 'MLF67', 'MLT13'  'MLF53', 'MLF54' 'MLF63'};
% 
% roi(2).label    = 'LtempPar';
% roi(2).channel  = {'MLT34', 'MLT35', 'MLT43', 'MLT44', 'MLT45', 'MLT53', 'MLT54'};
% 
% roi(3).label    = 'Locc';
% roi(3).channel  = {'MLO12', 'MLO23', 'MLO24', 'MLO32', 'MLO33', 'MLO34', 'MLO44'};
% 
% roi(4).label    = 'Rfront';
% roi(4).channel  = {'MRF35', 'MRF45', 'MRF46', 'MRF55', 'MRF56', 'MRF65', 'MRT11'};
% 
% roi(5).label    = 'RtempPar';
% roi(5).channel  = {'MRT34', 'MRT35', 'MRT43', 'MRT44', 'MRT45', 'MRT52', 'MRT53'};
% 
% roi(6).label    = 'Rocc';
% roi(6).channel  = {'MRO12', 'MRO22', 'MRO23', 'MRO24', 'MRO31', 'MRO32', 'MRO33'};


%% define clusters - based on Hanning taper for <30Hz, and Multitapers for >30Hz
roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC12', 'MLC13', 'MLF53', 'MLF54', 'MLF61', 'MLF62', 'MLF63'};

roi(2).label    = 'LmedTemp';
roi(2).channel  = {'MLF46', 'MLF55', 'MLF56', 'MLF66', 'MLF67', 'MLT11', 'MLT12', 'MLT13'};

roi(3).label    = 'LlatTemp';
roi(3).channel  = {'MLT34', 'MLT43', 'MLT44', 'MLT45', 'MLT53'};

roi(4).label    = 'Locc';
roi(4).channel  = {'MLO12', 'MLO22', 'MLO23', 'MLO24', 'MLO32', 'MLO33', 'MLO34', 'MLO44'};

roi(5).label    = 'Rfront';
roi(5).channel  = {'MRC17', 'MRF56', 'MRF66', 'MRF67', 'MRP57', 'MRT12', 'MRT13'};

roi(6).label    = 'RmedTemp';
roi(6).channel  = {'MRF46', 'MRF56', 'MRF66', 'MRF67', 'MRT11', 'MRT12', 'MRT13', 'MRT23'};

roi(7).label    = 'Rocc';
roi(7).channel  = {'MRO12', 'MRO22', 'MRO23', 'MRO24', 'MRO32', 'MRO33', 'MRO43','MRO44'};


%% permutation test for each ROI

cfg = [];
cfg.avgoverchan      = 'yes';
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
% cfg.numrandomization = 1;        % no swaps, don't do stats.  % FOR DETEMRINING NON-CONDITION SPECIFIC ROIs?
cfg.parameter        = 'powspctrm';
cfg_neighb.method    = 'distance'; % specifies with which sensors other sensors can form clusters
%cfg.neighbours       = {};  
cfg.design           = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar             = 2;
cfg.ivar             = 1;

%loop through structure to do statistics for each cluster
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    statroi1(k) = ft_freqstatistics(cfg, freq1{:});
    statroi2(k) = ft_freqstatistics(cfg, freq2{:});
    statroi1(k).label = roi(k).label;
    statroi2(k).label = roi(k).label;
end

save('Group_16ptp_SentvsSeqPerm_cdtnNonSpecDeterminedROIs_Hann4Under30Hz_19July2012','statroi1','statroi2','nsubj','freq1','freq2','roi'); %'freq1_b','freq2_b'

%% plot to determine significance / look at p-values
% LEFT HEMISPHERE --------------------------------------------------------
% under 30Hz
        % probabilities
        
%image(X,Y,C): 
% C = matrix being displayed as an image
% X & Y are vectors specifing location of pixel centres of C(1,1) and C(M,N)
% shiftdim removes all singleton values in matrix
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfront
title (strcat(statroi1(1).label,' <30 Prob'));
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).prob));axis xy; colorbar; caxis ([0 0.1]); % Ltemp
title (strcat(statroi1(2).label,' <30 Prob'));
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).prob));axis xy; colorbar; caxis ([0 0.1]); % LRocc
title (strcat(statroi1(3).label,' <30 Prob'));
figure;imagesc(statroi1(4).time,statroi1(4).freq,shiftdim(statroi1(4).prob));axis xy; colorbar; caxis ([0 0.1]); % LRocc
title (strcat(statroi1(4).label,' <30 Prob'));

        % statistics   
figure;imagesc(statroi1(1).time,statroi1(1).freq,shiftdim(statroi1(1).stat));axis xy; colorbar; caxis([-6 6]);   % Lfront
title (strcat(statroi1(1).label,' <30  Stat'));
figure;imagesc(statroi1(2).time,statroi1(2).freq,shiftdim(statroi1(2).stat));axis xy; colorbar; caxis([-6 6]);   % Ltemp
title (strcat(statroi1(2).label,' <30  Stat'));
figure;imagesc(statroi1(3).time,statroi1(3).freq,shiftdim(statroi1(3).stat));axis xy; colorbar; caxis([-6 6]);   % LRocc
title (strcat(statroi1(3).label,' <30  Stat'));
figure;imagesc(statroi1(4).time,statroi1(3).freq,shiftdim(statroi1(4).stat));axis xy; colorbar; caxis([-6 6]);   % LRocc
title (strcat(statroi1(4).label,' <30  Stat'));

% over 30Hz
% Multitaper
        % probabilities
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).prob));axis xy; colorbar; caxis ([0 0.1]); % Lfont
title (strcat(statroi1(1).label,' >30  Prob'));
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).prob));axis xy; colorbar; caxis ([0 0.1]);  % Ltemp
title (strcat(statroi1(2).label,' >30  Prob'));
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).prob));axis xy; colorbar; caxis ([0 0.1]);  % LRocc
title (strcat(statroi1(3).label,' >30  Prob'));
figure;imagesc(statroi2(4).time,statroi2(4).freq,shiftdim(statroi2(4).prob));axis xy; colorbar; caxis ([0 0.1]);  % LRocc
title (strcat(statroi1(4).label,' >30  Prob'));

        % statistics
figure;imagesc(statroi2(1).time,statroi2(1).freq,shiftdim(statroi2(1).stat));axis xy; colorbar; caxis([-6 6]); % Lfront
title (strcat(statroi1(1).label,' >30 Stat'));
figure;imagesc(statroi2(2).time,statroi2(2).freq,shiftdim(statroi2(2).stat));axis xy; colorbar; caxis([-6 6]); % Ltemp
title (strcat(statroi1(2).label,' >30 Stat'));
figure;imagesc(statroi2(3).time,statroi2(3).freq,shiftdim(statroi2(3).stat));axis xy; colorbar; caxis([-6 6]); % LRocc
title (strcat(statroi1(3).label,' >30 Stat'));
figure;imagesc(statroi2(4).time,statroi2(3).freq,shiftdim(statroi2(4).stat));axis xy; colorbar; caxis([-6 6]); % LRocc
title (strcat(statroi1(4).label,' >30 Stat'));

% RIGHT HEMISPHERE  -------------------------------------------------------------------------

% under 30Hz = statroi1
        % probabilities
figure;imagesc(statroi1(5).time,statroi1(5).freq,shiftdim(statroi1(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title (strcat(statroi1(5).label,' <30 Prob'))
figure;imagesc(statroi1(6).time,statroi1(5).freq,shiftdim(statroi1(6).prob));axis xy; colorbar; caxis ([0 0.1]); % Rtemp
title (strcat(statroi1(6).label,' <30 Prob'))
figure;imagesc(statroi1(7).time,statroi1(6).freq,shiftdim(statroi1(7).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title (strcat(statroi1(7).label,' <30 Prob'))

        % statistics   
figure;imagesc(statroi1(5).time,statroi1(5).freq,shiftdim(statroi1(5).stat));axis xy; colorbar; caxis([-6 6]);   % Rfront
title (strcat(statroi1(5).label,' <30 Stat'))
figure;imagesc(statroi1(6).time,statroi1(6).freq,shiftdim(statroi1(6).stat));axis xy; colorbar; caxis([-6 6]);   % Rtemp
title (strcat(statroi1(6).label,' <30 Stat'))
figure;imagesc(statroi1(7).time,statroi1(7).freq,shiftdim(statroi1(7).stat));axis xy; colorbar; caxis([-6 6]);   % Rpar
title (strcat(statroi1(7).label,' <30 Stat'))

% over 30Hz  = statroi2
% Multitaper
        % probabilities
figure;imagesc(statroi2(5).time,statroi2(4).freq,shiftdim(statroi2(5).prob));axis xy; colorbar; caxis ([0 0.1]); % Rfront
title (strcat(statroi2(5).label,' >30 Prob'))
figure;imagesc(statroi2(6).time,statroi2(5).freq,shiftdim(statroi2(6).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rtemp
title (strcat(statroi2(6).label,' >30 Prob'))
figure;imagesc(statroi2(7).time,statroi2(6).freq,shiftdim(statroi2(7).prob));axis xy; colorbar; caxis ([0 0.1]);  % Rpar
title (strcat(statroi2(7).label,' >30 Prob'))

        % statistics
figure;imagesc(statroi2(5).time,statroi2(4).freq,shiftdim(statroi2(5).stat));axis xy; colorbar; caxis([-6 6]);  % Rfront
title (strcat(statroi2(5).label,' >30 Stat'))
figure;imagesc(statroi2(6).time,statroi2(5).freq,shiftdim(statroi2(6).stat));axis xy; colorbar; caxis([-6 6]);  % Rtemp
title (strcat(statroi2(6).label,' >30 Stat'))
figure;imagesc(statroi2(7).time,statroi2(6).freq,shiftdim(statroi2(7).stat));axis xy; colorbar; caxis([-6 6]);  % Rpar
title (strcat(statroi2(7).label,' >30 Stat'))

