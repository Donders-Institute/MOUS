function networks = mous_getnodetimecourses(data, senders, receivers)

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

networks = struct([]);
for k = 1:size(senders,1)
  for m = 1:numel(senders{k,1})
    tmpindx = (senders{k,2}{m}-1)*4;
    tmp = [data(tmpindx+1,:);data(tmpindx+2,:)];
    [u,s,v] = svd(tmp,'econ');
    networks(k).senders(m).label = senders{k,1}{m};
    n = numel(senders{k,1}{m});
    networks(k).senders(m).avg   = u(:,1:min(n*2,size(u,2)))'*tmp;
  
    if iscelldata
      siz = size(networks(k).senders(m).avg);
      networks(k).senders(m).avg = reshape(networks(k).senders(m).avg, [siz(1) siz(2)./Ncell Ncell]);
    end
  end  
  for m = 1:numel(receivers{k,1})
    tmpindx = (receivers{k,2}{m}-1)*4;
    tmp = [data(tmpindx+3,:);data(tmpindx+4,:)];
    [u,s,v] = svd(tmp,'econ');
    networks(k).receivers(m).label = receivers{k,1}{m};
    n = numel(receivers{k,1}{m});
    networks(k).receivers(m).avg   = u(:,1:min(n*2,size(u,2)))'*tmp;
    
    if iscelldata
      siz = size(networks(k).receivers(m).avg);
      networks(k).receivers(m).avg = reshape(networks(k).receivers(m).avg, [siz(1) siz(2)./Ncell Ncell]);
    end
  end
end


