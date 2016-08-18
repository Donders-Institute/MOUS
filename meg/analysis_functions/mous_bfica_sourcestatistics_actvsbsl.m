function [statsent, statseq, Nsubj, avgsent, avgseq, semsent, semseq] = mous_bfica_sourcestatistics_actvsbsl(subj, suffix, baselinetype, cfg, rootdir)

% specify which type of baseline correction is requested
if nargin<3
  baselinetype = 'absolute';
end

% specify some cfg fields for the statistics routine.
if nargin<4
  cfg = [];
end
cfg.correctm         = ft_getopt(cfg, 'correctm', 'cluster');
cfg.numrandomization = ft_getopt(cfg, 'numrandomization', 1000);
if strcmp(cfg.correctm, 'cluster')
  cfg.clusteralpha     = ft_getopt(cfg, 'clusteralpha', 0.005);
  cfg.clusterthreshold = ft_getopt(cfg, 'clusterthreshold', 'nonparametric_individual');
end

if nargin<5
  rootdir = '/project/3011020.09/MEG/';
end

[p,~,~] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
sourcemodeltemplate = sourcemodel;

Nsubj   = numel(subj);
sent    = cell(1,Nsubj);
seq     = cell(1,Nsubj);
dummy   = cell(1,Nsubj);
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

  % and a dummy with 0's
  dummy{k}       = sourcemodel;
  dummy{k}.pos   = sourcemodeltemplate.pos;
  dummy{k}.avg.pow(:) = 0;
  
  
  switch baselinetype
    case 'absolute'
      if isfield(tlckseq,'freq')        % for 3D matrix: chan_freq_time (where chan = source)
        % loop through each bsl timepoint ?!?
        ix  = find(sent{k}.time<=-0.1);
        tmp = sent{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        sent{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)
          
        tmp = seq{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        seq{k}.avg.pow = tmp - repmat(bsl,[1,1,size(tmp,3)]);
      else                          % for 2D matrix: chan_time  (single freq)
        ix = find(sent{k}.time<=-0.1);
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow = tmp - nanmean(tmp(:,ix),2)*ones(1,size(tmp,2));
      end
    case 'relchange'
      if isfield(tlckseq,'freq')        % for 3D matrix: chan_freq_time (where chan = source)
        % loop through each bsl timepoint ?!?
        ix  = find(sent{k}.time<=-0.1);
        tmp = sent{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        sent{k}.avg.pow = tmp ./ repmat(bsl,[1,1,size(tmp,3)]) - 1;
          
        tmp = seq{k}.avg.pow;
        bsl = nanmean(tmp(:,:,ix),3);
        seq{k}.avg.pow = tmp ./ repmat(bsl,[1,1,size(tmp,3)]) - 1;
      else                          % for 2D matrix: chan_time  (single freq)
        ix = find(sent{k}.time<=-0.1);
        tmp = sent{k}.avg.pow;
        sent{k}.avg.pow = tmp ./ (nanmean(tmp(:,ix),2)*ones(1,size(tmp,2))) - 1;
        tmp = seq{k}.avg.pow;
        seq{k}.avg.pow = tmp ./ (nanmean(tmp(:,ix),2)*ones(1,size(tmp,2))) - 1;
      end
    otherwise
  end
end


% % do a baseline subtraction
% if baselineflag == 2            % pre-sentence baseline 
%     [bslsen bslseq] = mous_make_presentencebsl(subj,suff.oscband,rootdir);
%     if isfield(tlckseq,'freq')  % for 3D data matrix
%       % FIXME: implement ix = find(sent{k}.time<=-0.1 here or in
%       % mous_make_presentencebsl?
%       % also, <= -0.1 is an exclusive OR.   Should we not take advantage of
%       % using both -0.15 and -0.1 (especially for higher frequencies?)
%       for k = 1:numel(sent)
%         tmp = sent{k}.avg.pow;
%         sent{k}.avg.pow = tmp - repmat(bslsen{k}.avg.pow,[1,1,size(tmp,3)]);
% 
%         tmp = seq{k}.avg.pow;
%         seq{k}.avg.pow = tmp - repmat(bslseq{k}.avg.pow,[1,1,size(tmp,3)]);
%       end
%     else   % FIXME:  for 2D data matrix
%       for k = 1:numel(sent)
%         tmp = sent{k}.avg.pow;
%         sent{k}.avg.pow = tmp - bslsen{k}.avg.pow*ones(1,size(tmp,2));
%         
%         tmp = seq{k}.avg.pow;
%         seq{k}.avg.pow = tmp -  bslseq{k}.avg.pow*ones(1,size(tmp,2));
%       end
%     end
% end

  
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
statsent = ft_sourcestatistics(cfg, sent{:}, dummy{:});
statseq  = ft_sourcestatistics(cfg, seq{:}, dummy{:});
