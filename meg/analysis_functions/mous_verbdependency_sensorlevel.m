function mous_verbdependency_sensorlevel(frequency,trials)
%% compute sensor-level dependency analysis

% subjlist
[subj,~] = mous_db_getfilename('allV','subjectname');
% get stimuli
load('/home/language/nielam/MOUS/meg/trialfun/mous_stimuli');

numtrlpercdtn = zeros(102,2);

% load data and select trials
for m = 1:numel(subj)
  mous_db_getdata(subj{m},['meg_bfica_freq_',frequency],'/project/3011020.09/MEG')
  freq = ft_struct2double(freq);
  
  % create unique ID for each trial
  freq.trialinfo(:,7) = freq.trialinfo(:,6)*100 + freq.trialinfo(:,5); 
  trialinfo = freq.trialinfo;
   
%   % get RC sentences
%   sel  = find(ismember(trialinfo(:,2),[1 2]));  
%   expRC = trialinfo(sel,:);
  
  % get all sentences instead - 20-02-2015
  % FIXME: run 02-04 to get a distribution of distance between verbs and
  % subj
  sel   = find(ismember(trialinfo(:,2),[1 2 5 6]));
  expRC = trialinfo(sel,:);
  
  % get verbs in RC sentences
  uq      = unique(expRC(:,6));
  for k = 1:numel(uq)
    pstn(k) = stimuli(uq(k)).id*100 + stimuli(uq(k)).verb2subjMC;
  end
  idx    = find(ismember(expRC(:,7),pstn)); % some of allsubjRC may not be in expRC due to artifact rejection
  verb   = expRC(idx,:);
  
  %% remove RC sentences that ~senttype = [0 0 0 0] 
  senttype = [stimuli(verb(:,6)).sentencetype];   % get senttype for remaining RC sentences
  senttype = reshape(senttype,[4,size(verb,1)])'; 
  i = any(senttype,2);                            % identify special senttype
  verb = verb(~i,:);               % remove special senttype

  %% verb's subject position (column8) verb-subject distance (column9)
  for q = 1:size(verb,1)
    senid  = verb(q,6);
    verb(q,8) = stimuli(senid).subjMC;  
    verb(q,9) = verb(q,5)-verb(q,8);
  end
  
  %% split verbs into short and long dependency
  sn      = str2double(subj{m}(2:end));  % get randomseed value for subject
  
  tmp1    = find(ismember(verb(:,9),  trials{1}));  % can't use position '1' because some subjects only have 1 trials -> no crssspctra
  tmp2    = find(ismember(verb(:,9),  trials{2}));  % dependency of >= 3 word positions
  minnum  = min(numel(tmp1),numel(tmp2));
  
  if minnum ~= numel(tmp1)
    randomseed(sn); 
    tmp1         = datasample(tmp1, minnum, 'Replace', false);
  elseif minnum ~= numel(tmp2)
    randomseed(sn);
    tmp2         = datasample(tmp2, minnum, 'Replace', false);    
  end
  
  verblongdep = verb(tmp2,:);
  verbshrtdep = verb(tmp1,:);

  numtrlpercdtn(m,1) = numel(tmp1);
  numtrlpercdtn(m,2) = numel(tmp2);
%% match to original dataset
% index of each trial from each condition in original (full) dataset
[c,sel1] = intersect(freq.trialinfo(:,7),  verbshrtdep(:,7));       
[c,sel2] = intersect(freq.trialinfo(:,7),  verblongdep(:,7));
  
%% bsl and data time points
if strcmp(frequency,'low')
  bsltoi = 1;
  dattoi = 2;
  latency = [-0.1 0.5];
elseif strcmp(frequency,'medium') || strcmp(frequency,'high')
  bsltoi = 1:2;
  dattoi = 3;
  latency = [-0.15 0.5];
end

%% convert to planar gradient and then compute powspctrm
%  conversion only works if data is in format of fourier coefficients
cfg = [];
cfg.method       = 'template';
cfg.neighbours   = ft_prepare_neighbours(cfg,freq);
cfg.planarmethod = 'sincos';
cfg.trials = sel1;
freq1  = ft_megplanar(cfg,freq);

cfg         = [];
cfg.latency = latency;
freq1  = ft_freqdescriptives(cfg,freq1); % short
freq1  = ft_combineplanar([],freq1);


cfg = [];
cfg.method       = 'template';
cfg.neighbours   = ft_prepare_neighbours(cfg,freq);
cfg.planarmethod = 'sincos';
cfg.trials = sel2;
freq2  = ft_megplanar(cfg,freq);

cfg           = [];
cfg.latency   = latency;
freq2  = ft_freqdescriptives(cfg,freq2); % long
freq2  = ft_combineplanar([],freq2);


%% create data structure for statistics
freqshrt{m} = freq1;
freqlong{m} = freq2;
 
end

%% individual condition baseline subtraction
for m = 1:numel(subj)
  freqshrt2{m} = freqshrt{m};
  freqshrt2{m}.powspctrm = freqshrt{m}.powspctrm(:,:,:) - repmat(mean(freqshrt{m}.powspctrm(:,:,bsltoi),3),[1,1,numel(freqshrt{m}.time)]);
  
  freqlong2{m} = freqlong{m};
  freqlong2{m}.powspctrm = freqlong{m}.powspctrm(:,:,:) - repmat(mean(freqlong{m}.powspctrm(:,:,bsltoi),3),[1,1,numel(freqlong{m}.time)]);
end

%% condition common baseline subtraction
%  trials are balanced between conditions 
%  don't need extra code to do a weighted-common baseline
for m = 1:numel(subj)
  bslcom = (freqshrt{m}.powspctrm(:,:,bsltoi) + freqlong{m}.powspctrm(:,:,bsltoi))/2;
  freqshrt3{m} = freqshrt{m};
  freqshrt3{m}.powspctrm = freqshrt{m}.powspctrm(:,:,:) - repmat(mean(bslcom,3),[1,1,numel(freqshrt{m}.time)]);
  
  freqlong3{m} = freqlong{m};
  freqlong3{m}.powspctrm = freqlong{m}.powspctrm(:,:,:) - repmat(mean(bslcom,3),[1,1,numel(freqlong{m}.time)]);
end


%% group mean
cfg           = [];
cfg.parameter = 'powspctrm'; 
cfg.appenddim = 'rpt';      % fool ft_appendfreq
shrtavg  = ft_appendfreq(cfg,freqshrt{:});
longavg  = ft_appendfreq(cfg,freqlong{:});

% average data using ft_selectdata
cfg            = [];
cfg.avgoverrpt = 'yes';
shrtavg        = ft_selectdata(cfg,shrtavg);
longavg        = ft_selectdata(cfg,longavg);

%% group mean w/ bsl corrected
cfg           = [];
cfg.parameter = 'powspctrm'; 
cfg.appenddim = 'rpt';      % fool ft_appendfreq
shrtavg2  = ft_appendfreq(cfg,freqshrt2{:});
longavg2  = ft_appendfreq(cfg,freqlong2{:});

% average data using ft_selectdata
cfg            = [];
cfg.avgoverrpt = 'yes';
shrtavg2       = ft_selectdata(cfg,shrtavg2);
longavg2       = ft_selectdata(cfg,longavg2);

%% group mean w/ common-bsl corrected
cfg           = [];
cfg.parameter = 'powspctrm'; 
cfg.appenddim = 'rpt';      % fool ft_appendfreq
shrtavg3  = ft_appendfreq(cfg,freqshrt3{:});
longavg3  = ft_appendfreq(cfg,freqlong3{:});

% average data using ft_selectdata
cfg            = [];
cfg.avgoverrpt = 'yes';
shrtavg3       = ft_selectdata(cfg,shrtavg3);
longavg3       = ft_selectdata(cfg,longavg3);


%% statistics
nsubj=numel(subj);
cfg2 = [];
cfg2.numrandomization  = 2000;
cfg2.method            = 'montecarlo';
cfg2.parameter         = 'powspctrm';
cfg2.frequency         = 'all'; % [2.5 7.5]?
cfg2.statistic         = 'depsamplesT';
cfg2.correctm          = 'max';
cfg2.correcttail       = 'alpha';
cfg2.clusterthreshold  = 'nonparametric_common';
cfg2.clusterstatistics = 'maxsum';
cfg2_neighb.method     = 'distance';
cfg2.neighbours        = ft_prepare_neighbours(cfg2_neighb,freqshrt{1}); 
cfg2.ivar        = 1;      % 1st row in cfg2.design
cfg2.uvar        = 2;      % 2nd row in cfg2.design
                  % 1's          2's              1:102   1:102
cfg2.design     = [ones(1,nsubj) ones(1,nsubj)*2; 1:nsubj 1:nsubj];
cfg2.latency    = [0 0.5];
stat            = ft_freqstatistics(cfg2,  freqshrt{:}, freqlong{:});
statbsl         = ft_freqstatistics(cfg2, freqshrt2{:},freqlong2{:});
statcommon      = ft_freqstatistics(cfg2, freqshrt3{:},freqlong3{:});

if numel(trials{1}) > 1
  ts = [num2str(trials{1}(1)),'-',num2str(trials{1}(end)),'short'];
else
  ts = [num2str(trials{1}),'short'];
end

if numel(trials{2}) > 1
  tl = [num2str(trials{2}(1)),'-',num2str(trials{2}(end)),'long'];
else
  tl = [num2str(trials{2}),'long'];
end

save(['/project/3011020.09/nielam/groupresults/dependency/verbsubjdependency_',frequency,'Hz',...
      '_bslnon',ts,tl,'_',num2str(nsubj),'subj'],'stat','shrtavg','longavg');
    
save(['/project/3011020.09/nielam/groupresults/dependency/verbsubjdependency_',frequency,'Hz',...
      '_bslspc',ts,tl,'_',num2str(nsubj),'subj'],'statbsl','shrtavg2','longavg2');
    
save(['/project/3011020.09/nielam/groupresults/dependency/verbsubjdependency_',frequency,'Hz',...
      '_bslcom',ts,tl,'_',num2str(nsubj),'subj'],'statcommon','shrtavg3','longavg3');

