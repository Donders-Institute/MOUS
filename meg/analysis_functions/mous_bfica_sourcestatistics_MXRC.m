function [stat, Nsubj, avgrc, avgmix, semrc, semmix] = mous_bfica_sourcestatistics_MXRC(subj, suffix, baselineflag, cfg, rootdir)

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
  clear -regexp tlcksentMX tlcksentRC % can be used for tlcksent or tlcksenttar!
  mous_db_getdata(subj{k}, ['meg_bfica_',suffix.wordtype, suffix.oscband], rootdir);
  
    % select frequency
  if ~isempty(suffix.selfreq) 
    if strcmp(suffix.avg,'no')
      tlcksentMX = ft_selectdata(tlcksentMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
      tlcksentRC = ft_selectdata(tlcksentRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)]);
    elseif strcmp(suffix.avg, 'yes'); % average across frequencies
      tlcksentMX = ft_selectdata(tlcksentMX,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
      tlcksentRC = ft_selectdata(tlcksentRC,'foilim',[suffix.selfreq(1) suffix.selfreq(2)],'avgoverfreq','yes');
    end 
    tlcksentMX.avg = squeeze(tlcksentMX.avg);
    tlcksentMX.var = squeeze(tlcksentMX.var);
    tlcksentRC.avg = squeeze(tlcksentRC.avg);
    tlcksentRC.var = squeeze(tlcksentRC.var); 
  end
    
 
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  sourcemodel.time = tlcksentMX.time;  
  if isfield(tlcksentMX, 'freq') && ndims(tlcksentMX.avg) == 3
    sourcemodel.freq  = tlcksentMX.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
   
  % no log transform
  % MIX sentences
  sourcemodel.avg.pow = (tlcksentMX.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  if isfield(tlcksentMX,'freq') && ndims(tlcksentMX.avg) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  mix{k}         = sourcemodel;
  mix{k}.pos     = sourcemodeltemplate.pos;
 
  % Relative clause (RC) sentences 
  sourcemodel.avg.pow = (tlcksentRC.avg); 
  if isfield(tlcksentRC,'freq') && ndims(tlcksentRC.avg) == 3
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  rc{k}        = sourcemodel;
  rc{k}.pos    = sourcemodeltemplate.pos;
end

% do a baseline subtraction
if baselineflag == 2            % pre-sentence baseline 
  error('pre-sentence baseline not yet implemented for this contrast');
%     [bslsen bslseq] = mous_make_presentencebsl(subj,suffix.oscband,rootdir);
%     if isfield(tlckseq,'freq')  % for 3D data matrix
%       for k = 1:numel(mix)
%         tmp = mix{k}.avg.pow;
%         mix{k}.avg.pow  = tmp - repmat(bslsen{k},[1,1,size(tmp,3)]);
% 
%         tmp = rc{k}.avg.pow;
%         rc{k}.avg.pow  = tmp - repmat(bslseq{k},[1,1,size(tmp,3)]);
%       end
%     else   % FIXME:  for 2D data matrix
%       for k = 1:numel(mix)
%         tmp = mix{k}.avg.pow;
%         mix{k}.avg.pow = tmp - bslsen{k}.avg.pow*ones(1,size(tmp,2));
%         
%         tmp = rc{k}.avg.pow;
%         rc{k}.avg.pow = tmp -  bslseq{k}.avg.pow*ones(1,size(tmp,2));
%       end
%     end
end
if baselineflag  == 1
  if isfield(tlcksentMX,'freq') && ndims(tlcksentMX.avg) == 3       % for 3D matrix: chan_freq_time act(where chan = source)
      ix = find(mix{k}.time<=-0.1);  % loop through each bsl timepoint ?!?
      for k = 1:numel(mix)
        tmp = mix{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        mix{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

        tmp = rc{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        rc{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]);
      end
  else                          % for 2D matrix: chan_time  (single freq)
      ix = find(mix{k}.time<=-0.1);
      for k = 1:numel(mix)
        tmp = mix{k}.avg.pow;
        mix{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
        tmp = rc{k}.avg.pow;
        rc{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
      end
  end
end

  
% compute cumulative sum and ssq + determine the inside for all
for k = 1:Nsubj
  if k==1
    summix = mix{k}.avg.pow;
    sumrc  = rc{k}.avg.pow;
    ssqmix = mix{k}.avg.pow.^2;
    ssqrc  = rc{k}.avg.pow.^2;
    allinside = mix{k}.inside;
  else
    summix = summix + mix{k}.avg.pow;
    sumrc  = sumrc  + rc{k}.avg.pow;
    ssqmix = ssqmix + mix{k}.avg.pow.^2;
    ssqrc  = ssqrc  + rc{k}.avg.pow.^2;
    allinside = intersect(allinside, mix{k}.inside);
  end  
end
alloutside = setdiff(1:size(mix{1}.pos,1), allinside);
for k = 1:Nsubj
  mix{k}.inside = allinside(:)';
  mix{k}.outside = alloutside(:)';
  rc{k}.inside  = allinside(:)';
  rc{k}.outside = alloutside(:)';
end

% compute mean per condition and sem
avgmix = summix./Nsubj;
varmix = (ssqmix - summix.^2./Nsubj)./(Nsubj-1);
semmix = sqrt(varmix./Nsubj);

avgrc  = sumrc./Nsubj;
varrc  = (ssqrc - sumrc.^2./Nsubj)./(Nsubj-1);
semrc  = sqrt(varrc./Nsubj);

% cfg = [ ];  % keep cfg from inarg
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'avg.pow';
stat = ft_sourcestatistics(cfg, rc{:}, mix{:});


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