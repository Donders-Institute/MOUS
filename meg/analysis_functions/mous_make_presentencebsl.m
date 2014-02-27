function [sent seq] = mous_make_presentencebsl(subj, oscband, rootdir)

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
  mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq_firstword_',oscband], rootdir);
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
  cfgt = [];
  if strcmp(oscband,'low')
    cfgt.latency = [-0.1 -0.1]; 
  elseif strcmp(osband,'medium') || strcmp(oscband,'high');
    cfgt.latency = [-0.15 -0.1];
  end
  tlcksentfirst = ft_selectdata_new(cfgt, tlcksentfirst);
  tlckseqfirst = ft_selectdata_new(cfgt, tlckseqfirst);
 
    
  % Adjust sourcemodel dimensions according to input data
  % This time field is most important when submitting bsl as a condition to sourcestatistics
  sourcemodel.time = tlckseqfirst.time;  
  if isfield(tlckseqfirst, 'freq')
    sourcemodel.freq  = tlckseqfirst.freq;
    sourcemodel.dimord = 'pos_freq_time';
  else
    sourcemodel.dimord = 'pos_time';
  end
     
  % no log transform
  % sequences 
  sourcemodel.avg.pow = (tlckseqfirst.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
  if isfield(tlckseqfirst,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end 
  tmp(newinside,:,:)    = sourcemodel.avg.pow; % 'newinside' is a variable that loads along with the leadfield.
  sourcemodel.avg.pow = tmp;
  seq{k}         = sourcemodel;
  seq{k}.pos     = sourcemodeltemplate.pos;
  
  % sentences
  sourcemodel.avg.pow = (tlcksentfirst.avg); 
  if isfield(tlcksentfirst,'freq')
    tmp                 = zeros(prod(sourcemodel.dim),size(sourcemodel.avg.pow,2),numel(sourcemodel.time));
  else 
    tmp                 = zeros(prod(sourcemodel.dim),numel(sourcemodel.time));
  end
  tmp(newinside,:,:)    = sourcemodel.avg.pow;
  sourcemodel.avg.pow = tmp;
  sent{k}        = sourcemodel;
  sent{k}.pos    = sourcemodeltemplate.pos;
end




 