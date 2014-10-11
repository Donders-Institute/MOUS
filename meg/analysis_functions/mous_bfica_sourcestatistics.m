function [stat, Nsubj, avgsent, avgseq, semsent, semseq] = mous_bfica_sourcestatistics(subj, suffix, baselineflag, cfg, rootdir, findx)

% This function computes source-level statistics for sentseq(tar) contrasts
% suffix is a struct consisting of the components of the sourcedata being
% used in the contrast:
% suffix.sourcedata = 'sentseq' or 'sentseqtar';
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
 
  
  %% select dataset by frequency(low/medium/high)
  if suffixstruct
    % Nietz's code suffix inarg is a struct
    mous_db_getdata(subj{k}, ['meg_bfica_',suffix.sourcedata], rootdir);
    
    %%% adjust for target word analysis
    if exist('tlcksenttar','var')
      tlcksent = tlcksenttar;
      tlckseq  = tlckseqtar;
      clear -vars tlcksenttar tlckseqtar
    end 
    
    %%% adjust for RCendafter analysis
    if exist('tlckRCend','var')
      % cannot calculate variance for RCend-RCafter, and MXend-MXafter
      % nonequal number of trials in tlckRCend and tlckRCafter
      % this doesn't affect the group variance (based on new calculated
      % averages)
      tlcksent = tlckRCend;
      tlcksent.avg = tlcksent.avg - tlckRCafter.avg;
      
      tlckseq = tlckMXend;
      tlckseq.avg = tlckseq.avg - tlckMXafter.avg;
      clear -vars tlckMX* tlckRC* tstat*
    end
    
    %%% frequency (and averaging) selection
    if isfield(suffix,'selfreq') 
      if isfield(suffix,'avg') && strcmp(suffix.avg, 'yes'); % average across frequencies
        tlcksent = ft_selectdata(tlcksent,'foilim',suffix.selfreq,'avgoverfreq','yes');
        tlckseq = ft_selectdata(tlckseq,'foilim',suffix.selfreq,'avgoverfreq','yes');
      else % strcmp(suffix.avg,'no')
        tlcksent = ft_selectdata(tlcksent,'foilim',suffix.selfreq);
        tlckseq = ft_selectdata(tlckseq,'foilim',suffix.selfreq);
      end 
    end
    
    %% prestim
    bsltoi = [-inf -0.09];
    bslsent = ft_selectdata(tlcksent,'toilim',bsltoi);
    bslseq  = ft_selectdata(tlckseq,'toilim', bsltoi);
     
    %% poststim
    %%% time selection
    if isfield(suffix,'toi')
      if isfield(suffix,'tavg')
        tlcksent = ft_selectdata(tlcksent,'toilim',suffix.toi,'avgovertime','yes');
        tlckseq  = ft_selectdata(tlckseq,'toilim',suffix.toi,'avgovertime','yes');
      else  % no averaging across time points
        tlcksent = ft_selectdata(tlcksent,'toilim',suffix.toi);
        tlckseq  = ft_selectdata(tlckseq,'toilim',suffix.toi);
      end
    end

    %% squeeze data
    % If only one frequency band, squeeze data
    % If squeeze data before baseline selection ft_selectdata cannot correct select timepoints
    
    if isfield(suffix,'selfreq') && suffix.selfreq(1) == suffix.selfreq(2)
      tlcksent.avg = squeeze(tlcksent.avg);
      tlckseq.avg = squeeze(tlckseq.avg);
      
      bslsent.avg = squeeze(bslsent.avg);
      bslseq.avg = squeeze(bslseq.avg);
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
  
    
  %% baseline subtraction
  if baselineflag == 2            % pre-sentence baseline 
     [bslsen bslseq] = mous_make_presentencebsl(subj,suffix.oscband,rootdir);
      if isfield(tlckseq,'freq')  % for 3D data matrix
          tmp = tlcksent.avg;
          tlcksent.avg  = tmp - repmat(bslsen{k},[1,1,size(tmp,3)]);

          tmp = tlckseq.avg;
          tlckseq.avg  = tmp - repmat(bslseq{k},[1,1,size(tmp,3)]);
      else   % FIXME:  for 2D data matrix
          tmp = tlcksent.avg;
          tlcksent.avg = tmp - bslsen{k}.avg.pow*ones(1,size(tmp,2));

          tmp = tlckseq.avg;
          tlckseq.avg = tmp -  bslseq{k}.avg.pow*ones(1,size(tmp,2));
      end
  end
  if baselineflag  == 1
    % for 3D matrix: chan_freq_time (where chan = source)
    if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3     
      tmp = tlcksent.avg;
      tlcksent.avg = tmp - repmat(nanmean(bslsent.avg,3),[1,1,size(tmp,3)]); % subtract baseline (repmat)
      tmp = tlckseq.avg;
      tlckseq.avg = tmp - repmat(nanmean(bslseq.avg,3),[1,1,size(tmp,3)]);
      
    % for 2D matrix: chan_time  or chan_freq
%     elseif numel(tlcksent.time) > 1         
    elseif (numel(tlcksent.time) > 1 && numel(tlcksent.freq) == 1) || (numel(tlcksent.time) == 1 && numel(tlcksent.freq) > 1)
      tmp = tlcksent.avg;
      tlcksent.avg = tmp - nanmean(bslsent.avg,2)*ones(1,size(tmp,2));
      tmp = tlckseq.avg;
      tlckseq.avg  = tmp - nanmean(bslseq.avg,2)*ones(1,size(tmp,2));
      
    elseif numel(tlcksent.time) == 1 && numel(tlcksent.freq) == 1
      tmp = tlcksent.avg;
      tlcksent.avg = tmp - nanmean(bslsent.avg,2);    
      tmp = tlckseq.avg;
      tlckseq.avg  = tmp - nanmean(bslseq.avg,2);
    end
  end
 
  %% update dimords 
  sourcemodel.time = tlckseq.time;  
  if isfield(tlckseq, 'freq') && ndims(tlckseq.avg) == 3 % this dimord is wrong for stats on only 1 freq (selected from matrix of source x freq x time)
    sourcemodel.freq  = tlckseq.freq;
    sourcemodel.dimord = 'pos_freq_time';
  elseif numel(tlcksent.time) > 1 && numel(tlcksent.freq) == 1
    sourcemodel.dimord = 'pos_time';
  elseif numel(tlcksent.time) == 1 && numel(tlcksent.freq) > 1
    sourcemodel.dimord = 'pos_freq';
  elseif numel(tlcksent.time) == 1 && numel(tlcksent.freq) == 1
    sourcemodel.dimord = 'pos';
  end
  
  %% create data structure for statistics
  % no log transform
  % sequences 
  sourcemodel.avg.pow = (tlckseq.avg);
  if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  elseif (numel(tlcksent.time) > 1 && numel(tlcksent.freq) == 1) || (numel(tlcksent.time) == 1 && numel(tlcksent.freq) > 1)
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  elseif numel(tlcksent.time) == 1 && numel(tlcksent.freq) == 1
    sourcemodel.freq     = tlcksent.freq;
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
 
  % sentences
  sourcemodel.avg.pow = (tlcksent.avg); 
  if isfield(tlckseq,'freq') && ndims(tlckseq.avg) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  elseif (numel(tlcksent.time) > 1 && numel(tlcksent.freq) == 1) || (numel(tlcksent.time) == 1 && numel(tlcksent.freq) > 1)
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  elseif numel(tlcksent.time) == 1 && numel(tlcksent.freq) == 1
    sourcemodel.freq     = tlcksent.freq;
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
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
stat = ft_sourcestatistics(cfg, sent{:}, seq{:});  % RC = sent;  MX = seq

% switch suffix.sourcedata
%   case {'sourcedatasentseq_low' 'sourcedatasentseq_medium' 'sourcedatasentseq_high' 'sourcedatasentseqtar_low' 'sourcedatasentseqtar_medium' 'sourcedatasentseqtar_high'}
%     varargout{1} = stat;
%     varargout{2} = Nsubj;
%     varargout{3} = avgsent;
%     varargout{4} = avgseq;
%     varargout{5} = semsent;
%     varargout{6} = semseq;
%   case {'sourcedataRCendafter_low' 'sourcedataRCendafter_medium' 'sourcedataRCendafter_high'}
% end


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