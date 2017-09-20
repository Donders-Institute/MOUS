function g = mous_granger_blockwise_parcellation(csd_all, parcellation, reflabel)

selref = match_str(parcellation.label, reflabel);
nref   = numel(selref);
nparc  = numel(parcellation.label);

tmpcsd = rmfield(csd_all, {'label' 'crsspctrm'});
labelcmb = cell(nref*nparc*2,2);
grangerspctrm = zeros(nref*nparc*2,numel(csd_all.freq));
totispctrm    = zeros(nref*nparc*2,numel(csd_all.freq));

for k = 1:nref
  Fref  = parcellation.filter{selref(k)};
  Sref  = cumsum(parcellation.s{selref(k)});
  Sref  = Sref./Sref(end);
  %Fref  = Fref(Sref<0.99,:);
  Fref  = Fref(Sref<0.95,:);
  
  cnt = 0;
  for m = 1:nparc
    if any(strncmp({'L_?','R_?','L_M','R_M'},parcellation.label{m},3))
      fprintf('skipping parcel %s\n',parcellation.label{m});
      continue;
    end
    
    cnt = cnt+1;
    fprintf('computing blockwise granger for %s - %s\n', parcellation.label{m}, parcellation.label{selref(k)});
    F = parcellation.filter{m};
    S = cumsum(parcellation.s{m});
    S = S./S(end);
    %F = F(S<0.99,:);
    F = F(S<0.95,:);
    
    
    allF      = [Fref;F];
    
    crsspctrm = zeros(size(allF,1),size(allF,1),numel(csd_all.freq));
    for kk = 1:size(crsspctrm,3)
      crsspctrm(:,:,kk) = allF*csd_all.crsspctrm(:,:,kk)*allF';
    end
    tmpcsd.crsspctrm = crsspctrm;
    tmpcsd.label     = csd_all.label(1:size(crsspctrm,1)); % doesn't matter
    
    tmpout = ft_connectivity_csd2transfer(tmpcsd, 'feedback', 'none');
    H      = shiftdim(tmpout.transfer,  -1);
    S      = shiftdim(tmpout.crsspctrm, -1);
    Z      = shiftdim(tmpout.noisecov,  -1);
    powindx = {(1:size(Fref,1)) (1:size(F,1))+size(Fref,1)};
    tmpg    = ft_connectivity_granger(H,Z,S,'powindx',powindx,'dimord','rpt_chan_chan_freq');
    tmpt    = ft_connectivity_granger(H,Z,S,'powindx',powindx,'dimord','rpt_chan_chan_freq','method','total');
    
    labelcmb{(cnt-1)*2+(k-1)*2*nparc+1, 1} = parcellation.label{selref(k)};
    labelcmb{(cnt-1)*2+(k-1)*2*nparc+1, 2} = parcellation.label{m};
    labelcmb{(cnt-1)*2+(k-1)*2*nparc+2, 2} = parcellation.label{selref(k)};
    labelcmb{(cnt-1)*2+(k-1)*2*nparc+2, 1} = parcellation.label{m};
    
    grangerspctrm((cnt-1)*2+(k-1)*2*nparc+1, :) = squeeze(tmpg(1,2,:));
    grangerspctrm((cnt-1)*2+(k-1)*2*nparc+2, :) = squeeze(tmpg(2,1,:));
    totispctrm((cnt-1)*2+(k-1)*2*nparc+1, :)    = squeeze(tmpt(1,2,:));
    totispctrm((cnt-1)*2+(k-1)*2*nparc+2, :)    = squeeze(tmpt(2,1,:));
    
    
  end
end

n = (cnt-1)*2+(k-1)*2*nparc+2;
g.grangerspctrm = grangerspctrm(1:n,:);
g.totispctrm    = totispctrm(1:n,:);
g.labelcmb      = labelcmb(1:n,:);
g.freq          = csd_all.freq;
g.dimord        = 'chancmb_freq';
