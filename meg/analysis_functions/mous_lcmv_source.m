function [source, tlck, trialinfo] = mous_lcmv_source(subjectname, data, rootdir)

if nargin<3
  rootdir = '/project/3011020.09/jansch/';
end

% balance the number of replicates per condition
% (only sentences versus sequences
T    = data.trialinfo(:,2);
sel1 = find(ismember(T, [1 2 5 6])); n1 = numel(sel1);
sel2 = find(ismember(T, [3 4 7 8])); n2 = numel(sel2);

n    = min(n1,n2);
tmp1 = randperm(n1);
tmp2 = randperm(n2);
sel1 = sel1(sort(tmp1(1:n)));
sel2 = sel2(sort(tmp2(1:n)));

sel  = [sel1(:);sel2(:)];
data = ft_selectdata(data, 'rpt', sel);

cfg = [];
cfg.covariance   = 'yes';
cfg.channel      = 'MEG';
tlck = ft_timelockanalysis(cfg, data);

headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg', rootdir);

% compute leadfields
cfg         = [];
cfg.grid    = sourcemodel;
cfg.vol     = headmodel;
cfg.channel = 'MEG';
cfg.grad    = data.grad;
cfg.backproject = 'no';
sourcemodel = ft_prepare_leadfield(cfg);

% compute spatial filters
cfg                 = [];
cfg.method          = 'lcmv';
cfg.lcmv.fixedori   = 'no';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.lambda     = '5%';
cfg.vol             = headmodel;
cfg.grid            = sourcemodel;
%cfg.keepleadfield   = 'yes';
cfg.lcmv.projectnoise = 'yes';
source              = ft_sourceanalysis(cfg, tlck);
trialinfo           = data.trialinfo;
