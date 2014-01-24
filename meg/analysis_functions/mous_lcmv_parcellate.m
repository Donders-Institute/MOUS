function [source, parcellation] = mous_lcmv_parcellate(sourcein, tlck)

% create a spatial filter matrix based on the svd of the projected
% covariance
Ninside = numel(sourcein.inside);
Nori    = size(sourcein.avg.filter{sourcein.inside(1)},1);
Nchan   = size(sourcein.avg.filter{sourcein.inside(1)},2);

F = zeros(Ninside*Nori,Nchan);
for k = 1:Ninside
  indx = sourcein.inside(k);
  f    = sourcein.avg.filter{indx};
  [u,s,v] = svd(f*tlck.cov*f');
  F(2*(k-1)+(1:2),:) = u'*f;
end

% parcellate separately the left and right hemispheres, assume them both to
% have 4098 vertices
indxlft = find(sourcein.inside<=4098);
indxrgt = find(sourcein.inside>=4098);

C       = F(1:(2*indxlft(end)),:)*tlck.cov*F(1:(2*indxlft(end)),:)';
C       = abs(C)./sqrt(diag(C)*diag(C)');
nC      = ncutW(C, 200);
idx     = zeros(size(nC,1)/2,2);
n       = zeros(size(nC,2),1);
for k = 1:size(nC,2)
  idx(nC(1:2:end,k)==1,1) = k;
  idx(nC(2:2:end,k)==1,2) = k;
  n(k,1) = sum(nC(:,k));       
end
idxlft = idx;

C       = F((indxlft(end)*2+1):end,:)*tlck.cov*F((indxlft(end)*2+1):end,:)';
C       = abs(C)./sqrt(diag(C)*diag(C)');
nC      = ncutW(C, 200);
idx     = zeros(size(nC,1)/2,2);
n       = zeros(size(nC,2),1);
for k = 1:size(nC,2)
  idx(nC(1:2:end,k)==1,1) = k;
  idx(nC(2:2:end,k)==1,2) = k;
  n(k,1) = sum(nC(:,k));       
end
idxrgt = idx+200;

idx = [idxlft;idxrgt];

% % now check whether the patches are spatially contiguous
% connmat = tri2connmat(sourcein.tri);
% connmat2 = connmat*connmat; % second order neighbourhood
% clusmat = triu(full(connmat2>0),1);
% 
% newidx = idx;
% cnt    = max(idx(:))+1;
% for k = 1:size(nC,2)
%   clus  = double(findcluster(sum(idx==k,2)>0,clusmat(1:4098,1:4098))); % convert uint32 to double precision
%   nclus = numel(unique(clus))-1;
%   fprintf('number of spatially contiguous clusters of the %d vertices in cluster %d is %d\n', n(k), k, nclus);
%   if nclus<1
%     % re-index: this will be done later
%   elseif nclus==1
%     % do nothing
%   elseif nclus>1
%     for kk = 1:nclus
%       nsub = sum(clus==kk);
%       fprintf('number of vertices in subcluster %d is %d\n', kk, nsub);
%       if nsub>=10
%         % re-index
%         tmp = newidx(clus==kk,:);
%         tmp(tmp==kk) = cnt;
%         %keyboard
%         newidx(clus==kk,:) = tmp;
%         cnt = cnt+1;
%       else
%         % re-assign the vertices to the cluster to which the direct
%         % neighbours belong by majority vote
%         selidx  = find(clus==kk);
%         [~, iy] = find(connmat(selidx,:));
%         [~, iz] = find(newidx(selidx,:)==k);  % take a majority vote as to which orientation to take
%         iy      = setdiff(iy,selidx);
%         clusid  = newidx(iy, mode(iz));
%         for kkk = 1:numel(selidx)
%           newidx(selidx(kkk), iz(kkk)) = mode(clusid);
%         end
%       end
%     end  
%   end
% end

% combine the spatial filters per parcel and summarize it with the largest
% component.
filter = cell(max(idx(:)),1);
idx    = reshape(idx', [8196*2 1]);
for k = 1:numel(filter)
  tmp     = F(idx==k,:);
  if ~isempty(tmp)
    [u,s,v]   = svd(tmp*tlck.cov*tmp');
    filter{k} = u(:,1)'*tmp;
  end
end
  
source = rmfield(sourcein, 'avg');
source.parcellation = [idxlft;idxrgt];
for k = 1:numel(filter)/2
  source.parcellationlabel{k,1} = ['L_parcel',num2str(k,'%03d')];
  source.parcellationlabel{k+numel(filter)/2,1} = ['R_parcel',num2str(k+numel(filter)/2,'%03d')];
end

parcellation.label  = source.parcellationlabel;
parcellation.filter = filter;
