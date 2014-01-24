function [stat, i1, Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subj, suffix, baselineflag, cfg)

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
rootdir = '/home/language/jansch/public/mous';

load('/home/language/jansch/projects/mous/meg/templates/sourcemodel/standard_sourcemodel3d8mm');
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  clear tlcksentpar statsentpar stat2sentpar
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix{1}], rootdir);
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  sourcemodel.time = tlcksentpar.time;
  
  % no log transform
  sourcemodel.avg.pow = statsentpar.stat;% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.time));
  tmp(newinside,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  dat{k}         = sourcemodel;
  dat{k}.pos     = sourcemodeltemplate.pos;
  
  clear tlcksqtpar statseqpar stat2seqpar
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix{2}], rootdir);
  
  sourcemodel.time = statseqpar.time;
  
  % no log transform
  sourcemodel.avg.pow = statseqpar.stat;% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.time));
  tmp(newinside,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  dat2{k}         = sourcemodel;
  dat2{k}.pos     = sourcemodeltemplate.pos;
  
end

% do a baseline subtraction
if baselineflag
  ix = find(dat{k}.time<=0.1);
  for k = 1:numel(dat)
    tmp = dat{k}.avg.pow;
    dat{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
    tmp = dat2{k}.avg.pow;
    dat2{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
  end
end

%cfg = [];
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
%cfg.numrandomization = 1000;
cfg.parameter = 'avg.pow';
stat = ft_sourcestatistics(cfg, dat{:}, dat2{:});
if ndims(stat.stat)>2 %i.e. being a 3d matrix, rather than space x something else
  stat.stat=stat.stat(:);
  stat.prob=stat.prob(:);
  stat.mask=stat.mask(:);
end
i1    = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
for k = 1:numel(i1)
  i1(k).coordsys = 'spm';
  i1(k).mask = imask(k).avg.pow;
  i1(k).prob = iprob(k).avg.pow;
end
