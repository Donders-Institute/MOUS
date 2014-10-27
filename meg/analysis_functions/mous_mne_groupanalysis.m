function [stat,sent,seq,datsent,datseq] = mous_mne_groupanalysis(subj, suffix, rootdir, varargin)

% MOUS_MNE_GROUPANALYSIS performs statistical analysis of the sentence
% versus sequence main contrast of MNE reconstructed data.
%
% Use as
%   [stat, sent, seq, datsent, datseq] = mous_mne_groupanalysis(subj, suffix, rootdir, varargin)
%
% Input arguments:
%   subj   = cell-array of the subjects that are included in the analysis
%   suffix = string, file suffix that identifies the file to be read, starting with 'meg_mne_'
%   rootdir = directory where the MNE results are
%
% Output arguments:
%    ....

if nargin==2
  rootdir = '';
end

param = ft_getopt(varargin, 'parameter', 'avg.pow');
sent  = ft_getopt(varargin, 'sent');
seq   = ft_getopt(varargin, 'seq');
cfg   = ft_getopt(varargin, 'cfg', []);

if ~iscell(suffix)
  suffix = {suffix};
  % suffix was either a single string or a 2-element cell-array
  % in case it was a string, the assumption was that it contains 'sent' and
  % the other condition is assumed to have 'sent' replaced with 'seq'.
  % in case it was a cell-array, it's more generic, where the first element
  % is condition 1 and the second condition 2
end

if isempty(sent) || isempty(seq)
  
  % load in the data
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, suffix{1}, rootdir);
    if ~exist('source', 'var')
      %HACK
      source = stat;
    end
    if strcmp(param, 'avg.dspm') && ~issubfield(source, param)
      if issubfield(source, 'avg.noise') && issubfield(source, 'avg.pow')
        fprintf('computing dspm from the power and the noise fields\n');
        source.avg.dspm = spdiags(1./sqrt(source.avg.noise),0,8196,8196)*source.avg.pow;
      else
        error('the parameter ''avg.dspm'' is not found in the data and cannot be computed');
      end
    elseif ~issubfield(source, param);
      error('the parameter %s is not found in the data and cannot be computed',param);
    end
      
    if k==1
      if ~isfield(source, 'pos')
        load('cortex_inflated_8196reg');
        source.pos = sourcemodel.pnt;
        source.tri = sourcemodel.tri;
        clear sourcemodel;
      end
      
      tmpdat   = getsubfield(source, param);
      inside   = find(sum(tmpdat~=0,2)==numel(source.time)|sum(isfinite(tmpdat),2)==numel(source.time));
      outside  = setdiff(1:8196,inside(:)')';
      endtim   = nearest(source.time, 0.6);
      
      tmp.inside = inside;
      tmp.outside = outside;
      tmp.pos  = source.pos;
      tmp.time = source.time(1:4:endtim); % downsample the time axis with a factor of 4
      tmp.tri  = source.tri;
      
      tmp.method  = 'average';
    end
    tmptmp = ft_preproc_smooth(getsubfield(source, param), 4); % boxcar average time axis with 4 samples
    tmp    = setsubfield(tmp, param, tmptmp(:,1:4:endtim));
    sent{k} = tmp;
    clear source;
    
    if numel(suffix)>1
      suffix2 = suffix{2};
    else
      suffix2 = strrep(suffix{1},'sent', 'seq');
    end
    mous_db_getdata(subj{k}, suffix2, rootdir);
    if ~exist('source', 'var')
      %HACK
      source = stat;
    end
    tmptmp = ft_preproc_smooth(getsubfield(source, param), 4);
    tmp    = setsubfield(tmp, param, tmptmp(:,1:4:endtim));
    seq{k} = tmp;
    clear source
  end
end


Nsubj = numel(sent);
% if ~isfield(sent{1}, 'dim')
% for k = 1:Nsubj
%   sent{k}.dim = [8196 1 1];
%   seq{k}.dim  = [8196 1 1];
% end
% end

load('cortex_inflated_8196reg');


design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];

cfg.method    = ft_getopt(cfg, 'method', 'montecarlo');
cfg.statistic = ft_getopt(cfg, 'statistic', 'depsamplesT');
cfg.design    = ft_getopt(cfg, 'design', design);
cfg.ivar      = ft_getopt(cfg, 'ivar',   1);
cfg.uvar      = ft_getopt(cfg, 'uvar',   2);
cfg.numrandomization = ft_getopt(cfg, 'numrandomization', 1000);
cfg.parameter = param;
cfg.correctm  = ft_getopt(cfg, 'correctm', 'cluster');
if strcmp(cfg.correctm,'cluster')
  cfg.clusterthreshold = ft_getopt(cfg, 'clusterthreshold', 'nonparametric_individual');
end
cfg.tri       = sourcemodel.tri;

if isfield(cfg, 'latency'),
  % ft_sourcestatistics does not work with latency yet, so do it here
  for k = 1:numel(sent)
    ix = nearest(sent{k}.time, cfg.latency(1));
    iy = nearest(sent{k}.time, cfg.latency(2));
    tmp = getsubfield(sent{k}, param);
    tmp = tmp(:,ix:iy);
    sent{k} = setsubfield(sent{k}, param, tmp);
  
    ix = nearest(seq{k}.time, cfg.latency(1));
    iy = nearest(seq{k}.time, cfg.latency(2));
    tmp = getsubfield(seq{k}, param);
    tmp = tmp(:,ix:iy);
    seq{k} = setsubfield(seq{k}, param, tmp);
  end
  cfg = rmfield(cfg, 'latency');
end
if isfield(cfg, 'avgovertime') && istrue(cfg.avgovertime)
  for k = 1:numel(sent)
    tmp = getsubfield(sent{k}, param);
    sent{k} = setsubfield(sent{k}, param, nanmean(tmp,2));
    tmp = getsubfield(seq{k}, param);
    seq{k} = setsubfield(seq{k}, param, nanmean(tmp,2));
  end
  cfg = rmfield(cfg, 'avgovertime');
end

stat = ft_sourcestatistics(cfg,sent{:},seq{:});

datsent = zeros(size(stat.stat));
datseq  = zeros(size(stat.stat));
for k = 1:Nsubj
  datsent = datsent+getsubfield(sent{k},param);
  datseq  = datseq+getsubfield(seq{k},param);
end
datsent = datsent./Nsubj;
datseq  = datseq./Nsubj;

