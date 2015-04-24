function [statSvWL, statsenEvL, statwlEvL,...
          avgearlysen, avglatesen, avgearlywl, avglatewl,...
          semearlysen, semlatesen, semearlywl, semlatewl] = mous_bfica_sourcestatistics_SevlWevl(subj, suffix, baselineflag, cfg, rootdir)
% mous_bfica_sourcestatistics_SevlWevl compares 
% Sentence(early-late words) vs. Word lists (early-late words) in
% volumetric space (Beamformer output)
        
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

suffix.wordtype     = ft_getopt(suffix,'wordtype',[]); 

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
  tlckearlysen = tlckearly;   tlcklatesen  = tlcklate;
  
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{2}], rootdir);
  tlckearlywl = tlckearly;   tlcklatewl  = tlcklate;
  
  % select frequency (optional) and average across frequencies (optional)
  if isfield(suffix,'selfreq') 
    if strcmp(suffix.favg,'no')
      tlckearlysen = ft_selectdata(tlckearlysen,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      tlcklatesen  = ft_selectdata(tlcklatesen, 'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      
      tlckearlywl  = ft_selectdata(tlckearlywl,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      tlcklatewl  = ft_selectdata(tlcklatewl,  'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      
    elseif strcmp(suffix.favg, 'yes'); % average across frequencies
      tlckearlysen = ft_selectdata(tlckearlysen,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      tlcklatesen  = ft_selectdata(tlcklatesen, 'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      
      tlckearlywl  = ft_selectdata(tlckearlywl,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      tlcklatewl   = ft_selectdata(tlcklatewl, 'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
    end 
  end
  
  %% prestim
  bsltoi = [-inf -0.09];
  bslearlysen = ft_selectdata(tlckearlysen,'toilim',bsltoi);
  bsllatesen  = ft_selectdata(tlcklatesen,'toilim', bsltoi);

  bslearlywl  = ft_selectdata(tlckearlywl,'toilim',bsltoi);
  bsllatewl   = ft_selectdata(tlcklatewl,'toilim', bsltoi);
  
  
  %% poststim
  if isfield(suffix,'toi')
    tlckearlysen = ft_selectdata(tlckearlysen,'toilim',suffix.toi);
    tlcklatesen  = ft_selectdata(tlcklatesen,'toilim',suffix.toi);

    tlckearlywl  = ft_selectdata(tlckearlywl,'toilim',suffix.toi);
    tlcklatewl   = ft_selectdata(tlcklatewl,'toilim',suffix.toi);
  end
  
  %% squeeze data 
  if isfield(suffix,'selfreq') && (suffix.selfreq(1) == suffix.selfreq(2) || strcmp(suffix.favg,'yes'))
    tlckearlysen.avg = squeeze(tlckearlysen.avg);
    tlckearlywl.avg  = squeeze(tlckearlywl.avg);
    tlcklatesen.avg  = squeeze(tlcklatesen.avg);
    tlcklatewl.avg   = squeeze(tlcklatewl.avg);
    
    tlckearlysen.var = squeeze(tlckearlysen.var);
    tlckearlywl.var  = squeeze(tlckearlywl.var);
    tlcklatesen.var  = squeeze(tlcklatesen.var);
    tlcklatewl.var   = squeeze(tlcklatewl.var);
    
    bslearlysen.avg  = squeeze(bslearlysen.avg);
    bslearlywl.avg   = squeeze(bslearlywl.avg);
    bsllatesen.avg   = squeeze(bsllatesen.avg);
    bsllatewl.avg    = squeeze(bsllatewl.avg);
  end
  
  %% baseline 
  
  % absolute (subtraction)
  if baselineflag  == 1
    if isfield(tlcklatesen,'freq') && ndims(tlcklatesen.avg) == 3     % for 3D matrix: chan_freq_time (where chan = source)
      tmp = tlckearlysen.avg;
      tlckearlysen.avg = tmp - repmat(nanmean(bslearlysen.avg,3),[1,1,size(tmp,3)]); % subtract baseline (repmat)

      tmp = tlcklatesen.avg;
      tlcklatesen.avg  = tmp - repmat(nanmean(bsllatesen.avg,3),[1,1,size(tmp,3)]);

      tmp = tlckearlywl.avg;
      tlckearlywl.avg  = tmp - repmat(nanmean(bslearlywl.avg,3),[1,1,size(tmp,3)]);

      tmp = tlcklatewl.avg;
      tlcklatewl.avg   = tmp - repmat(nanmean(bsllatewl.avg,3),[1,1,size(tmp,3)]);       
    else                          % for 2D matrix: chan_time  (single freq)
      if strcmp(suffix.bsl,'indabs') % subtract baseline
        tmp = tlckearlysen.avg;
        tlckearlysen.avg = tmp - nanmean(bslearlysen.avg,2)*ones(1,size(tmp,2));

        tmp = tlcklatesen.avg;
        tlcklatesen.avg  = tmp - nanmean(bsllatesen.avg,2)*ones(1,size(tmp,2));

        tmp = tlckearlywl.avg;
        tlckearlywl.avg  = tmp - nanmean(bslearlywl.avg,2)*ones(1,size(tmp,2));

        tmp = tlcklatewl.avg;
        tlcklatewl.avg   = tmp - nanmean(bsllatewl.avg,2)*ones(1,size(tmp,2));
        
      elseif strcmp(suffix.bsl,'comabs')
        tmp1 = nanmean(bslearlysen.avg,2);    tmp2 = nanmean(bsllatesen.avg,2);
        tmp3 = nanmean(bslearlywl.avg,2);     tmp4 = nanmean(bsllatewl.avg,2);
        bsl  = (tmp1+tmp2+tmp3+tmp4)/4;
        
        tmp  = tlckearlysen.avg;
        tlckearlysen.avg = tmp - bsl*ones(1,size(tmp,2));
        
        tmp  = tlcklatesen.avg;
        tlcklatesen.avg  = tmp - bsl*ones(1,size(tmp,2));
        
        tmp  = tlckearlywl.avg;
        tlckearlywl.avg  = tmp - bsl*ones(1,size(tmp,2));
        
        tmp  = tlcklatewl.avg;
        tlcklatewl.avg   = tmp - bsl*ones(1,size(tmp,2));
      end
    end
  end
    
  %% update dimord
  sourcemodel.time = tlcklatesen.time;  
  if isfield(tlcklatesen, 'freq') && ndims(tlcklatesen.avg) == 3 % this dimord is wrong for stats on only 1 freq (selected from matrix of source x freq x time)
    sourcemodel.freq  = tlcklatesen.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
  
  %% create data structure for statistics (no log transform)
  % CHANGEME: limit sourcemodel.inside for statistics?
  
  % earlySEN
  sourcemodel.avg.pow = (tlckearlysen.avg);  % assume all tlck structures same size
  if isfield(tlcklatesen,'freq') && ndims(tlcklatesen.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  earlysen{k}         = sourcemodel;
  earlysen{k}.pos     = sourcemodeltemplate.pos;
 
  % lateSEN
  sourcemodel.avg.pow = (tlcklatesen.avg); % assume all tlck structures same size
  if isfield(tlcklatesen,'freq') && ndims(tlcklatesen.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  latesen{k}          = sourcemodel;
  latesen{k}.pos      = sourcemodeltemplate.pos;
    
   % earlyWL
  sourcemodel.avg.pow = (tlckearlywl.avg); % assume all tlck structures same size
  if isfield(tlcklatesen,'freq') && ndims(tlcklatesen.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  earlywl{k}          = sourcemodel;
  earlywl{k}.pos      = sourcemodeltemplate.pos;
 
  % lateWL
  sourcemodel.avg.pow = (tlcklatewl.avg); 
  if isfield(tlcklatesen,'freq') && ndims(tlcklatesen.avg) == 3
    tmp               = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp               = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  latewl{k}           = sourcemodel;
  latewl{k}.pos       = sourcemodeltemplate.pos;
end

%% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    sumearlysen = earlysen{k}.avg.pow;
    sumlatesen  = latesen{k}.avg.pow;
    ssqearlysen = earlysen{k}.avg.pow.^2;
    ssqlatesen  = latesen{k}.avg.pow.^2;
    allinside   = earlysen{k}.inside;
    
    sumearlywl  = earlywl{k}.avg.pow;
    sumlatewl   = latewl{k}.avg.pow;
    ssqearlywl  = earlywl{k}.avg.pow.^2;
    ssqlatewl   = latewl{k}.avg.pow.^2;
  else
    sumearlysen = sumearlysen + earlysen{k}.avg.pow;
    sumlatesen  = sumlatesen  + latesen{k}.avg.pow;
    ssqearlysen = ssqearlysen + earlysen{k}.avg.pow.^2;
    ssqlatesen  = ssqlatesen  + latesen{k}.avg.pow.^2;
    allinside   = intersect(allinside, earlysen{k}.inside);
    
    sumearlywl  = sumearlywl + earlywl{k}.avg.pow;
    sumlatewl   = sumlatewl  + latewl{k}.avg.pow;
    ssqearlywl  = ssqearlywl + earlywl{k}.avg.pow.^2;
    ssqlatewl   = ssqlatewl  + latewl{k}.avg.pow.^2;
  end  
end
alloutside = setdiff(1:size(earlysen{1}.pos,1), allinside);

for k = 1:Nsubj
  earlysen{k}.inside  = allinside(:)';
  earlysen{k}.outside = alloutside(:)';
  latesen{k}.inside   = allinside(:)';
  latesen{k}.outside  = alloutside(:)';
  
  earlywl{k}.inside   = allinside(:)';
  earlywl{k}.outside  = alloutside(:)';
  latewl{k}.inside    = allinside(:)';
  latewl{k}.outside   = alloutside(:)';
end

% compute mean per condition and sem
avgearlysen = sumearlysen./Nsubj;
varearlysen = (ssqearlysen - sumearlysen.^2./Nsubj)./(Nsubj-1);
semearlysen = sqrt(varearlysen./Nsubj);

avglatesen  = sumlatesen./Nsubj;
varlatesen  = (ssqlatesen - sumlatesen.^2./Nsubj)./(Nsubj-1);
semlatesen  = sqrt(varlatesen./Nsubj);

avgearlywl  = sumearlywl./Nsubj;
varearlywl  = (ssqearlywl - sumearlywl.^2./Nsubj)./(Nsubj-1);
semearlywl  = sqrt(varearlywl./Nsubj);

avglatewl   = sumlatewl./Nsubj;
varlatewl   = (ssqlatewl - sumlatewl.^2./Nsubj)./(Nsubj-1);
semlatewl   = sqrt(varlatewl./Nsubj);

%% statistics
for k = 1:numel(subj)
  senEvL{k}          = earlysen{k};
  senEvL{k}.avg.pow  = earlysen{k}.avg.pow - latesen{k}.avg.pow;

  wlEvL{k}           = earlywl{k};
  wlEvL{k}.avg.pow   = earlywl{k}.avg.pow  - latewl{k}.avg.pow;
end

% cfg = [ ];  % keep cfg from inarg
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.ivar      = 1;
cfg.uvar      = 2;
cfg.parameter = 'avg.pow';

cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
statSvWL      = ft_sourcestatistics(cfg, senEvL{:}, wlEvL{:});

cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
statsenEvL    = ft_sourcestatistics(cfg, latesen{:},earlysen{:});

cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
statwlEvL     = ft_sourcestatistics(cfg, latewl{:},earlywl{:});

