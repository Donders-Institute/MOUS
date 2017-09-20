%% get filenames 
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
end

%% load axial data

for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_erf_sen_chopped');
    tlckAsen{k} = tmp;
    tmp = mous_db_getdata(subjA{k},'meg_erf_seq_chopped');
    tlckAseq{k} = tmp;
    tmp = mous_db_getdata(subjV{k},'meg_erf_sen_chopped');
    tlckVsen{k} = tmp;
    tmp = mous_db_getdata(subjV{k},'meg_erf_seq_chopped');
    tlckVseq{k} = tmp;
end

for k = 1:Nsubj
    % correct for bsl-variance in both auditory
    tmp = mous_db_getdata(subjA{k},'meg_erf_bslchopped');
    B=diag(tmp.cov);
    tlckA_covcor{k} = tlckA{k};
    tlckA_covcor{k}.avg=diag(sqrt(1./B))*tlckA{k}.avg;
    % and visual
%     tmp = mous_db_getdata(subjV{k},'meg_erf_bslchopped');
%     B=diag(tmp.cov);
%     tlckV_covcor{k} = tlckV{k};
%     tlckV_covcor{k}.avg=diag(sqrt(1./B))*tlckV{k}.avg;
end
%% select bsl and N400 time windows and save in different vars

for k = 1:Nsubj
    cfg = [];
    cfg.latency = [tlckA{k}.time(1) 0];
    bslA{k} = ft_selectdata(cfg,tlckA{k});
%     bslV{k} = ft_selectdata(cfg,tlckV{k});
%     cfg.latency = [0.3508 0.4500];
%     n400A{k} = ft_selectdata(cfg,tlckA{k});
%     n400V{k} = ft_selectdata(cfg,tlckV{k});
%    
%     bslA{k}.time = n400A{k}.time;
%     bslV{k}.time = n400V{k}.time;
end

%% Or load in pre-sentence bsl per subject (axial only)
% for k = 1:Nsubj
%     tmp = mous_db_getdata(subjA{k},'meg_erf_bslchopped');
%     tlckA{k} = tmp;
%      tmp = mous_db_getdata(subjV{k},'meg_erf_bslchopped');
%      tlckV{k} = tmp;
% end

%% Or create dummy data with zeros
for k = 1:Nsubj
    dum{k} = tlckA_covcor{k};
    dum{k}.avg = zeros(size(tlckA_covcor{k}.avg));    
end

%% Grand average

cfg = [];
cfg.parameter = 'avg';
cfg.appenddim = 'rpt';
allA = ft_appendtimelock(cfg,tlckVsen{:});
allV = ft_appendtimelock(cfg,tlckVseq{:});


cfg = [];
cfg.avgoverrpt = 'yes';
cfg.channel = {'MEG'};
avgVsen= ft_selectdata(cfg,allA);
avgVseq = ft_selectdata(cfg,allV);

% Visualize
cfgp = [];
cfgp.layout = 'CTF275_helmet.mat';
cfgp.parameter = 'trial';
figure;ft_topoplotER(cfgp,avgAsen,avgAseq)
figure;ft_topoplotER(cfgp,avgAseq)


%% statistical test (bonferroni)

cfg = [];
cfg.channel     = 'MEG'; 
cfg.avgovertime = 'no';
cfg.parameter   = 'avg';
cfg.method      = 'analytic';
cfg.statistic   = 'ft_statfun_depsamplesT'
cfg.alpha       = 0.05;
cfg.correctm    = 'bonferroni';
 
cfg.design(1,1:2*Nsubj)  = [ones(1,Nsubj) 2*ones(1,Nsubj)];
cfg.design(2,1:2*Nsubj)  = [1:Nsubj 1:Nsubj];
cfg.ivar                = 1; 
cfg.uvar                = 2; 
statA = ft_timelockstatistics(cfg,tlckA_covcor{:},dum{:})
statV = ft_timelockstatistics(cfg,tlckV_covcor{:},dum{:})

%% source data
% Load source data
for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_sen');
    tlckAsen{k} = tmp;
end


%% Conjunction
if any(ismember(statA.label,statV.label))
    statA.stat = statA.stat(ismember(statA.label,statV.label),:);
    statA.prob = statA.prob(ismember(statA.label,statV.label),:);
    statA.mask = statA.mask(ismember(statA.label,statV.label),:);
    statA.label = statA.label(ismember(statA.label,statV.label),:);
    
    statV.stat = statV.stat(ismember(statV.label,statA.label),:);
    statV.prob = statV.prob(ismember(statV.label,statA.label),:);
    statV.mask = statV.mask(ismember(statV.label,statA.label),:);
    statV.label = statV.label(ismember(statV.label,statA.label),:);
end


cfg = [];
conj = ft_conjunctionanalysis(cfg,statA,statV)













