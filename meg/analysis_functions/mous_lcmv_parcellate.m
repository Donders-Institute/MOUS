function [source, parcellation] = mous_lcmv_parcellate(sourcein, tlck, varargin)

method = ft_getopt(varargin, 'method', 'graphcut');

switch method
  case 'graphcut'
    
    Nclus = ft_getopt(varargin, 'Nclus', 400)./2;
    
    % create a spatial filter matrix based on the svd of the projected
    % covariance
    Ninside = numel(sourcein.inside);
    %Nori    = size(sourcein.avg.filter{sourcein.inside(1)},1);
    Nori    = 1;
    Nchan   = size(sourcein.avg.filter{sourcein.inside(1)},2);
    
    F = zeros(Ninside*Nori,Nchan);
    for k = 1:Ninside
      indx = sourcein.inside(k);
      f    = sourcein.avg.filter{indx};
      %[u,s,v] = svd(f*tlck.cov*f');
      %F(2*(k-1)+(1:2),:) = u'*f;
      %FIXME!!!!!!!!! this is incorrect and only works if leadfields are
      %un-backprojected 2D
      F(k,:) = f(1,:);
    end
    
    D    = tri2dist(sourcein.tri, 10);
    Dlft = D(1:4098,1:4098) + eye(4098);
    Drgt = D(4098+(1:4098),4098+(1:4098)) + eye(4098);
    Dlft = 1./Dlft;
    Drgt = 1./Drgt; % weight with inverse of distance
    
    %dupvec = repmat(1:4098,[2 1]);
    %dupvec = dupvec(:);
    
    % parcellate separately the left and right hemispheres, assume them both to
    % have 4098 vertices
    indxlft = find(sourcein.inside<=4098);
    indxrgt = find(sourcein.inside>4098);
    
    %options.verbose   = 1;
    options.valeurMin = 1e-4;
    
    %C       = F(1:(2*indxlft(end)),:)*tlck.cov*F(1:(2*indxlft(end)),:)';
    C       = F(indxlft,:)*tlck.cov*F(indxlft,:)';
    C       = abs(C)./sqrt(diag(C)*diag(C)');
    %nC      = ncutW(C.*Dlft(dupvec,dupvec), Nclus, options);
    nC      = ncutW(C.*Dlft, Nclus, options);
    %idx     = zeros(size(nC,1)/2,2);
    idx     = zeros(size(nC,1),1);
    nlft    = zeros(size(nC,2),1);
    for k = 1:size(nC,2)
      %idx(nC(1:2:end,k)==1,1) = k;
      %idx(nC(2:2:end,k)==1,2) = k;
      idx(nC(:,k)==1,1) = k;
      nlft(k,1) = sum(nC(:,k));
    end
    idxlft = idx;
    
    %C       = F((indxlft(end)*2+1):end,:)*tlck.cov*F((indxlft(end)*2+1):end,:)';
    C       = F(indxrgt,:)*tlck.cov*F(indxrgt,:)';
    C       = abs(C)./sqrt(diag(C)*diag(C)');
    %nC      = ncutW(C.*Drgt(dupvec,dupvec), Nclus, options);
    nC      = ncutW(C.*Drgt, Nclus, options);
    %idx     = zeros(size(nC,1)/2,2);
    idx     = zeros(size(nC,1),1);
    nrgt    = zeros(size(nC,2),1);
    for k = 1:size(nC,2)
      %idx(nC(1:2:end,k)==1,1) = k;
      %idx(nC(2:2:end,k)==1,2) = k;
      idx(nC(:,k)==1,1) = k;
      nrgt(k,1) = sum(nC(:,k));
    end
    idxrgt = idx+Nclus;
    
    idx = [idxlft;idxrgt];
    n   = [nlft;nrgt];
    
    
    % combine the spatial filters per parcel and summarize it with the largest
    % component.
    filter = cell(Nclus*2,1);
    %idx    = reshape(idx', [8196*2 1]);
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
    
  case 'parcellation'
    % use an existing parcellation, but still do an svd on the projected
    % power
    parcellation = ft_getopt(varargin, 'parcellation');
    parcelparam  = ft_getopt(varargin, 'parcellationparam');
    
    Nparcel = numel(parcellation.([parcelparam,'label']));
    filter  = cell(Nparcel,1);
    for k = 1:Nparcel
      sel = find(parcellation.(parcelparam)==k);
      F   = cat(1,sourcein.avg.filter{sel});
      [u,s,v] = svd(F*tlck.cov*F');
      filter{k} = u(:,1)'*F;
    end
    
    source = rmfield(sourcein, 'avg');
    source.parcellation = parcellation.(parcelparam);
    source.parcellationlabel = parcellation.([parcelparam,'label']);
    
    clear parcellation;
    
    parcellation.label  = source.parcellationlabel;
    parcellation.filter = filter;
    
  otherwise
end
