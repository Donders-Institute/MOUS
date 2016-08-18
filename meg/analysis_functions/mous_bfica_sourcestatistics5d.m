function [stat, i1, Nsubj, avgsent, avgseq, semsent, semseq] = mous_bfica_sourcestatistics5d(subj, str, baselineflag)

if nargin<3
  baselineflag = 0;
end

Nsubj   = numel(subj);
rootdir = '/home/language/jansch/public/mous';

load('/home/language/jansch/projects/mous/meg/templates/sourcemodel/standard_sourcemodel3d8mm');
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  clear tlcksent tlckseq datsent datseq sourcemodel
  mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
  for m = 1:numel(str)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq',str{m}], rootdir);
    datsent(:,:,m) = tlcksent.avg;
    datseq(:,:,m)  = tlckseq.avg;
  end
  datsent = permute(datsent, [1 3 2]);
  datseq  = permute(datseq,  [1 3 2]);
  
  sourcemodel.time = tlckseq.time;
  sourcemodel.freq = 1:size(datsent, 2);
  sourcemodel = rmfield(sourcemodel, 'leadfield');
  if isfield(sourcemodel, 'cfg')
    sourcemodel = rmfield(sourcemodel, 'cfg');
  end
  
  sourcemodel.avg.pow = datseq;
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.freq), numel(sourcemodel.time));
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
  
  sourcemodel.avg.pow = datsent;
  tmp                 = zeros(prod(sourcemodel.dim), numel(sourcemodel.freq), numel(sourcemodel.time));
  tmp(newinside,:,:)  = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end

% do a baseline subtraction
if baselineflag
  ix = find(sent{k}.time<=0);
  for k = 1:numel(sent)
    tmp = sent{k}.avg.pow;
    sent{k}.avg.pow = tmp - repmat(nanmean(tmp(:,:,ix),3),[1,1,size(tmp,3)]);
    tmp = seq{k}.avg.pow;
    seq{k}.avg.pow = tmp - repmat(nanmean(tmp(:,:,ix),3),[1,1,size(tmp,3)]);
  end
end
  
% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    sumsent = sent{k}.avg.pow;
    sumseq  = seq{k}.avg.pow;
    ssqsent = sent{k}.avg.pow.^2;
    ssqseq  = seq{k}.avg.pow.^2;
    allinside = sent{k}.inside;
  else
    sumsent = sumsent + sent{k}.avg.pow;
    sumseq  = sumseq  + seq{k}.avg.pow;
    ssqsent = ssqsent + sent{k}.avg.pow.^2;
    ssqseq  = ssqseq  + seq{k}.avg.pow.^2;
    allinside = intersect(allinside, sent{k}.inside);
  end  
end
alloutside = setdiff(1:size(sent{1}.pos,1), allinside);
for k = 1:Nsubj
  sent{k}.inside = allinside(:)';
  sent{k}.outside = alloutside(:)';
  seq{k}.inside  = allinside(:)';
  seq{k}.outside = alloutside(:)';
end

% compute mean per condition and sem
avgsent = sumsent./Nsubj;
varsent = (ssqsent - sumsent.^2./Nsubj)./(Nsubj-1);
semsent = sqrt(varsent./Nsubj);

avgseq  = sumseq./Nsubj;
varseq  = (ssqseq - sumseq.^2./Nsubj)./(Nsubj-1);
semseq  = sqrt(varseq./Nsubj);

cfg = [];
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.numrandomization = 100;
cfg.parameter = 'avg.pow';
cfg.correctm  = 'cluster';
cfg.clusteralpha = 0.005;
%cfg.clusterthreshold = 'nonparametric_individual';
stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
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