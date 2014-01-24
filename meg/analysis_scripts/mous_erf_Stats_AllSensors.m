% % THIS SCRIPT DETERMINES THE condition-nonspecific determined ROI FOR ERF DATA
%   Then statistical tests are performed on these ROIs for difference
%   between sentences and sequences
% % JM, NL 17-7-2012

% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% (A) get the individual data for long time window
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-pg']);  % load data
  erfAllTar{k} = senTar_CPG;   
  tmp = ((senTar_CPG.avg + seqTar_CPG.avg)./2);
  ix1 = nearest(senTar_CPG.time,-0.5);
  ix2 = nearest(senTar_CPG.time,-0.3);
  tmp = tmp./repmat(mean(tmp(:,ix1:ix2),2),[1 size(tmp,2)])-1;
  
  erfAllTar{k}.avg = tmp; % doesn't account for fact that there are not an equal number of trials in each condition
end

%% (B) create empty 2nd condition
erfAllTar(nsubj+(1:nsubj)) = erfAllTar;  % add another nsubj number of columns
for k = nsubj+(1:nsubj)                  % from column 19+1, 19+2 ... i.e. 20 to 38 assign 0 (no difference powspctra)
  erfAllTar{k}.avg(:) = 0;
end

%% (C) cluster permutation statistics for whole head, all frequencies
%  involves creating a design matrix that has 2 rows:
%  row1 = condition (Hann vs. Mult); row2 = which subject's data
%  1 1 1 1 1 2 2 2 2 2
%  1 2 3 4 5 1 2 3 4 5

cfg                     = [];
cfg.channel             = {'MEG'};
%cfg.avgoverchan         = 'yes';
cfg.method              = 'montecarlo';
cfg.statistic           = 'depsamplesT';
cfg.latency             = [-inf 1];
cfg.tail                = 0;
cfg.alpha               = 0.025;
cfg.numrandomization    = 2000;  % use value of 0 if just want to get an idea of data
cfg.parameter           = 'avg';
cfg.correctm            = 'no';
cfg.clusteralpha        = 0.05;
cfg.clusterstatistic    = 'maxsum';
cfg.minnbchan           = 2;
cfg.tail                = 0;
cfg.clustertail         = 0;
cfg.numrandomization    = 500;
% specifies with which sensors other sensors can form clusters
cfg_neighb.method       = 'distance';
%cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, erfSenTar);
cfg.design              = [ones(1,nsubj) 2*ones(1,nsubj); 1:nsubj 1:nsubj];
cfg.uvar                = 2;
cfg.ivar                = 1;

stat_erf     = ft_timelockstatistics(cfg, erfAllTar{:});  % statistics on entire array (instead of doing ft_timelockgrandaverage separately)

%% plot

cfg2            = [];
cfg2.layout     = 'CTF275.lay';
cfg2.interactive = 'yes';
cfg2.parameter  = 'stat';
cfg2.zlim       = 'maxabs';
%stat1.stat2                         = stat1.stat;  % assign "stat1.stat" to a different field so that changes can be applied without overwriting
%stat1.stat2(stat1.prob>=0.005)      = 0;           % 'turn off' all freq-time points which are greater than 0.005. Somewhat of an arbitrary value but shouldn't be bigger than 0.01 because a multiple-comparision control not performed
figure; ft_multiplotER(cfg2, stat_erf);

%% PART 2: statistical test between conditions using condition non-specific determined ROIs
%% Load data into appropriate design matrix structure
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

% correct for baseline?

for k = 1:numel(subjlist)
    load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-pg']);
  % load sentences and sequences into 2 columns
    erf{k} = senTar_CPG;                                    %      SenTar          SeqTar         permuting between these 2 conditions
    erf{k+nsubj} = seqTar_CPG;                              %     1 1 1 1 1 1    2 2 2 2 2 2      cfg.ivar (independent variables)                                                       
end                                                         %     1 2 3 4 5 6    1 2 3 4 5 6      cfg.uvar (units of observ.
%% define ROIs  % TO BE MODIFIED  7.17.2012

roi(1).label    = 'Lfront';
roi(1).channel  = {'MLC16', 'MLC17', 'MLF46', 'MLF55', 'MLF56', 'MLF65', 'MLF66', 'MLF67', 'MLT13'  'MLF53', 'MLF54' 'MLF63'};

roi(2).label    = 'LtempPar';
roi(2).channel  = {'MLT34', 'MLT35', 'MLT43', 'MLT44', 'MLT45', 'MLT53', 'MLT54'};

roi(3).label    = 'Locc';
roi(3).channel  = {'MLO12', 'MLO23', 'MLO24', 'MLO32', 'MLO33', 'MLO34', 'MLO44'};

roi(4).label    = 'Rfront';
roi(4).channel  = {'MRF35', 'MRF45', 'MRF46', 'MRF55', 'MRF56', 'MRF65', 'MRT11'};

roi(5).label    = 'RtempPar';
roi(5).channel  = {'MLT34', 'MLT35', 'MLT43', 'MLT44', 'MLT45', 'MLT53', 'MLT54'};

roi(6).label    = 'Rocc';
roi(6).channel  = {'MRO12', 'MRO22', 'MRO23', 'MRO24', 'MRO31', 'MRO32', 'MRO33'};

%% permutation test for each ROI

cfg = [];
cfg.avgoverchan      = 'yes';
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

%loop through structure to do statistics for each cluster
for k = 1:numel(roi)
    cfg.channel = roi(k).channel;  % to loop through structure assign it to the same variable for each loop
    statroi1(k) = ft_timelockstatistics(cfg, erf:});
    statroi1(k).label = roi(k).label;
end

%% PLOT

ft_singleplotER.
