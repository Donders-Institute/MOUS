function [source_parc, filterlabel, source] = mous_multisetcca_lcmv(subjectname, data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% computation of the covariance matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get rid of the nans
fsample = 1./mean(diff(data.time{1}));
for k = 1:numel(data.trial)
  data.trial{k}(:,~isfinite(data.trial{k}(1,:))) = [];
  data.time{k} = (0:(size(data.trial{k},2)-1))./fsample;
end
nsmp = cellfun('size',data.time,2);
data.trial = data.trial(nsmp>0);
data.time  = data.time(nsmp>0);

cfg = [];
cfg.channel = 'MEG';
data = ft_selectdata(cfg, data);

cfg              = [];
cfg.covariance   = 'yes';
cfg.vartrllength = 2;
cfg.channel      = 'MEG';
tlck = ft_timelockanalysis(cfg, data);

data.trial{1} = cat(2,data.trial{:});
data.trial    = data.trial(1);
data.time     = {(0:(size(data.trial{1},2)-1))./fsample};

tmp = ft_timelockanalysis(cfg, data);
tlck.cov = tmp.cov; clear tmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preparation of the anatomical data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load the 2D sourcemodel and deal with the midline
mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D_surfreg');
if exist('bnd', 'var')
  sourcemodel = bnd;
  clear bnd;
end
if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
  sourcmodel.pos = sourcemodel.pnt;
  sourcemodel    = rmfield(sourcemodel, 'pnt');
end
sourcemodel = ft_convert_units(sourcemodel, 'm');

% define the medial wall parcel as outside. NOTE: this assumes
% the medial wall te have a value of 2
load atlas_conte69_8196reg_LR_brodmann_subparc
sourcemodel.inside  = find(~ismember(atlas.parcellation,[1 2 194 195]));
sourcemodel.outside = find( ismember(atlas.parcellation,[1 2 194 195]));

% load the volume conduction model of the head
mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
if exist('vol', 'var')
  headmodel = vol;
  clear vol;
end
headmodel = ft_convert_units(headmodel, 'm');

% pre-compute the leadfields
cfg          = [];
cfg.grad     = tlck.grad;
cfg.headmodel = headmodel;
cfg.grid     = sourcemodel;
cfg.channel  = 'MEG';
cfg.feedback = 'textbar';
sourcemodel  = ft_prepare_leadfield(cfg, tlck);

cfg = [];
cfg.method = 'lcmv';
cfg.headmodel = headmodel;
cfg.grid      = sourcemodel;
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.fixedori   = 'yes';
cfg.lcmv.lambda     = '100%';
cfg.lcmv.weightnorm = 'unitnoisegain';
source = ft_sourceanalysis(cfg, tlck);
F      = zeros(size(source.pos,1),numel(tlck.label));
F(source.inside,:) = cat(1,source.avg.filter{:});

% prepare the cfg for pca
cfg                       = [];
cfg.method                = 'pca';

tmp     = rmfield(data, {'elec' 'grad'});
selparc = setdiff(1:numel(atlas.parcellationlabel),[1 2 194 195]); % hard coded exclusion of midline and ???

source_parc.label = atlas.parcellationlabel(selparc);
source_parc.time  = tlck.time;
source_parc.F     = cell(numel(source_parc.label),1);
source_parc.avg   = zeros(numel(selparc),numel(source_parc.time));
source_parc.dimord = 'chan_time';

for k = [111 112]%1:numel(selparc)
  tmpF = F(atlas.parcellation==selparc(k),:);
  tmp.trial = tmpF*data.trial;
  tmp.label = data.label(1:size(tmpF,1));
  tmpcomp   = ft_componentanalysis(cfg, tmp);

  source_parc.F{k}     = tmpcomp.unmixing*tmpF;
  source_parc.avg(k,:) = source_parc.F{k}(1,:)*tlck.avg;
end
filterlabel = tlck.label; % keep track of the channels that went into the spatial filters
