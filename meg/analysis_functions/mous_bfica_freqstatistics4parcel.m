function mous_bfica_freqstatistics4parcel(subjectnames,sourcedata,frange,rootdir,varargin) %,varargin{:}) %roi,foi,toi)
% Statistical analyses on an AAL-parcellated 8mm grid
% input = freq data 
% Input data can come in 2 forms both containing 1 value per parcel i.e.
% one voxel per parcel
% (1) average of voxels within a parcel 
%     this option loads parcellated data
% (2) maximum voxel within a parcel (subject specific max. voxel)
%     this option loads voxel data (non-parcellated) and the voxel with the
%     highest power amongst all voxels belonging to a parcel is selected  
% For details on how the maximum voxel is chosen see mous_bfica_maxvoxel
% varargin: 3 possibilities to be entered in a specific order
% roi: which parcel out of 1 to 330
% foi: which frequency(ies)
% toi: which time point(s)

if nargin < 2
  error('specify sourcedata e.g., "meg_bfica_sourcedatasentseq_low_parcelavg", or "meg_bfica_sourcedatasentseq_low"');
end 

if nargin < 4
  rootdir = '/project/3011020.09/MEG/';
end

if nargin < 5
  warning('no parcels (roi) in AAL template specified, all 330 used for analysis')
  roi.savename = 'LR4allparcels';
  roi.index = 1:330;
elseif nargin >= 5
  roi = varargin{1};
  if isempty(roi.savename) || isempty(roi.index)
    error('you are missing a filename for saving the statistics on the ROI and/or the indices for the ROIs to be selected');
  end
end

if nargin < 6
  warning('no foi specified'); 
elseif nargin >= 6
  foi = varargin{2};
end
  
if nargin < 7
  warning('no toi specified');
elseif nargin >= 7
  toi = varargin{3};
end

% aal parcellation template
load('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm_parcellated_aal_sub');
aal = sourcemodel;

% load regular sourcemodel (3d8mm)
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);

% get insides: (5782 new inside; 5219 new outside)
lf = mous_db_getdata('V1001','meg_bfica_leadfield8mm','/project/3011020.09/MEG/');
sourcemodel.inside = lf.newinside;

% create structure for statistics
dat1 = cell(1,numel(subjectnames));
dat2 = cell(1,numel(subjectnames));

%% make parcel
if regexp(sourcedata,'parcelavg')  % average across voxels in parcel
  for k = 1:numel(subjectnames)
     mous_db_getdata(subjectnames{k},sourcedata,rootdir);  % name has "parcelavg" in it

    % select roi,foi,toi (optional)
    cfg = [];
    cfg.channel = roi.index;
    if exist('foi','var')
      cfg.foilim = foi;
    end
    if exist('toi','var')
      cfg.latency = toi;
    end     
    tlcksent = ft_selectdata(cfg, tlcksent);
    tlckseq  = ft_selectdata(cfg, tlckseq);

    % enter relevant (selected) data into cell array
    dat1{k} = tlcksent;
    dat2{k} = tlckseq;
  end  % end subject loop
  
  %subtract baseline  
  % assumes that dat1/dat2 contain entire trial: bsl until 0.5s
  ix  = find(dat1{1}.time<=-0.09);  % baseline duration ( (-0.15 &) -0.10): set at -0.09 due to matlab rounding
  for k = 1:numel(dat1)
    tmp = dat1{k}.powspctrm;
    bsl = nanmean(tmp(:,:,ix),3);        % 2D: vox x freq 
    bsl = repmat(bsl,[1,1,size(tmp,3)]); % repmat on time dimension
    dat1{k}.powspctrm = (tmp./bsl)-1;   % change to relative difference (on 26 June, decrease effects of 1/f)
    
    
    tmp = dat2{k}.powspctrm;
    bsl = nanmean(tmp(:,:,ix),3);
    bsl = repmat(bsl,[1,1,size(tmp,3)]);
    dat2{k}.powspctrm = (tmp./bsl)-1;
  end
  
else
  for k = 1:numel(subjectnames)    % use maximum voxel within parcel
    
    % sentseq target
    if ~isempty(regexp(sourcedata,'tar')) && isempty(regexp(sourcedata,'par'))
      mous_db_getdata(subjectnames{k},sourcedata,rootdir);
      tlcksent = tlcksenttar;
      tlckseq  = tlckseqtar; 
      
    % sentseq parametric
    elseif ~isempty(regexp(sourcedata,'par')) && isempty(regexp(sourcedata,'tar'))
      mous_db_getdata(subjectnames{k},['meg_bfica_sourcedatasentpar_',frange,'_bslabsolute'],rootdir);
      tlcksent = tlcksentpar;
      mous_db_getdata(subjectnames{k},['meg_bfica_sourcedataseqpar_',frange,'_bslabsolute'],rootdir);
      tlckseq  = tlckseqpar;
      
    % sentseq target parametric
    elseif ~isempty(regexp(sourcedata,'par')) && ~isempty(regexp(sourcedata,'tar'))
      mous_db_getdata(subjectnames{k},['meg_bfica_sourcedatasentpartar_',frange,'_bslabsolute'],rootdir);
      tlcksent = tlcksentpartar;
      mous_db_getdata(subjectnames{k},['meg_bfica_sourcedataseqpartar_',frange,'_bslabsolute'],rootdir);
      tlckseq = tlckseqpartar;  
    
    % sent MX vs sentRC 
    elseif regexp(sourcedata,'sentMXRC')
      mous_db_getdata(subjectnames{k},sourcedata,rootdir);
      tlcksent = tlcksentRC;
      tlckseq  = tlcksentMX;
    
    % sentseq allwords contrast
    else 
      mous_db_getdata(subjectnames{k},sourcedata,rootdir);
    end
    
    % get maximum voxel list: voxel position (not it's corresponding index in sourcemodel.inside)
%     load(['/project/3011020.09/MEG/',subjectnames{k}, filesep,'bfica',filesep,subjectnames{k},'_bfica_sourcedatasentseq_',frange,'_voxlist4parcels_330parcels_usingbslVSsentseq_0205.mat']);
    load(['/project/3011020.09/MEG/',subjectnames{k}, filesep,'bfica',filesep,subjectnames{k},'_bfica_sourcedatasentseq_',frange,'_bslabsolute_voxlist4parcels_330parcels_usingbslVSsentseq_0205.mat']);
    
    % post stim
    cfg = [];
    if exist('foi','var')
      cfg.foilim = foi;
    end
    if exist('toi','var')
      cfg.latency = toi;
    end
    tmpsent = ft_selectdata(cfg,tlcksent);
    tmpseq = ft_selectdata(cfg,tlckseq);

    % pre stim
    cfg = [];
    if exist('foi','var')
      cfg.foilim = foi;
    end
    bslsent = ft_selectdata(cfg,tlcksent);
    bslseq = ft_selectdata(cfg,tlckseq);
    
    % update dat1,dat2 to retain only the necessary parcels
    % note: voxlist is in order of parcels (1:330); same order for all subjects
    % set up full data structure (including all fields)
    dat1{k} = tmpsent;
    dat2{k} = tmpseq;

    for kk = 1:numel(roi.index) 
      % get data for roi
      i = find(sourcemodel.inside == voxlist(roi.index(kk),2));    
      dat1{k}.powspctrm(kk,:,:) = tmpsent.avg(i,:,:);
      dat2{k}.powspctrm(kk,:,:) = tmpseq.avg(i,:,:); 
      
      % get bsl for roi
      bsl1 = nanmean(bslsent.avg(i,:,:),3); % select vox*freq*time, average on time
      bsl2 = nanmean(bslseq.avg(i,:,:),3); 
            
      % subtract bsl
      tmp = dat1{k}.powspctrm(kk,:,:);
      bsl1 = repmat(bsl1,[1,1,size(tmp,3)]);  % repmat bsl on time
      dat1{k}.powspctrm(kk,:,:) = (tmp./bsl1)-1;
      
      tmp = dat2{k}.powspctrm(kk,:,:);
      bsl2 = repmat(bsl2,[1,1,size(tmp,3)]);
      dat2{k}.powspctrm(kk,:,:) = (tmp./bsl2)-1;
    end 
    
    % remove unnecessary fields
    fd = {'avg','var','dof'};
    dat1{k} = rmfield(dat1{k},fd);
    dat2{k} = rmfield(dat2{k},fd);
    
    % update label for FieldTrip to understand dimord
    dat1{k}.label = aal.tissuelabel(roi.index);
    dat2{k}.label = aal.tissuelabel(roi.index);
    
  end % end subject loop
end % end type of parcellation choice


% specify empty neighbourhood structure to allow for clustering options
% parameters for stats calculation
Nsubj = numel(subjectnames);
cfg = [];
cfg.statistic = 'depsamplesT';
cfg.method = 'montecarlo';
cfg.clusterthreshold = 'parametric';
cfg.clusteralpha = 0.05;
cfg.clusterstatistic = 'maxsum';
% cfg.alpha = 0.05; % default
cfg.correctm = 'cluster';
cfg.neighbours = [];
cfg.numrandomization = 2000; % 30subj = 600; 72subj = 1400;  102 subj = 2000
              % conditionA  %conditionB      %subj   %subj
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'powspctrm';
[stat] = ft_freqstatistics(cfg, dat1{:},dat2{:});

savedir = '/project/3011020.09/nielam/groupresults/bfica_parcel/visual/';

%note if sentMXRC contrast, tlcksent(dat1) = RC, tlckseq(dat2) = MX
if isempty(regexp(sourcedata,'parcelavg'))
  save([savedir, sourcedata(11:end),'_maxvoxelparcel_',num2str(Nsubj),'subj_',roi.savename],'stat','roi');
else
  roilabels = tlcksent.label;
  save([savedir, sourcedata(11:end),'_parcelavg_',num2str(Nsubj),'subj_',roi.savename],'stat','roi','roilabels');
end


