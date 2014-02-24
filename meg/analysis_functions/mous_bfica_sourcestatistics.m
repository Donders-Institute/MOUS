function [stat, Nsubj, avgsent, avgseq, semsent, semseq] = mous_bfica_sourcestatistics(subj, suffix, baselineflag, cfg, rootdir)

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

if nargin<5
    rootdir = '/project/3011020.09/jansch/';
end 
%rootdir = '/home/language/jansch/public/mous';
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  clear tlcksent tlckseq
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix], rootdir);
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  sourcemodel.time = tlckseq.time;  
  if isfield(tlckseq, 'freq')
    sourcemodel.freq  = tlckseq.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
   
  % no log transform
  % sequences 
  sourcemodel.avg.pow = (tlckseq.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  if isfield(tlckseq,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
 
  % sentences
  sourcemodel.avg.pow = (tlcksent.avg); 
  if isfield(tlckseq,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end

% do a baseline subtraction
if baselineflag
  if isfield(tlckseq,'freq') % for 3D matrix (chan_freq_time; where chan = sources))
      ix = find(sent{k}.time<=-0.1);
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        sent{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

        tmp = seq{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        seq{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]);
      end
  else % for 2D matrix %%
      ix = find(sent{k}.time<=-0.1);
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
      end
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

% cfg = [];  % keep cfg from inarg
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';
stat = ft_sourcestatistics(cfg, sent{:}, seq{:});


% Commented out because this functions wasn't written to take into account
% source_freq_time (e.g., 11000 x 16 x 13)
% if ndims(stat.stat)>2 && ~isfield(stat,'freq') 
% if source_freq_time dont make into 2D
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