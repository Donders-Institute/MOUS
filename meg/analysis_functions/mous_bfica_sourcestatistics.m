function [stat, i1, Nsubj] = mous_bfica_sourcestatistics(subj, suffix)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute statistics (source level and save results) no log10 transform

Nsubj   = numel(subj);
rootdir = '/home/language/jansch/public/mous';

load('/home/language/jansch/projects/mous/meg/templates/sourcemodel/standard_sourcemodel3d8mm');
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  clear tlcksent tlckseq
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix], rootdir);
  mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
  
  sourcemodel.time = tlckseq.time;
  sourcemodel = rmfield(sourcemodel, 'leadfield');
  if isfield(sourcemodel, 'cfg')
    sourcemodel = rmfield(sourcemodel, 'cfg');
  end
  
  % no log transform
  sourcemodel.avg.pow = (tlckseq.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.time));
  tmp(newinside,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
  
  sourcemodel.avg.pow = (tlcksent.avg);% ./ repmat(Bsent, [1 numel(tlcksent.time)]);
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.time));
  tmp(newinside,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end

cfg = [];
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.numrandomization = 1000;
cfg.parameter = 'avg.pow';
cfg.correctm  = 'cluster';
cfg.clusteralpha = 0.005;
cfg.clusterthreshold = 'nonparametric_common';
stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
if ndims(stat.stat)>2 %i.e. being a 3d matrix, rather than space x something else
  stat.stat=stat.stat(:);
  stat.prob=stat.prob(:);
  stat.mask=stat.mask(:);
end
i1    = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
i1.coordsys = 'spm';
i1.mask = imask.avg.pow;
i1.prob = iprob.avg.pow;
