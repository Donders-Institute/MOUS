
docomputations = true;
if docomputations
  
  load atlas_conte69_8196reg_LR_brodmann_subparc
  parcel = {'L_44_B05_04';'L_22_B05_01';'L_22_B05_02';'L_22_B05_04';'L_22_B05_08';'L_22_B05_10'};
  sel = match_str(atlas.parcellationlabel, parcel);
  
  for k = 1:numel(sel)
    
    parcel_indx = sel(k)-2; % correct for ??? and medial wall offset in parcel index
    scenario = [1 4];
    
    for nmax = 1:5
      tim = 120; % in minutes
      gb  = 24+max(0,nmax-5).*5; % in gigabytes
      
      lags = -6:6;
      timeshift = 'before';
      savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax%d',nmax);
      system(sprintf('mkdir -p %s', savdir));
      qsubfeval('mous_execute_pipeline', ...
        'mous_hyperalignment_2sce_pipeline_forfigure0', 'V1001', {'parcel_indx' parcel_indx}, {'scenario' scenario}, ...
        {'nmax' nmax}, {'lags' lags}, {'timeshift' timeshift}, {'savdir', savdir}, 'timreq', tim*60, 'memreq', gb*(1024^3));
      
    end
    for nmax = 1:5
      tim = 120; % in minutes
      gb  = 24+max(0,nmax-5).*5; % in gigabytes
      
      lags = 0;
      timeshift = 'none';
      savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag0_nmax%d',nmax);
      system(sprintf('mkdir -p %s', savdir));
      qsubfeval('mous_execute_pipeline', ...
        'mous_hyperalignment_2sce_pipeline_forfigure0', 'V1001', {'parcel_indx' parcel_indx}, {'scenario' scenario}, ...
        {'nmax' nmax}, {'lags' lags}, {'timeshift' timeshift}, {'savdir', savdir}, 'timreq', tim*60, 'memreq', gb*(1024^3));
      
    end
    
%     for nmax = 1:4
%       tim = 60; % in minutes
%       gb  = 24+max(0,nmax-5).*5; % in gigabytes
%       
%       lags = -6:6;
%       timeshift = 'before';
%       normmethod = 'perchannel';
%       savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax%d_perchannel',nmax);
%       system(sprintf('mkdir -p %s', savdir));
%       qsubfeval('mous_execute_pipeline', ...
%         'mous_hyperalignment_2sce_pipeline_forfigure0', 'V1001', {'parcel_indx' parcel_indx}, {'scenario' scenario}, ...
%         {'nmax' nmax}, {'lags' lags}, {'timeshift' timeshift}, {'savdir', savdir}, {'normmethod', normmethod}, 'timreq', tim*60, 'memreq', gb*(1024^3));
%       
%     end
  end
end

makeplots = false;
if makeplots
  nlag = 0;
  nmax = 5;
  
  
  savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag%d_nmax%d',nlag,nmax);
  
  load atlas_conte69_8196reg_LR_brodmann_subparc
  parcel = {'L_44_B05_04';'L_22_B05_01';'L_22_B05_02';'L_22_B05_04';'L_22_B05_08';'L_22_B05_10'};
  sel = match_str(atlas.parcellationlabel, parcel);
  
  parcel_indx = sel(3)-2;
  
  load(fullfile(savdir, sprintf('mscca_sce1-4_parcel%03d',parcel_indx)));
  trc1.rho = (trc1.rho+trc2.rho)./2;
  trc1.rho(trc1.rho==1)=nan;
  dat = trc1.rho;
  n   = sqrt(size(dat,1));
  indx = tril(ones(n),-1);
  indx = indx(:)>0;
  dat  = dat(indx,:); % unique pairs
  
  mx = median(dat)';
  sx = prctile(dat,[25 75],1)'; % std
  figure;ciplot(trc1.time, mx, sx(:,1), sx(:,2), 'colormap', [0 0 0]);
  xlabel('time');
  ylabel('intersubject correlation (Z-transformed)');
  
end

