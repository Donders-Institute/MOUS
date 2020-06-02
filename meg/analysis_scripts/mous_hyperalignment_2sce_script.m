
docomputations = true;
if docomputations
  
  load atlas_conte69_8196reg_LR_brodmann_subparc
  parcel = {'L_44_B05_04';'L_22_B05_01';'L_22_B05_02';'L_22_B05_04';'L_22_B05_08';'L_22_B05_10'};
  sel = match_str(atlas.parcellationlabel, parcel);
  
  for k = 1:numel(sel)
    
    parcel_indx = sel(k)-2; % correct for ??? and medial wall offset in parcel index
    scenario = [1 4];
    
%     for nmax = 1:5
%       tim = 60; % in minutes
%       gb  = 24+max(0,nmax-5).*5; % in gigabytes
%       
%       lags = -6:6;
%       timeshift = 'before';
%       savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax%d',nmax);
%       system(sprintf('mkdir -p %s', savdir));
%       qsubfeval('mous_execute_pipeline', ...
%         'mous_hyperalignment_2sce_pipeline_forfigure0', 'V1001', {'parcel_indx' parcel_indx}, {'scenario' scenario}, ...
%         {'nmax' nmax}, {'lags' lags}, {'timeshift' timeshift}, {'savdir', savdir}, 'timreq', tim*60, 'memreq', gb*(1024^3));
%       
%     end
    for nmax = 1:5
      tim = 60; % in minutes
      gb  = 24+max(0,nmax-5).*5; % in gigabytes
      
      lags = 0;
      timeshift = 'none';
      savdir = sprintf('/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax%d',nmax);
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
  % nmax = 5;
  % lags = -6:6;
  % timeshift = 'before';
  % lambda = 10;
  % savdir = '/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax5_lambda10';
  % system(sprintf('mkdir -p %s', savdir));
  % mous_hyperalignment_2sce_pipeline_forfigure0;
  %
  %
  % nmax = 1;
  % lags = -6:6;
  % timeshift = 'before';
  % savdir = '/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax1';
  % system(sprintf('mkdir -p %s', savdir));
  % mous_hyperalignment_2sce_pipeline_forfigure0;
  %
  % nmax = 5;
  % lags = 0;
  % timeshift = 'none';
  % savdir = '/project/3011020.09/elecal/scenario1_4/forfigure/nlag0_nmax5';
  % system(sprintf('mkdir -p %s', savdir));
  % mous_hyperalignment_2sce_pipeline_forfigure0;
  %
  % nmax = 1;
  % lags = 0;
  % timeshift = 'none';
  % savdir = '/project/3011020.09/elecal/scenario1_4/forfigure/nlag0_nmax1';
  % system(sprintf('mkdir -p %s', savdir));
  % mous_hyperalignment_2sce_pipeline_forfigure0;
  %
  %
  % % this requires a lot of RAM
  % nmax = 10;
  % lags = -6:6;
  % timeshift = 'before';
  % savdir = '/project/3011020.09/elecal/scenario1_4/forfigure/nlag13_nmax10';
  % system(sprintf('mkdir -p %s', savdir));
  % mous_hyperalignment_2sce_pipeline_forfigure0;
  
end

