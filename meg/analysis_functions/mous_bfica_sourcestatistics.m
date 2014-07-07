function [stat, Nsubj, avgsent, avgseq, semsent, semseq] = mous_bfica_sourcestatistics(subj, suffix, baselineflag, cfg, rootdir, findx)

% This function computes source-level statistics for sentseq(tar) contrasts
% suffix is a struct consisting of the components of the sourcedata being
% used in the contrast:
% suffix.wordtype = 'sentseq' or 'sentseqtar';
% suffix.oscband  = 'low', 'medium', or 'high';
% suffix.extra    = 'parcelavg','bslabsolute'...
% suffix.selfreq  = [low high];
% suffix.avg      = 'no'  or 'yes';  - option to average across selected frequencies 
% baselineflag:  1 = pre-word,  2 = pre-sentence

% cfg = options for ft_sourcestatistics
% rootdir = '/project/3011020.09/MEG/'
% findx  = index in the frequency dimension of the data (a JM option)

suffixstruct = isstruct(suffix);
Nsubj   = numel(subj);

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

if nargin<5
    rootdir = '/project/3011020.09/jansch/';
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
 
 clear -regexp tlcksent tlckseq  % can be used for tlcksent or tlcksenttar!
  
  %% select dataset by frequency(low/medium/high)
  if suffixstruct
    % Nietz's code suffix inarg is a struct
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.sourcedata], rootdir);
    if isfield(suffix,'selfreq') 
      if strcmp(suffix.avg,'no')
        tlcksent = ft_selectdata(tlcksent,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
        tlckseq = ft_selectdata(tlckseq,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      elseif strcmp(suffix.avg, 'yes'); % average across frequencies
        tlcksent = ft_selectdata(tlcksent,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
        tlckseq = ft_selectdata(tlckseq,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      end 
      tlcksent.avg = squeeze(tlcksent.avg);
      tlcksent.var = squeeze(tlcksent.var);
      tlckseq.avg = squeeze(tlckseq.avg);
      tlckseq.var = squeeze(tlckseq.var);
    end
  
  else
    % JM's code usings suffix inarg that is made up of a cell array of strings
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix{1}], rootdir);
    if isempty(findx), findx = 1; end
    
    tlcksent.avg = squeeze(tlcksent.avg.stat(:,findx,:));
    tlckseq.avg = squeeze(tlckseq.avg.stat(:,findx,:));
    if numel(findx)==1 && isfield(tlcksentpar, 'freq'), 
      tlcksent = rmfield(tlcksent, 'freq'); 
      tlckseq = rmfield(tlckseq, 'freq');
    end
  end
  
  %% rename variables: can reuse same script
  if exist('tlcksenttar','var')
    tlcksent = tlcksenttar;
    tlckseq  = tlckseqtar;
    clear -vars tlcksenttar tlckseqtar
  end 
  
  %% create data structure for statististics
  sourcemodel.time = tlckseq.time;  
  if isfield(tlckseq, 'freq') && ndims(tlckseq.avg) == 3 % this dimord is wrong for stats on only 1 freq (selected from matrix of source x freq x time)
    sourcemodel.freq  = tlckseq.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
   
  % no log transform
  % sequences 
  sourcemodel.avg.pow = (tlckseq.avg);
  if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3
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
  if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end

%% baseline subtraction
if baselineflag == 2            % pre-sentence baseline 
    [bslsen bslseq] = mous_make_presentencebsl(subj,suffix.oscband,rootdir);
    if isfield(tlckseq,'freq')  % for 3D data matrix
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow  = tmp - repmat(bslsen{k},[1,1,size(tmp,3)]);

        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow  = tmp - repmat(bslseq{k},[1,1,size(tmp,3)]);
      end
    else   % FIXME:  for 2D data matrix
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow = tmp - bslsen{k}.avg.pow*ones(1,size(tmp,2));
        
        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow = tmp -  bslseq{k}.avg.pow*ones(1,size(tmp,2));
      end
    end
end
if baselineflag  == 1
  if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3     % for 3D matrix: chan_freq_time (where chan = source)
      ix = find(sent{k}.time<=-0.1);  % loop through each bsl timepoint ?!?
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        sent{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

        tmp = seq{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        seq{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]);
      end
  else                          % for 2D matrix: chan_time  (single freq)
      ix = find(sent{k}.time<=-0.1);
      for k = 1:numel(sent)
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
      end
  end
end

  
%% compute cumulative sum and ssq + determine the inside for all
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

%% stats
% cfg = [ ];  % keep cfg from inarg
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