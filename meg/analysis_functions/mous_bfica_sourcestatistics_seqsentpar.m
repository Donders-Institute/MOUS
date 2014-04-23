function [stat, Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subj, suffix, baselineflag, cfg, rootdir, findx)

suffixstruct = isstruct(suffix);

if nargin<6
  findx = [];
end

if nargin<3
  baselineflag = 0;
end

if nargin<=3
  cfg = [];
end
cfg.correctm         = ft_getopt(cfg, 'correctm', 'cluster');
cfg.numrandomization = ft_getopt(cfg, 'numrandomization', 1000);

if strcmp(cfg.correctm, 'cluster')
  cfg.clusteralpha     = ft_getopt(cfg, 'clusteralpha', 0.005);
  cfg.clusterthreshold = ft_getopt(cfg, 'clusterthreshold', 'nonparametric_individual');
end

Nsubj   = numel(subj);
if nargin<4
    rootdir = '/project/3011020.09/jansch/';
end

[p,n,e] = fileparts(which('standard_sourcemodel3d8mm.mat'));
load([p,'/',n,e]);
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
   
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  %% sentences
  clear -regexp tlcksentpar statsentpar stat2sentpar  % for target/allword variables
  
  % select frequency
  if suffixstruct && isfield(suffix,'selfreq') 
    % Nietzsche's code uses a structure for the input argument suffix
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{1}], rootdir);
    if strcmp(suffix.avg,'no')
      statsentpar = ft_selectdata(statsentpar,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
    elseif strcmp(suffix.avg, 'yes'); % average across frequencies
      statsentpar = ft_selectdata(statsentpar,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
    end 
    statsentpar.stat = squeeze(statsentpar.stat);
    statsentpar.prob = squeeze(statsentpar.prob);
    statsentpar.mask = squeeze(statsentpar.mask);
    statsentpar.cirange = squeeze(statsentpar.cirange);
    
  else
    % JM's original code uses a cell array of strings for the input
    % argument suffix
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix{1}], rootdir);
    if isempty(findx), findx = 1; end
    
    statsentpar.stat = squeeze(statsentpar.stat(:,findx,:));
    if numel(findx)==1 && isfield(tlcksentpar, 'freq'), 
      tlcksentpar = rmfield(tlcksentpar, 'freq'); 
      statsentpar = rmfield(statsentpar, 'freq');
    end
    
  end
  
  % rename variables
  % When analysing target words (tlcksentpartar, tlckseqpartar) this avoids
  % having to create 2 scripts with identical function but diff varname.
  if exist('tlcksentpartar','var')
    tlcksentpar   = tlcksentpartar;
    statsentpar   = statsentpartar;
    stat2sentpar  = stat2sentpartar;
    clear -vars tlcksentpartar statsentpartar stat2sentpartar
  end 
   
  sourcemodel.time = tlcksentpar.time;
  if isfield(tlcksentpar, 'freq') && ndims(statsentpar.stat) == 3 
    sourcemodel.freq  = tlcksentpar.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
  
% no log transform
  sourcemodel.avg.pow = statsentpar.stat;% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  %tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.time));
  if isfield(statsentpar,'freq') && ndims(statsentpar.stat) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp; 
  dat{k}         = sourcemodel;
  dat{k}.pos     = sourcemodeltemplate.pos;
  
  %% sequences
  clear -regexp tlckseqpar statseqpar stat2seqpar
  
  
  if suffixstruct && isfield(suffix,'selfreq') 
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{2}], rootdir);
    if strcmp(suffix.avg,'no')
      statseqpar = ft_selectdata(statseqpar,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
    elseif strcmp(suffix.avg, 'yes'); % average across frequencies
      statseqpar = ft_selectdata(statseqpar,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
    end 

    statseqpar.stat = squeeze(statseqpar.stat);
    statseqpar.prob = squeeze(statseqpar.prob);
    statseqpar.mask = squeeze(statseqpar.mask);
    statseqpar.cirange = squeeze(statseqpar.cirange);
  else
    % JM's original code uses a cell array of strings for the input
    % argument suffix
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix{2}], rootdir);
    statseqpar.stat = squeeze(statseqpar.stat(:,findx,:));
    if numel(findx)==1 && isfield(tlckseqpar, 'freq'), 
      tlckseqpar = rmfield(tlckseqpar, 'freq');
      statseqpar = rmfield(statseqpar, 'freq');
    end
  end
  
  if exist('tlckseqpartar','var')
    tlckseqpar   = tlckseqpartar;
    statseqpar   = statseqpartar;
    stat2seqpar  = stat2seqpartar;
    clear -vars tlcksentpartar statsentpartar stat2sentpartar
  end 
  
  
  sourcemodel.time = tlckseqpar.time;

  sourcemodel.avg.pow = statseqpar.stat;
  if isfield(statseqpar,'freq') && ndims(statseqpar.stat) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  dat2{k}         = sourcemodel;
  dat2{k}.pos     = sourcemodeltemplate.pos;
end

% do a baseline subtraction
if baselineflag
  ix = find(dat{k}.time<=-0.1);  % define toi for baseline
  if isfield(statseqpar,'freq') && ndims(statseqpar.stat) == 3 % if 3D matrix
    for k = 1:numel(dat)
      tmp = dat{k}.avg.pow;
      
      bsl = nanmean(tmp(:,:,ix),3);
      dat{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

      tmp = dat2{k}.avg.pow;
      bsl = nanmean(tmp(:,:,ix),3);
      dat2{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)
    end
  else 
    for k = 1:numel(dat)
      tmp = dat{k}.avg.pow;
      dat{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));

      tmp = dat2{k}.avg.pow;
      dat2{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
    end
  end
end

cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';
stat = ft_sourcestatistics(cfg, dat{:}, dat2{:});  % sent = dat;  seq = dat2;


% Commented out because this functions wasn't written to take into account
% source_freq_time (e.g., 11000 x 16 x 13)
% if ndims(stat.stat)>2 %i.e. being a 3d matrix, rather than space x something else
%   stat.stat=stat.stat(:);
%   stat.prob=stat.prob(:);
%   stat.mask=stat.mask(:);
% end
% i1    = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
% iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
% imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
% for k = 1:numel(i1)
%   i1(k).coordsys = 'spm';
%   i1(k).mask = imask(k).avg.pow;
%   i1(k).prob = iprob(k).avg.pow;
% end
