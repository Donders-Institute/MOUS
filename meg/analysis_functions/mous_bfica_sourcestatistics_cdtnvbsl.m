 function [stat, Nsubj, avgcdtn, avgbsl, semcdtn, sembsl] = mous_bfica_sourcestatistics_cdtnvbsl(subj, suffix, bslflag, cfg, rootdir)

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

suffix.wordtypesel = 'sourcedatasentseq'; % change in order to load data

for k = 1:Nsubj
  clear tlcksent tlckseq
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtypesel, suffix.oscband], rootdir);
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end

  %sourcemodel.time = tlckseq.time;  % time separately determine for bsl and cdtn
  if isfield(tlckseq, 'freq')
    sourcemodel.freq  = tlckseq.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
   
  % no log transform
  % select necessary timepoints before placing into sourcemodel structure
  switch suffix.wordtype
    case {'sourcedataseqvbsl'};
    cfg2 = [];
    cfg2.latency = [0 0.5];
    cdtn = ft_selectdata(cfg2, tlckseq);

    if bslflag == 1
      if strcmp(suffix.oscband,'_low')
        cfg2.latency = [-0.1 -0.1];
      else 
        cfg2.latency = [-0.15 -0.1];
      end 
      bsl = ft_selectdata(cfg2,tlckseq); 
    end
  
    case {'sourcedatasentvbsl'}
    cfg2 = [];
    cfg2.latency = [0 0.5];
    cdtn = ft_selectdata(cfg2, tlcksent); 

    if bslflag == 1
      if strcmp(suffix.oscband,'_low')
        cfg2.latency = [-0.1 -0.1];
      else 
        cfg2.latency = [-0.15 -0.1];
      end 
      bsl = ft_selectdata(cfg2,tlcksent); 
    end 
    otherwise
      error('unidentified input, should be "sourcedatasentvbsl" or "sourcedataseqvbsl"');
  end 
  
  % insert selected data into sourcemodel structure
  sourcemodel.avg.pow = cdtn.avg;
  sourcemodel.time    = cdtn.time;
  if isfield(tlckseq,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  act{k}         = sourcemodel;
  act{k}.pos     = sourcemodeltemplate.pos;
  
  % pre-word baseline structure
  if bslflag == 1
    sourcemodel.avg.pow = bsl.avg;
    sourcemodel.time    = bsl.time;  %% USE CDTN.TIME? for ft_Freqanalysis need to use same timepoints
    if isfield(tlckseq,'freq')
      tmp = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
    else
      tmp = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
    end
    tmp(newinside,:,:) = sourcemodel.avg.pow;
    sourcemodel.avg.pow = tmp;
    bslcdtn{k}             = sourcemodel;
    bslcdtn{k}.pos         = sourcemodeltemplate.pos;  
    sourcemodel.time   = cdtn.time;  % only change time here to fool statistics, keep time on line 96 so that sourcemodel dimensions are consistent
  end
end 

  % pre-sentence baseline structure 
   
  if bslflag == 2         % pre-sentence baseline
    [~, ~, bslsenwhole, bslseqwhole] = mous_make_presentencebsl(subj,suffix.oscband,rootdir);
    if strcmp(suffix.wordtype,'sourcedatasentvbsl')
      bsl = bslsenwhole;
    elseif strcmp(suffix.wordtype,'sourcedataseqvbsl')
      bsl = bslseqwhole;
    end
  end 
 
  
% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    sumact      = act{k}.avg.pow;
    sumbslcdtn  = bslcdtn{k}.avg.pow;
    ssqact      = act{k}.avg.pow.^2;
    ssqbslcdtn  = bslcdtn{k}.avg.pow.^2;
    allinside   = act{k}.inside;
  else
    sumact      = sumact + act{k}.avg.pow;
    sumbslcdtn  = sumbslcdtn  + bslcdtn{k}.avg.pow;
    ssqact      = ssqact + act{k}.avg.pow.^2;
    ssqbslcdtn  = ssqbslcdtn  + bslcdtn{k}.avg.pow.^2;
    allinside = intersect(allinside, act{k}.inside);
  end  
end
alloutside = setdiff(1:size(act{1}.pos,1), allinside);
for k = 1:Nsubj
  act{k}.inside = allinside(:)';
  act{k}.outside = alloutside(:)';
  bslcdtn{k}.inside  = allinside(:)';
  bslcdtn{k}.outside = alloutside(:)';
end

% compute mean per condition and sem
avgact = sumact./Nsubj;
varact = (ssqact - sumact.^2./Nsubj)./(Nsubj-1);
semact = sqrt(varact./Nsubj);

avgbslcdtn  = sumbslcdtn./Nsubj;
varbslcdtn  = (ssqbslcdtn - sumbslcdtn.^2./Nsubj)./(Nsubj-1);
sembslcdtn  = sqrt(varbslcdtn./Nsubj);

% cfg = [ ];  % keep cfg from inarg
% FIXME: does data for 'act' and ' bslcdtn'  need to have same time
% parameters?
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';
stat  = ft_sourcestatistics(cfg, act{:}, bslcdtn{:});

