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

if isempty(sent) || isempty(seq)
  
  % load in the data
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, suffix, rootdir);
    if ~exist('source', 'var')
      %HACK
      source = stat;
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
      outside  = find(sum(tmpdat==0,2)==numel(source.time)|sum(~isfinite(tmpdat),2)==numel(source.time));
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
    
    mous_db_getdata(subj{k}, strrep(suffix,'sent','seq'), rootdir);
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
for k = 1:Nsubj
  sent{k}.dim = [8196 1 1];
  seq{k}.dim  = [8196 1 1];
end

load('cortex_inflated_8196reg');

cfg = [];
cfg.method = 'montecarlo';
cfg.statistic = 'depsamplesT';
%cfg.statistic = 'ft_statfun_diff';
%cfg.statistic = 'statfun_yuent';
%cfg.yuent.type = 'depsamples';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar   = 1;
cfg.uvar   = 2;
cfg.numrandomization = 1000;
cfg.parameter = param;
cfg.correctm = 'cluster';
cfg.clusterthreshold = 'nonparametric_individual';
cfg.tri = sourcemodel.tri;
stat = ft_sourcestatistics(cfg,sent{:},seq{:});

datsent = zeros(size(stat.stat));
datseq  = zeros(size(stat.stat));
for k = 1:Nsubj
  datsent = datsent+getsubfield(sent{k},param);
  datseq  = datseq+getsubfield(seq{k},param);
end
datsent = datsent./Nsubj;
datseq  = datseq./Nsubj;

