function mous_bfica_freqstatistics4parcel(subjectnames,sourcedata,rootdir,varargin) %,varargin{:}) %roi,foi,toi)
% Statistical analyses on an AAL-parcellated 8mm grid
% input = freq data 
% Input data can come in 2 forms both containing 1 value per parcel i.e.
% one voxel per parcel
% (1) average of voxels within a parcel 
% (2) maximum voxel within a parcel (subject specific max. voxel)
% For option 2 see mous_bfica_maxvoxel for details
% varargin: 3 possibilities to be entered in a specific order
% roi: which parcel out of 1 to 330
% foi: which frequency(ies)
% toi: which time point(s)

if nargin < 2
  error('specify sourcedata e.g., "meg_bfica_sourcedatasentseq_low_parcelavg", or "meg_bfica_sourcedatasentseq_low"');
end 

if nargin < 3
  rootdir = '/project/3011020.09/MEG/';
end

if nargin < 4
  warning('no parcels (roi) in AAL template specified, all 330 used for analysis')
  roi.savename = 'LR4allparcels';
elseif nargin == 4
  roi = varargin{4};
  if isempty(roi.savename) || isempty(roi.index)
    error('you are missing a filename for saving the statistics on the ROI and/or the indices for the ROIs to be selected');
  end
end

if nargin < 5
  warning('no foi specified'); 
elseif naragin == 5
  foi = varargin{5};
end
  
if nargin < 6
  warning('no toi specified');
elseif nargin == 6
  toi = varargin{6};
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

%% select maximum voxel representing parcel 
if regexp(sourcedata,'parcelavg')
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
  
else
  for k = 1:numel(subjectnames)
    % get data
    mous_db_getdata(subjectnames{k},sourcedata,rootdir); 
    % get max. voxel list
    load(['/project/3011020.09/MEG/',subjectnames{k}, filesep,'bfica',filesep,subjectnames{k},'_bfica_sourcedata_voxlist4parcels_330parcels_usingbslVSsentseq0205.mat']);

    % list is in order of parcels (1:330); same order for all subjects
    dat1{k} = tlcksent; 
    dat2{k} = tlckseq;

    for kk = 1:330 % # parcels  
      i = find(sourcemodel.inside == voxlist(kk,2));
      %   tmp = tlcksent.avg(i,:,7:13);
      %   dat1.powspctrm(k,:,: = mean(tmp(:));
      dat1{k}.powspctrm(kk,:,:) = tlcksent.avg(i,:,:);

    %   tmp = tlckseq.avg(i,:,7:13);
    %   dat2.powspctrm = mean(tmp(:));
      dat2{k}.powspctrm(kk,:,:) = tlckseq.avg(i,:,:); 
    end 
    
    % remove unnecessary fields
    fd = {'avg','var','dof'};
    dat1{k} = rmfield(dat1{k},fd);
    dat2{k} = rmfield(dat2{k},fd);
    
    % update label for FieldTrip to understand dimord
    dat1{k}.label = aal.tissuelabel; 
    dat2{k}.label = aal.tissuelabel; 
    
  end % end subject loop
end % end type of parcellation choice

%subtract baseline  
ix = find(dat1{1}.time<=-0.09);  % baseline duration ( (-0.15 &) -0.10): set at -0.09 due to matlab rounding
for k = 1:numel(dat1)
  tmp = dat1{k}.powspctrm;
  bsl = nanmean(tmp(:,:,ix),3);
  dat1{k}.powspctrm = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

  tmp = dat2{k}.powspctrm;
  bsl = nanmean(tmp(:,:,ix),3);
  dat2{k}.powspctrm = tmp - repmat(bsl,[1,1,size(tmp,3)]);
end

% specify empty neighbourhood structure to allow for clustering options

% parameters for stats calculation
Nsubj = numel(subjectnames);
cfg = [];
cfg.statistic = 'depsamplesT';
cfg.method = 'montecarlo';
cfg.clusterthreshold = 'parametric';
cfg.clusteralpha = 0.01;
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
roilabels = tlcksent.label;

if isempty(regexp(sourcedata,'parcelavg'))
  save([savedir, sourcedata(11:end),'_maxvoxelparcel_',num2str(Nsubj),'subj_',roi.savename],'stat','roilabels');
end
% save([savedir, sourcedata(11:end),'_',num2str(Nsubj),'subj_',roi.savename],'stat','roi','roilabels');

