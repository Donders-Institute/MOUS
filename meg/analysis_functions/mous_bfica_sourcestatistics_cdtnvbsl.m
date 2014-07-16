 function [stat, Nsubj, avgact, avgbslorzero, semact, sembslorzero] = mous_bfica_sourcestatistics_cdtnvbsl(subj, suffix, bzflag, cfg, rootdir, findx)

suffixstruct = isstruct(suffix);

if nargin<6;
  findx = [];
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

suffix.wordtypesel = 'sourcedatasentseq'; % change in order to load data

for k = 1:Nsubj
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  clear tlcksent tlckseq
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtypesel,'_', suffix.oscband], rootdir);
  
  % determine active condition to test against bsl/zero
  switch suffix.sourcedata
    case {'sourcedataseqvbz'};
      cdtn = tlckseq;
    case {'sourcedatasentvbz'}
      cdtn = tlcksent;
    otherwise
      error('unidentified suffix.sourcedata, specify "sourcedatasentvbsl" or "sourcedataseqvbsl"');
  end
  
  % frequency selection (and average)
  if isfield(suffix,'selfreq') 
    if strcmp(suffix.avg,'no')
      cdtn = ft_selectdata(cdtn,'foilim',suffix.selfreq);
    elseif strcmp(suffix.avg, 'yes'); % average across frequencies
      cdtn = ft_selectdata(cdtn,'foilim',suffix.selfreq,'avgoverfreq','yes');
    end 
  end
  
  % baseline (pre-word; select first because cdtn then becomes toi specific)
  if bzflag == 1
    bsl = ft_selectdata(cdtn, 'toilim',[-inf -0.09]);
  end
  
  if isfield(suffix,'toi')
    cdtn = ft_selectdata(cdtn,'toilim',suffix.toi);
  end
   
 
  %% update dimensions and dimord
  if isfield(suffix,'selfreq') && suffix.selfreq(1) == suffix.selfreq(2)
    cdtn.avg = squeeze(cdtn.avg);
    cdtn.var = squeeze(cdtn.var);
   
    if bzflag == 1
      bsl.avg = squeeze(bsl.avg);
    end 
  end

  if isfield(cdtn, 'freq')  && ndims(cdtn.avg) == 3 
    sourcemodel.freq  = cdtn.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
   
  
  %% Set data (sent or seq)
  sourcemodel.avg.pow = cdtn.avg;
  sourcemodel.time    = cdtn.time;
  if isfield(cdtn,'freq') && ndims(cdtn.avg) == 3 
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  act{k}         = sourcemodel;
  act{k}.pos     = sourcemodeltemplate.pos;
  
  %% set comparison data baseline / zero
  % pre-word baseline structure
  if bzflag == 1
    sourcemodel.avg.pow = bsl.avg;
    sourcemodel.time    = cdtn.time;  %% fool ft_sourcestatistics (need same # time points)
    if isfield(tlckseq,'freq')
      tmp = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
    else
      tmp = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
    end
    tmp(newinside,:,:) = repmat(sourcemodel.avg.pow, [1 1 numel(sourcemodel.time)]);
    sourcemodel.avg.pow = tmp;
    bslorzero{k}             = sourcemodel;
    bslorzero{k}.pos         = sourcemodeltemplate.pos;  

  % set pre-sentence baseline 
  elseif bzflag == 2         % pre-sentence baseline
    [~, ~, bslsenwhole, bslseqwhole] = mous_make_presentencebsl(subj,suffix.oscband,rootdir);
    if strcmp(suffix.wordtype,'sourcedatasentvbsl')
      bsl = bslsenwhole;
    elseif strcmp(suffix.wordtype,'sourcedataseqvbsl')
      bsl = bslseqwhole;
    end

    % set zero condition
  elseif bzflag == 3
    bslorzero{k} = act{k};
    bslorzero{k}.avg.pow(:) = 0;
  end  % bzflag 

end  % subject loop

%% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    sumact      = act{k}.avg.pow;  
    ssqact      = act{k}.avg.pow.^2;
    if bzflag == 1
      sumbslorzero  = bslorzero{k}.avg.pow;
      ssqbslorzero  = bslorzero{k}.avg.pow.^2;
    end
    allinside   = act{k}.inside;
  else
    sumact      = sumact + act{k}.avg.pow;
    ssqact      = ssqact + act{k}.avg.pow.^2;
    if bzflag == 1
      sumbslorzero  = sumbslorzero  + bslorzero{k}.avg.pow;  
      ssqbslorzero  = ssqbslorzero  + bslorzero{k}.avg.pow.^2;
    end
    allinside = intersect(allinside, act{k}.inside);
  end  
end
alloutside = setdiff(1:size(act{1}.pos,1), allinside);

for k = 1:Nsubj
  act{k}.inside = allinside(:)';
  act{k}.outside = alloutside(:)';
  if bzflag == 1
    bslorzero{k}.inside  = allinside(:)';
    bslorzero{k}.outside = alloutside(:)';
  end
end

% compute mean per condition and sem
avgact = sumact./Nsubj;
varact = (ssqact - sumact.^2./Nsubj)./(Nsubj-1);
semact = sqrt(varact./Nsubj);

if bzflag == 1
  avgbslorzero  = sumbslorzero./Nsubj;
  varbslorzero  = (ssqbslorzero - sumbslorzero.^2./Nsubj)./(Nsubj-1);
  sembslorzero  = sqrt(varbslorzero./Nsubj);
end

% cfg = [ ];  % keep cfg from inarg
% FIXME: does data for 'act' and ' bslorzero'  need to have same time
% parameters?
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';
stat  = ft_sourcestatistics(cfg, act{:}, bslorzero{:});

