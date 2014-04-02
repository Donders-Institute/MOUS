  function [sent seq sentwhole seqwhole] = mous_make_presentencebsl(subj, oscband, rootdir)

Nsubj   = numel(subj);

if nargin<3
    rootdir = '/project/3011020.09/MEG/';
    % As of 27Feb2014: Visual results = /MEG/, Auditory = /nielam
end 

% get sourcemodel into which data will be inserted for statistics
% see mous_bfica_sourcestatisticsXXX.m
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
sourcemodeltemplate = sourcemodel;

for k = 1:Nsubj
  
  % load data
  clear tlcksentfirst tlckseqfirst
  mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq_firstword',oscband], rootdir);
  if k==1
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', rootdir);
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
  
  % limit time dimensions
  % When oscband = low: only one toi i.e. -0.1, when oscband > low (e.g., medium/high) there will be two i.e. -0.15 and -0.1
  % This is in alignment with the pre-word baseline calculated within mous_bfica_sourcestatistics(XXX).m
  if strcmp(oscband,'_low')
    tlcksentfirst= ft_selectdata(tlcksentfirst,'toilim',[-0.1 -0.1]);
    tlckseqfirst = ft_selectdata(tlckseqfirst,'toilim',[-0.1 -0.1]);
  elseif strcmp(oscband,'_medium') || strcmp(oscband,'_high');
    tlcksentfirst= ft_selectdata(tlcksentfirst,'toilim',[-0.15 -0.1],'avgovertime','yes');
    tlckseqfirst = ft_selectdata(tlckseqfirst,'toilim',[-0.15 -0.1],'avgovertime','yes');
  end
 
    
  % Adjust sourcemodel dimensions according to input data
  if isfield(tlckseqfirst, 'freq')      %  3D matrix
    sourcemodel.freq  = tlckseqfirst.freq;
    sourcemodel.dimord = 'pos_freq';    % time dimension removed (averaged)
    %sourcemodel.dimord = 'pos_freq_time';  
    % FIXME: consider keeping timefield so that we can run statistics for act vs. bsl
  else
    sourcemodel.time = 'pos_time';      % 2D matrix
  end
     
  % no log transform
  % sequences 
  sourcemodel.avg.pow = (tlckseqfirst.avg);
  if isfield(tlckseqfirst,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),1);
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
  
  % sentences
  sourcemodel.avg.pow = (tlcksentfirst.avg); 
  if isfield(tlcksentfirst,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),1);
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end

  % this returns the full structure so that it can be used as an individual
  % condition for group-level statistics.
  sentwhole = sent;
  seqwhole  = seq; 

  % this only returns the power values without the structure
% array: each element is the baseline matrix for one subject
% each cell:  % [number of sources X number of frequency bands] 
% [source x freq] 
for k = 1:numel(subj)
  sent{k} = sent{k}.avg.pow;
  seq{k}  = seq{k}.avg.pow;
end




 