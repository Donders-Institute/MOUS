function connections = mous_getnodetimecourses_new(data, connections)

% the datamatrix is assumed to be Nedges*4 versus 840 time points
if iscell(data)
  iscelldata = true;
  Ncell = numel(data);
else
  iscelldata = false;
end

if iscelldata
%   for k = 1:numel(data)
%     % subtract baseline per condition, assuming the first 120 samples to be pre-zero
%     data{k} = data{k} - repmat(mean(data{k}(:,1:120),2), [1 840]);
%   end
  
  % concatenate across conditions, now data is a matrix
  data = cat(2, data{:});
end


for k = 1:numel(connections)
  tmpindx = (connections(k).indx(:)-1)*4;
  tmp     = [data(tmpindx+1,:);data(tmpindx+2,:)];
  [u,s,v] = svd(tmp,'econ');
  n       = numel(connections(k).senders);
  connections(k).senders_avg = u(:,1:min(n*2,size(u,2)))'*tmp;
  
  if iscelldata
    siz = size(connections(k).senders_avg);
    connections(k).senders_avg = reshape(connections(k).senders_avg, [siz(1) siz(2)./Ncell Ncell]);
  end
  
  tmp     = [data(tmpindx+3,:);data(tmpindx+4,:)];
  [u,s,v] = svd(tmp,'econ');
  n       = numel(connections(k).receivers);
  connections(k).receivers_avg = u(:,1:min(n*2,size(u,2)))'*tmp;
  
  if iscelldata
    siz = size(connections(k).receivers_avg);
    connections(k).receivers_avg = reshape(connections(k).receivers_avg, [siz(1) siz(2)./Ncell Ncell]);
  end
  
end


