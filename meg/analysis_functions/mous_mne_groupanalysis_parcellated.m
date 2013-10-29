function [stat,sent,seq,datsent,datseq] = mous_mne_groupanalysis_parcellated(subj, suffix, rootdir, varargin)

if nargin==2
  rootdir = '';
end

param = ft_getopt(varargin, 'parameter', 'avg.pow');

cfg              = [];
cfg.parameter    = param;
cfg.method       = 'median';
cfg.parcellation = 'parcellation2';

[p,f,e] = fileparts('mous_mne_groupanalysis_parcellated');
sel     = strfind(p, '/');
fname   = fullfile(p(1:sel),'templates','atlas_conte69_8196reg_LR');
load(fname);

% load in the data
for k = 1:numel(subj)
  %mous_db_getdata(subj{k}, ['meg_mne_',suffix,'_Sent'], rootdir);
  mous_db_getdata(subj{k}, suffix, rootdir);
  if ~exist('source', 'var')
    %HACK
    source = stat;
    if ~isfield(source, 'pos')
      load('cortex_inflated_8196reg');
      source.pos = sourcemodel.pnt;
      source.tri = sourcemodel.tri;
      clear sourcemodel;
    end
    if isfield(source, 'label')
      source = rmfield(source, 'label');
      source.dimord = 'pos_time';
    end
    source.inside = 1:8196;
    source.outside = [];
  end
  
  sourcep          = ft_sourceparcellate(cfg, source, atlas);
  sent{k}          = sourcep;
  clear source;
  
  %mous_db_getdata(subj{k}, ['meg_mne_',suffix,'_Seq'], rootdir);
  mous_db_getdata(subj{k}, strrep(suffix,'sent','seq'), rootdir);
  if ~exist('source', 'var')
    %HACK
    source = stat;
    if ~isfield(source, 'pos')
      load('cortex_inflated_8196reg');
      source.pos = sourcemodel.pnt;
      source.tri = sourcemodel.tri;
      clear sourcemodel;
    end
    if isfield(source, 'label')
      source = rmfield(source, 'label');
      source.dimord = 'pos_time';
    end
    source.inside = 1:8196;
    source.outside = [];
  end
  sourcep          = ft_sourceparcellate(cfg, source, atlas);
  seq{k}          = sourcep;
  clear source;
end

for k = 1:numel(subj)
  sent{k}.dimord = 'chan_time';
  seq{k}.dimord  = 'chan_time';
end

Nsubj = numel(sent);

for k = 1:numel(sent{1}.label)
  neighbours(k).label = sent{1}.label{k};
  neighbours(k).neighblabel = {};
end

cfg = [];
cfg.method  = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar   = 1;
cfg.uvar   = 2;
cfg.numrandomization = 1000;
cfg.parameter = param;
cfg.correctm = 'cluster';
cfg.neighbours = neighbours;
cfg.channel = sent{1}.label(setdiff(1:numel(sent{1}.label),[1 2 44 45])); % remove ??? and MEDIAL.WALL
stat = ft_timelockstatistics(cfg,sent{:},seq{:});

datsent = zeros(size(sent{1}.dspm));
datseq  = zeros(size(sent{1}.dspm));
for k = 1:Nsubj
  datsent = datsent+sent{k}.dspm;
  datseq  = datseq+seq{k}.dspm;
end
datsent = datsent./Nsubj;
datseq  = datseq./Nsubj;
