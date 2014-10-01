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
  if suffixstruct % Nietzsche's code uses a structure for the input argument suffix
    
    % get data 
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{1}], rootdir);     
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype{2}], rootdir);

    if regexp(suffix.wordtype{1},'tar')  % rename variable if necessary
      statsentpar = statsentpartar;
      statseqpar  = statseqpartar;
    end
    
       %%% frequency (and averaging) selection
    if isfield(suffix,'selfreq')
      if strcmp(suffix.avg,'no')
        statsentpar = ft_selectdata(statsentpar,'foilim',suffix.selfreq);
        statseqpar  = ft_selectdata(statseqpar,'foilim',suffix.selfreq);
      elseif strcmp(suffix.avg, 'yes'); % average across frequencies
        statsentpar = ft_selectdata(statsentpar,'foilim',suffix.selfreq,'avgoverfreq','yes');
        statseqpar = ft_selectdata(statseqpar,'foilim',suffix.selfreq,'avgoverfreq','yes');
      end 
    end
    
    % prestim    
    bsltoi = [-inf -0.09];
    bslsent = ft_selectdata(statsentpar,'toilim',bsltoi);
    bslseq = ft_selectdata(statseqpar,'toilim',bsltoi);

    % poststim
    % time selection
    if isfield(suffix,'toi')
      statsentpar = ft_selectdata(statsentpar,'toilim',suffix.toi);
      statseqpar = ft_selectdata(statseqpar,'toilim',suffix.toi);
    end
    % squeeze data
    statsentpar.stat = squeeze(statsentpar.stat);
    statsentpar.prob = squeeze(statsentpar.prob);
    statsentpar.mask = squeeze(statsentpar.mask);
    statsentpar.cirange = squeeze(statsentpar.cirange);
    
    statseqpar.stat = squeeze(statseqpar.stat);
    statseqpar.prob = squeeze(statseqpar.prob);
    statseqpar.mask = squeeze(statseqpar.mask);
    statseqpar.cirange = squeeze(statseqpar.cirange);
    
    bslsent.stat = squeeze(bslsent.stat);
    bslseq.stat = squeeze(bslseq.stat);
   
  else
    % JM's original code uses a cell array of strings for the input
    % argument suffix
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix{1}], rootdir);
    if isempty(findx), findx = 1; end
    % sentences
    statsentpar.stat = squeeze(nanmean(statsentpar.stat(:,findx,:),2));
    if numel(findx)==1 && isfield(tlcksentpar, 'freq'), 
      tlcksentpar = rmfield(tlcksentpar, 'freq'); 
      statsentpar = rmfield(statsentpar, 'freq');
    end
    
    % sequences
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix{2}], rootdir);
    statseqpar.stat = squeeze(nanmean(statseqpar.stat(:,findx,:),2));
    if numel(findx)==1 && isfield(tlckseqpar, 'freq'), 
      tlckseqpar = rmfield(tlckseqpar, 'freq');
      statseqpar = rmfield(statseqpar, 'freq');
    end
  end
  
  
  %% baseline subtraction
  if baselineflag
    if isfield(statseqpar,'freq') && ndims(statseqpar.stat) == 3 % if 3D matrix
        tmp = statsentpar.stat;
        statsentpar.stat = tmp - repmat(nanmean(bslsent.stat,3),[1,1,size(tmp,3)]); % subtract baseline (repmat)

        tmp = statseqpar.stat;
        statseqpar.stat = tmp - repmat(nanmean(bslseq.stat,3),[1,1,size(tmp,3)]); 
    else 
        tmp = statsentpar.stat;
        statsentpar.stat = tmp - nanmean(bslsent.stat,2)*ones(1,size(tmp,2));

        tmp = statseqpar.stat;
        statseqpar.stat = tmp - nanmean(bslseq.stat,2)*ones(1,size(tmp,2));
    end
  end 
  
  %% update dimord
  sourcemodel.time = statsentpar.time;
  if isfield(statsentpar, 'freq') && ndims(statsentpar.stat) == 3 
    sourcemodel.freq  = statsentpar.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
  
  %% create data structure for statistics (no log transform)

  % seNTences
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

  % seQuences
  sourcemodel.time = statseqpar.time;
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

end % end subject loop

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
