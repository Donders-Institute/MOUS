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
     tmp = mous_db_getdata(subjA{k},'meg_erf_seq_chopped');
     tlckAseq{k} = tmp;
    tmp = mous_db_getdata(subjA{k},'meg_erf_bslchopped');
    tlckAbsl{k} = tmp;
%     tmp = mous_db_getdata(subjV{k},'meg_erf_seq_chopped');
%     tlckVseq{k} = tmp;
%     tmp = mous_db_getdata(subjV{k},'meg_erf_bslchopped');
%     tlckVbsl{k} = tmp;
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
%% Or load in pre-sentence bsl per subject (axial only)
% for k = 1:Nsubj
%     tmp = mous_db_getdata(subjA{k},'meg_erf_bslchopped');
%     tlckAbsl{k} = tmp;
%      tmp = mous_db_getdata(subjV{k},'meg_erf_bslchopped');
%      tlckVbsl{k} = tmp;
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
%allVbsl = ft_appendtimelock(cfg,tlckVbsl{:});
allVseq = ft_appendtimelock(cfg,tlckVseq{:});
allVsen = ft_appendtimelock(cfg,tlckVsen{:});
allAbsl = ft_appendtimelock(cfg,tlckAbsl{:});
allAseq = ft_appendtimelock(cfg,tlckAseq{:});
allAsen = ft_appendtimelock(cfg,tlckAsen{:});


cfg = [];
cfg.avgoverrpt = 'yes';
cfg.channel = {'MEG'};
% avgVbsl= ft_selectdata(cfg,allVbsl);
avgVseq = ft_selectdata(cfg,allVseq);
avgVsen = ft_selectdata(cfg,allVsen);
avgAbsl= ft_selectdata(cfg,allAbsl);
avgAseq = ft_selectdata(cfg,allAseq);
avgAsen = ft_selectdata(cfg,allAsen);


% Visualize
cfgp = [];
cfgp.layout = 'CTF275_helmet.mat';
cfgp.parameter = 'trial';
figure;ft_topoplotER(cfgp,avgAsen,avgAseq)
figure;ft_topoplotER(cfgp,avgfrst)


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
load cortex_inflated_8196reg
for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_bsl');
    source{k} = tmp;
    source{k}.cfg = rmfield(source{k}.cfg,'previous');
    source{k}.avg = rmfield(source{k}.avg,'dspm');
end

for k = 1:Nsubj
    source{k}.pos = sourcemodel.pnt;
    source{k}.tri = sourcemodel.tri;
end

cfg = [];
cfg.parameter = 'pow';
sourceGA = ft_sourcegrandaverage(cfg,source{:});
sVbsl = sourceGA;
% stats
for k = 1:Nsubj
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_seq');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    seq{k} = tmp;
    tmp = mous_db_getdata(subjA{k},'meg_mne_conjunction_bsl');
    tmp.cfg = rmfield(tmp.cfg,'previous');
    tmp.pos = sourcemodel.pnt;
    tmp.tri = sourcemodel.tri;
    bsl{k} = tmp;
    bsl{k}.time = seq{k}.time;
end

cfg = [];
cfg.parameter = 'dspm';
sAseq = ft_sourcegrandaverage(cfg,seq{:});
sAbsl = ft_sourcegrandaverage(cfg,bsl{:});
save('mne_ga_auditory','sAseq','sAbsl')

cfg = [];
cfg.parameter   = 'dspm';
cfg.method      = 'analytic';
cfg.statistic   = 'ft_statfun_depsamplesT'
cfg.alpha       = 0.05;
cfg.correctm    = 'bonferroni';
cfg.design(1,1:2*Nsubj)  = [ones(1,Nsubj) 2*ones(1,Nsubj)];
cfg.design(2,1:2*Nsubj)  = [1:Nsubj 1:Nsubj];
cfg.ivar                = 1; 
cfg.uvar                = 2; 

statAdspm = ft_sourcestatistics(cfg,seq{:},bsl{:})
  
%% Conjunction
% if any(ismember(statA.label,statV.label))
%     statA.stat = statA.stat(ismember(statA.label,statV.label),:);
%     statA.prob = statA.prob(ismember(statA.label,statV.label),:);
%     statA.mask = statA.mask(ismember(statA.label,statV.label),:);
%     statA.label = statA.label(ismember(statA.label,statV.label),:);
%     
%     statV.stat = statV.stat(ismember(statV.label,statA.label),:);
%     statV.prob = statV.prob(ismember(statV.label,statA.label),:);
%     statV.mask = statV.mask(ismember(statV.label,statA.label),:);
%     statV.label = statV.label(ismember(statV.label,statA.label),:);
% end


cfg = [];
conj = ft_conjunctionanalysis(cfg,statAdspm,statVdspm)













