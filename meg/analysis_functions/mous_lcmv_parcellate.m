function [source, parcellation] = mous_lcmv_parcellate(sourcein, tlck, varargin)

method = ft_getopt(varargin, 'method', 'parcellation_dss');

switch method
  case 'graphcut'
    % this has never really worked I guess, kept here for historical
    % reasons
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
    
    if ~isfield(tlck, 'cov')
      tlck = ft_checkdata(tlck, 'datatype', 'raw');
      cfg  = [];
      cfg.covariance = true;
      tlck = ft_timelockanalysis(cfg, tlck);
    end
    
    % use an existing parcellation, and do an svd on the projected
    % variance
    parcellation = ft_getopt(varargin, 'parcellation');
    parcelparam  = ft_getopt(varargin, 'parcellationparam', 'parcellation');
    parcel_indx  = ft_getopt(varargin, 'parcel_indx', 'all');
    
    if isequal(parcel_indx,'all')
      parcel_indx = 1:numel(parcellation.([parcelparam,'label']));
    elseif iscell(parcel_indx)
      parcel_indx = match_str(parcellation.([parcelparam,'label']), parcel_indx);
    elseif ischar(parcel_indx)
      parcel_indx = match_str(parcellation.([parcelparam,'label']), parcel_indx);
    end
    
    Nparcel = numel(parcel_indx);
    filter  = cell(Nparcel,1);
    for k = 1:Nparcel
      sel = parcellation.(parcelparam)==parcel_indx(k);
      F   = cat(1,sourcein.avg.filter{sel});
      [u,s,v] = svd(F*tlck.cov*F');
      filter{k} = u'*F;
      S{k}      = diag(s);
      U{k}      = u;
    end
    label  = sourcein.avg.label;
    source = rmfield(sourcein, 'avg');
    source.parcellation = parcellation.(parcelparam);
    source.parcellationlabel = parcellation.([parcelparam,'label']);
    
    clear parcellation;
    
    parcellation.label  = source.parcellationlabel(parcel_indx);
    parcellation.filter = filter;
    parcellation.s      = S;
    parcellation.u      = U;
    parcellation.chanlabel = label;
  case 'parcellation_dss'
    % use an existing parcellation, but do a frequency band optimized dss
    % decomposition, sweeping through a range of frequencies
    ft_hastoolbox('dss', 1);
    tlck = ft_checkdata(tlck, 'datatype', 'raw');
        
    cfg               = [];
    cfg.cellmode      = 'yes';
    cfg.method        = 'dss';
    cfg.demean        = 'no';
    cfg.doscale       = 'yes';
    cfg.dss.algorithm = 'pca';
    cfg.dss.denf.function = 'denoise_filter2';
    cfg.dss.denf.params.filter_filtfilt.A = [];
    cfg.dss.denf.params.filter_filtfilt.B = [];
    
    % use an existing parcellation, but still do an svd on the projected
    % power
    parcellation = ft_getopt(varargin, 'parcellation');
    parcelparam  = ft_getopt(varargin, 'parcellationparam', 'parcellation');
    parcel_indx  = ft_getopt(varargin, 'parcel_indx', 'all');
    freqs        = ft_getopt(varargin, 'freq', [1:30 35:5:80]);
    
    if isequal(parcel_indx,'all')
      parcel_indx = 1:numel(parcellation.([parcelparam,'label']));
    elseif iscell(parcel_indx)
      parcel_indx = match_str(parcellation.([parcelparam,'label']), parcel_indx);
    elseif ischar(parcel_indx)
      parcel_indx = match_str(parcellation.([parcelparam,'label']), parcel_indx);
    end
    
    Nparcel = numel(parcel_indx);
    filter  = cell(Nparcel,1);
    for m = 1:Nparcel
      data = removefields(tlck, {'label' 'grad' 'elec'});
      
      sel = parcellation.(parcelparam)==parcel_indx(m);
      F   = cat(1,sourcein.avg.filter{sel});
      
      data.trial = F*tlck.trial;
      for k = 1:size(F,1)
        data.label{k,1} = sprintf('chan%03d',k);
      end
      
      for k = 1:numel(data.trial)
        data.trial{k} = ft_preproc_baselinecorrect(data.trial{k});
      end
      
      for k = 1:numel(freqs)
        fprintf('processing frequency %d Hz\n',freqs(k));
        [dum, B, A] = ft_preproc_bandpassfilter(data.trial{1},data.fsample,freqs(k)+[-1 1].*freqs(k)./8,[],'firws');
        cfg.dss.denf.params.filter_filtfilt.A = A;
        cfg.dss.denf.params.filter_filtfilt.B = B;
        cfg.dss.denf.params.filter_filtfilt.function = 'fir_filterdcpadded';
        if k==1
          cfg.dss = removefields(cfg.dss, {'V' 'dV'});
          cfg.doscale = 'yes';
        elseif k==2
          cfg.dss.V         = comp.cfg.dss.V;
          cfg.dss.dV        = comp.cfg.dss.dV;
          cfg.doscale       = 'no';
        end
        
        comp = ft_componentanalysis(cfg, data);
        filter{m}(:,:,k) = comp.unmixing*F;
      end
      
    end
    label  = sourcein.avg.label;
    source = rmfield(sourcein, 'avg');
    source.parcellation = parcellation.(parcelparam);
    source.parcellationlabel = parcellation.([parcelparam,'label']);
    
    clear parcellation;
    
    parcellation.label  = source.parcellationlabel(parcel_indx);
    parcellation.filter = filter;
    parcellation.chanlabel = label;
    parcellation.freq   = freqs;
  
  case 'parcellation_dss_mim'
    % use an existing parcellation, but do a frequency band optimized dss
    % decomposition, sweeping through a range of frequencies
    ft_hastoolbox('dss', 1);
    tlck = ft_checkdata(tlck, 'datatype', 'raw');
        
    cfg               = [];
    cfg.cellmode      = 'yes';
    cfg.method        = 'dss';
    cfg.demean        = 'no';
    cfg.doscale       = 'yes';
    cfg.dss.algorithm = 'mim';
    cfg.dss.denf.function = 'denoise_hilbert';
    cfg.dss.denf.params.filter_filtfilt.A = [];
    cfg.dss.denf.params.filter_filtfilt.B = [];
    cfg.dss.preprocf.function = 'pre_sphere_blocked';
    
    % use an existing parcellation, but still do an svd on the projected
    % power
    parcellation = ft_getopt(varargin, 'parcellation');
    parcelparam  = ft_getopt(varargin, 'parcellationparam', 'parcellation');
    parcel_cmb   = ft_getopt(varargin, 'parcel_cmb', {'all' 'all'});
    freqs        = ft_getopt(varargin, 'freq', [1:30 35:5:80]);
    
    label      = parcellation.([parcelparam,'label']);
    parcel_cmb = ft_channelcombination(parcel_cmb, label);
    parcel_indx(:,1) = match_str(label, parcel_cmb(:,1));
    parcel_indx(:,2) = match_str(label, parcel_cmb(:,2));
    
    Nparcelcmb = size(parcel_indx,1);
    filter  = cell(Nparcelcmb,1);
    for m = 1:Nparcelcmb
      data = removefields(tlck, {'label' 'grad' 'elec'});
      
      sel = parcellation.(parcelparam)==parcel_indx(m,1);
      F1  = cat(1,sourcein.avg.filter{sel});
      sel = parcellation.(parcelparam)==parcel_indx(m,2);
      F2  = cat(1,sourcein.avg.filter{sel});
      
      cfg.dss.indx = [ones(1,size(F1,1)) ones(1,size(F2,1))*2];
      cfg.dss.preprocf.params.indx = cfg.dss.indx;
    
      data.trial = [F1;F2]*tlck.trial;
      for k = 1:size(F1,1)
        data.label{k,1} = sprintf('chan1_%03d',k);
      end
      for k = 1:size(F2,1)
        data.label{size(F1,1)+k} = sprintf('chan2_%03d',k);
      end
      
      for k = 1:numel(data.trial)
        data.trial{k} = ft_preproc_baselinecorrect(data.trial{k});
      end
      
      for k = 1:numel(freqs)
        fprintf('processing frequency %d Hz\n',freqs(k));
        [dum, B, A] = ft_preproc_bandpassfilter(data.trial{1},data.fsample,freqs(k)+[-1 1].*freqs(k)./8,[],'firws');
        cfg.dss.denf.params.filter_filtfilt.A = A;
        cfg.dss.denf.params.filter_filtfilt.B = B;
        cfg.dss.denf.params.filter_filtfilt.function = 'fir_filterdcpadded';
        if k==1
          cfg.dss = removefields(cfg.dss, {'V' 'dV'});
          cfg.doscale = 'yes';
        elseif k==2
          cfg.dss.V         = comp.cfg.dss.V;
          cfg.dss.dV        = comp.cfg.dss.dV;
          cfg.doscale       = 'no';
        end
        
        comp = ft_componentanalysis(cfg, data);
        filter{m}(:,:,k) = comp.unmixing*[F1;F2];
        D{m}(:,k) = comp.cfg.dss.D;
      end
      
      N = size(comp.unmixing,1)/2;
      datlab = cell(2*N,1);
      for k = 1:N
        datlab{k  , 1} = sprintf('%s_%02d',parcel_cmb{m,1}, k);
        datlab{k+N, 1} = sprintf('%s_%02d',parcel_cmb{m,2}, k);
      end
      datlabel{m} = datlab;
      
    end
    
    
    label  = sourcein.avg.label;
    source = rmfield(sourcein, 'avg');
    source.parcellation = parcellation.(parcelparam);
    source.parcellationlabel = parcellation.([parcelparam,'label']);
    
    clear parcellation;
    
    parcellation.label  = reshape(source.parcellationlabel(parcel_indx), size(parcel_indx));
    parcellation.filter = filter;
    parcellation.chanlabel = label;
    parcellation.freq   = freqs;
    parcellation.datlabel = datlabel;
    parcellation.D = D;
  otherwise
end
