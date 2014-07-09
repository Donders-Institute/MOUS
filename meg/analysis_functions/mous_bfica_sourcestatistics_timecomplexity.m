function [stattime statcomplex stattimecomp avgearlyRC avglateRC avgearlyMX avglateMX semearlyRC semlateRC semearlyMX semlateMX] = mous_bfica_sourcestatistics_timecomplexity(subj, suffix, baselineflag, cfg, rootdir)

%%% data options
% e.g., data is 'meg_bfica_sourcedatasentearlylateMX_low'
% suffix.wordtype = 'sourcedatasentearlylate'
% suffix.oscband  = 'low', 'medium', 'high'
% suffix.parcel   = '' or 'parcelavg

%%% manipulation options
% suffix.selfreq  = [min max];  Create field if want to select a specific frequency
% suffix.avg      = 'yes' or 'no';   Option to average across frequencies
% baselineflag    =  1;  % 1 = pre-word;  2 = pre-sentence

%%% statistics cfg
% cfg     = [];
% cfg.correctm            = 'cluster';
% cfg.clusterthreshold    = 'parametric';
% cfg.clusteralpha        = 0.01;
% cfg.numrandomization    = 2000;

% NL 25-06-2014

Nsubj   = numel(subj);

if nargin<3
  baselineflag = 0;
end

if nargin<=3
  cfg = [];
end

suffix.wordtype     = ft_getopt(suffix,'wordtype','sourcedatasentearlylate');

cfg.correctm         = ft_getopt(cfg, 'correctm', 'cluster');
cfg.numrandomization = ft_getopt(cfg, 'numrandomization', 1000);

if strcmp(cfg.correctm, 'cluster')
  cfg.clusteralpha     = ft_getopt(cfg, 'clusteralpha', 0.005);
  cfg.clusterthreshold = ft_getopt(cfg, 'clusterthreshold', 'nonparametric_individual');
end

if nargin<5
    rootdir = '/project/3011020.09/MEG/';
end 

% load sourcemodel
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  %% get data
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{1}], rootdir);
  tlckearlyRC = tlckearly;   tlcklateRC  = tlcklate;
  
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{2}], rootdir);
  tlckearlyMX = tlckearly;   tlcklateMX  = tlcklate;
  
  % select frequency (optional) and average across frequencies (optional)
  if isfield(suffix,'selfreq') 
    if strcmp(suffix.avg,'no')
      tlckearlyRC = ft_selectdata(tlckearlyRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      tlcklateRC = ft_selectdata(tlcklateRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      
      tlckearlyMX = ft_selectdata(tlckearlyMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      tlcklateMX = ft_selectdata(tlcklateMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      
    elseif strcmp(suffix.avg, 'yes'); % average across frequencies
      tlckearlyRC = ft_selectdata(tlckearlyRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      tlcklateRC = ft_selectdata(tlcklateRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      
      tlckearlyMX = ft_selectdata(tlckearlyMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      tlcklateMX = ft_selectdata(tlcklateMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
    end 
  end
  
  % select baseline 
  bsltoi = [-inf -0.09];
  bslearlyRC = ft_selectdata(tlckearlyRC,'toilim',bsltoi);
  bsllateRC = ft_selectdata(tlcklateRC,'toilim', bsltoi);

  bslearlyMX = ft_selectdata(tlckearlyMX,'toilim',bsltoi);
  bsllateMX = ft_selectdata(tlcklateMX,'toilim', bsltoi);
  
  
  % select time (optional)
  if isfield(suffix,'toi')
    tlckearlyRC = ft_selectdata(tlckearlyRC,'toilim',suffix.toi);
    tlcklateRC = ft_selectdata(tlcklateRC,'toilim',suffix.toi);

    tlckearlyMX = ft_selectdata(tlckearlyMX,'toilim',suffix.toi);
    tlcklateMX = ft_selectdata(tlcklateMX,'toilim',suffix.toi);
  end
  
  if isfield(suffix,'selfreq') && suffix.selfreq(1) == suffix.selfreq(2);
    tlckearlyRC.avg = squeeze(tlckearlyRC.avg);
    tlckearlyMX.avg = squeeze(tlckearlyMX.avg);
    tlcklateRC.avg = squeeze(tlcklateRC.avg);
    tlcklateMX.avg = squeeze(tlcklateMX.avg);
    
    tlckearlyRC.var = squeeze(tlckearlyRC.var);
    tlckearlyMX.var = squeeze(tlckearlyMX.var);
    tlcklateRC.var = squeeze(tlcklateRC.var);
    tlcklateMX.var = squeeze(tlcklateMX.var);
    
    bslearlyRC.avg = squeeze(bslearlyRC.avg);
    bslearlyMX.avg = squeeze(bslearlyMX.avg);
    bsllateRC.avg = squeeze(bsllateRC.avg);
    bsllateMX.avg = squeeze(bsllateMX.avg);
  end
  
    %% baseline subtraction
  if baselineflag  == 1
    if isfield(tlcklateRC,'freq') && ndims(tlcklateRC.avg) == 3     % for 3D matrix: chan_freq_time (where chan = source)
      tmp = tlckearlyRC.avg;
      tlckearlyRC.avg = tmp - repmat(nanmean(bslearlyRC.avg,3),[1,1,size(tmp,3)]); % subtract baseline (repmat)

      tmp = tlcklateRC.avg;
      tlcklateRC.avg = tmp - repmat(nanmean(bsllateRC.avg,3),[1,1,size(tmp,3)]);

      tmp = tlckearlyMX.avg;
      tlckearlyMX.avg = tmp - repmat(nanmean(bslearlyMX.avg,3),[1,1,size(tmp,3)]);

      tmp = tlcklateMX.avg;
      tlcklateMX.avg = tmp - repmat(nanmean(bsllateMX.avg,3),[1,1,size(tmp,3)]);       
    else                          % for 2D matrix: chan_time  (single freq)
      tmp = tlckearlyRC.avg;
      tlckearlyRC.avg = tmp - nanmean(bslearlyRC.avg,2)*ones(1,size(tmp,2));

      tmp = tlcklateRC.avg;
      tlcklateRC.avg  = tmp - nanmean(bsllateRC.avg,2)*ones(1,size(tmp,2));

      tmp = tlckearlyMX.avg;
      tlckearlyMX.avg = tmp - nanmean(bslearlyMX.avg,2)*ones(1,size(tmp,2));

      tmp = tlcklateMX.avg;
      tlcklateMX.avg  = tmp - nanmean(bsllateMX.avg,2)*ones(1,size(tmp,2));
    end
  end


  %% update dimord
  sourcemodel.time = tlcklateRC.time;  
  if isfield(tlcklateRC, 'freq') && ndims(tlcklateRC.avg) == 3 % this dimord is wrong for stats on only 1 freq (selected from matrix of source x freq x time)
    sourcemodel.freq  = tlcklateRC.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
  
  %% create data structure for statistics (no log transform)
  % earlyRC
  sourcemodel.avg.pow = (tlckearlyRC.avg);  % assume all tlck structures same size
  if isfield(tlcklateRC,'freq') && ndims(tlcklateRC.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  earlyRC{k}          = sourcemodel;
  earlyRC{k}.pos      = sourcemodeltemplate.pos;
 
  % lateRC
  sourcemodel.avg.pow = (tlcklateRC.avg); % assume all tlck structures same size
  if isfield(tlcklateRC,'freq') && ndims(tlcklateRC.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  lateRC{k}            = sourcemodel;
  lateRC{k}.pos         = sourcemodeltemplate.pos;
    
   % earlyMX
  sourcemodel.avg.pow = (tlckearlyMX.avg); % assume all tlck structures same size
  if isfield(tlcklateRC,'freq') && ndims(tlcklateRC.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  earlyMX{k}          = sourcemodel;
  earlyMX{k}.pos      = sourcemodeltemplate.pos;
 
  % lateMX
  sourcemodel.avg.pow = (tlcklateMX.avg); 
  if isfield(tlcklateRC,'freq') && ndims(tlcklateRC.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  lateMX{k}           = sourcemodel;
  lateMX{k}.pos       = sourcemodeltemplate.pos;
end

%% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    sumearlyRC = earlyRC{k}.avg.pow;
    sumlateRC  = lateRC{k}.avg.pow;
    ssqearlyRC = earlyRC{k}.avg.pow.^2;
    ssqlateRC  = lateRC{k}.avg.pow.^2;
    allinside = earlyRC{k}.inside;
    
    sumearlyMX = earlyMX{k}.avg.pow;
    sumlateMX  = lateMX{k}.avg.pow;
    ssqearlyMX = earlyMX{k}.avg.pow.^2;
    ssqlateMX  = lateMX{k}.avg.pow.^2;
  else
    sumearlyRC = sumearlyRC + earlyRC{k}.avg.pow;
    sumlateRC  = sumlateRC  + lateRC{k}.avg.pow;
    ssqearlyRC = ssqearlyRC + earlyRC{k}.avg.pow.^2;
    ssqlateRC  = ssqlateRC  + lateRC{k}.avg.pow.^2;
    allinside = intersect(allinside, earlyRC{k}.inside);
    
    sumearlyMX = sumearlyMX + earlyMX{k}.avg.pow;
    sumlateMX  = sumlateMX  + lateMX{k}.avg.pow;
    ssqearlyMX = ssqearlyMX + earlyMX{k}.avg.pow.^2;
    ssqlateMX  = ssqlateMX  + lateMX{k}.avg.pow.^2;
%     allinside = intersect(allinside, sent{k}.inside);
  end  
end
alloutside = setdiff(1:size(earlyRC{1}.pos,1), allinside);

for k = 1:Nsubj
  earlyRC{k}.inside = allinside(:)';
  earlyRC{k}.outside = alloutside(:)';
  lateRC{k}.inside  = allinside(:)';
  lateRC{k}.outside = alloutside(:)';
  
  earlyMX{k}.inside = allinside(:)';
  earlyMX{k}.outside = alloutside(:)';
  lateMX{k}.inside  = allinside(:)';
  lateMX{k}.outside = alloutside(:)';
end

% compute mean per condition and sem
avgearlyRC = sumearlyRC./Nsubj;
varearlyRC = (ssqearlyRC - sumearlyRC.^2./Nsubj)./(Nsubj-1);
semearlyRC = sqrt(varearlyRC./Nsubj);

avglateRC = sumlateRC./Nsubj;
varlateRC = (ssqlateRC - sumlateRC.^2./Nsubj)./(Nsubj-1);
semlateRC = sqrt(varlateRC./Nsubj);

avgearlyMX  = sumearlyMX./Nsubj;
varearlyMX = (ssqearlyMX - sumearlyMX.^2./Nsubj)./(Nsubj-1);
semearlyMX  = sqrt(varearlyMX./Nsubj);

avglateMX  = sumlateMX./Nsubj;
varlateMX  = (ssqlateMX - sumlateMX.^2./Nsubj)./(Nsubj-1);
semlateMX  = sqrt(varlateMX./Nsubj);

%% collapse levels between factors to test for effects 
% (1) earlyMX + lateRC   (2) lateMX + earlyRC
for k = 1:numel(subj)
  emxlrc{k} = earlyMX{k};
  emxlrc{k}.avg.pow = earlyMX{k}.avg.pow + lateRC{k}.avg.pow;

  lmxerc{k} = lateMX{k};
  lmxerc{k}.avg.pow = lateMX{k}.avg.pow + earlyRC{k}.avg.pow;

  early{k} = earlyMX{k};
  early{k}.avg.pow = earlyMX{k}.avg.pow + earlyRC{k}.avg.pow;

  late{k}  = lateMX{k};
  late{k}.avg.pow = lateMX{k}.avg.pow + lateRC{k}.avg.pow;

  rc{k} = earlyRC{k};
  rc{k}.avg.pow = earlyRC{k}.avg.pow + lateRC{k}.avg.pow;

  mx{k} = earlyMX{k};
  mx{k}.avg.pow = earlyMX{k}.avg.pow + lateMX{k}.avg.pow;
end
%% stats
% cfg = [ ];  % keep cfg from inarg
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';

cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
stattimecomp = ft_sourcestatistics(cfg,emxlrc{:}, lmxerc{:});

cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
stattime = ft_sourcestatistics(cfg,early{:}, late{:});

cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
statcomplex = ft_sourcestatistics(cfg,rc{:}, mx{:});

%% stats2 

% cfg.statistic='anova2x2rm';
% cfg.design;
% cfg.design=[ones(1,Nsubj*2) 2*ones(1,Nsubj*2);ones(1,Nsubj) 2*ones(1,Nsubj) ones(1,Nsubj) 2*ones(1,Nsubj);repmat(1:Nsubj,[1 4])];
% cfg.ivar=[1 2];
% cfg.uvar=3;
% cfg.f='interaction';
% cfg.numrandomization=0;
% stat=ft_sourcestatistics(cfg,earlyRC{:},earlyMX{:},lateRC{:},lateMX{:});

