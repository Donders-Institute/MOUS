function varargout = mous_lcmv_parcel_tlck(subj, varargin)

% this function uses spatial filters as computed with
% mous_granger_parcellate, i.e. an lcmv-based filter obtained from the
% covariance between 0.2 and 0.6 post word onset, and computes source level
% erfs based on the input data, using the first 2 components in the
% parcellated filter

data    = ft_getopt(varargin, 'data');
latency = ft_getopt(varargin, 'latency');

% default to the sentence-sequences erfs
if isempty(data)
  data = 'meg_erf_allwords_02-nextword-allwords-ag';
end

% load in the data file if the data argument is a string + convert to cell
% array with known variable name
if ischar(data)
  tmpdata = mous_db_getdata(subj, data);
  fn = fieldnames(tmpdata);
  
  data = cell(1,numel(fn));
  for k = 1:numel(fn);
    data{k} = tmpdata.(fn{k});
  end
  clear tmpdata; 
end

% get the parcellation information, i.e. the spatial filters for each
% parcel
rootdir = '/project/3011020.09/jansch';
mous_db_getdata(subj, 'meg_granger_parcellation', rootdir);

% ensure it to be a cell-array
if ~iscell(data) 
  data = {data};
end

% do time axis subselection if requested
if ~isempty(latency)
  tmpcfg = [];
  tmpcfg.latency = latency;
  for k = 1:numel(data)
    data{k} = ft_selectdata(tmpcfg, data{k});
  end
end

% create the output
varargout = cell(1,numel(data));
for k = 1:numel(data)
  ix  = 1:nearest(data{k}.time,0);
  tmp = zeros(numel(parcellation.label),numel(data{k}.time),2);
  for m = 1:numel(parcellation.label)
    tmp(m,:,:) = transpose(parcellation.filter{m}(1:2,:)*data{k}.avg);
  end
  tmp = tmp - repmat(mean(tmp(:,ix,:),2), [1 size(tmp,2) 1]);
  tmp = tmp./repmat(std([tmp(:,ix,1) tmp(:,ix,2)],[],2), [1 size(tmp,2) 2]);
  tmp = sqrt(sum(tmp.^2,3));
  data{k}.avg   = tmp;
  data{k}.label = parcellation.label;
  varargout{k}  = data{k};
end
