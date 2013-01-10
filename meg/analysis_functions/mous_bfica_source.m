function [source, trialinfo] = mous_bfica_source(subjectname, freq, toi)

warning off;
freq = ft_struct2double(freq);
warning on;

% balance the number of replicates per condition
% (only sentences versus sequences
T = freq.trialinfo(:,2);
sel1 = find(ismember(T, [1 2 5 6])); n1 = numel(sel1);
sel2 = find(ismember(T, [3 4 7 8])); n2 = numel(sel2);

n = min(n1,n2);
tmp1 = randperm(n1);
tmp2 = randperm(n2);
sel1 = sel1(sort(tmp1(1:n)));
sel2 = sel2(sort(tmp2(1:n)));

sel = [sel1(:);sel2(:)];
freq = ft_selectdata(freq, 'rpt', sel);

% get necessary geometrical information
headmodel = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin10mm');

if nargin==3
  % toi exist
  tmp = ft_selectdata(freq, 'toilim', toi+[-eps eps]);
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparse');
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparsewithpow');
  tmp = rmfield(tmp, 'time');
else
  % concatenate all tois
  if isfield(freq, 'time'),
    tmp = mtmconvol2mtmfft(freq, 200);
  else
    tmp = freq;
  end
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparse');
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparsewithpow');
end

% compute leadfields
cfg = [];
cfg.grid = sourcemodel;
cfg.vol = headmodel;
cfg.channel = 'MEG';
cfg.grad = freq.grad;
cfg.normalize = 'yes';
sourcemodel = ft_prepare_leadfield(cfg);

% compute spatial filters
cfg = [];
cfg.method = 'dics';
cfg.frequency = freq.freq;
cfg.dics.fixedori = 'yes';
cfg.dics.realfilter = 'yes';
cfg.dics.keepfilter = 'yes';
cfg.dics.lambda = '5%';
cfg.vol = headmodel;
cfg.grid = sourcemodel;
cfg.keepleadfield = 'yes';
source = ft_sourceanalysis(cfg, tmp);
trialinfo = freq.trialinfo;

% estimate fwhm of spatial filters for voxel specific smoothing
cfg = [];
cfg.fwhm = 'yes';
source = ft_sourcedescriptives(cfg, source);