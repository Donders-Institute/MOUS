function [sourcemodel, newinside, oldinside] = mous_bfica_leadfield(subjectname, freq, toi, res)

if nargin<4
  res = 10;
end

% Do time slice selection first. In a previous version of the code the
% selection only took place after balancing for trials, and there was no
% check for NaN trials. This has been corrected as of Feb27, 2013. FIXME:
% notify Izabela, who is using an old version of this code
if nargin>2 && ~isempty(toi)
  % toi exist
  tmp = ft_selectdata(freq, 'toilim', toi+[-0.4 0.4]*mean(diff(freq.time)));
  tmp = rmfield(tmp, 'time');
  nans = ~isfinite(tmp.fourierspctrm(:,1));
  ntap = tmp.cumtapcnt(1);
  if ~all(tmp.cumtapcnt==ntap), error('different number of tapers per trial not supported here');end
  nans = reshape(nans,ntap,[]);
  fprintf('removing %d trials due to nans\n', sum(nans(1,:)));
  tmp.fourierspctrm(nans(:),:) = [];
  tmp.trialinfo(nans(1,:),:)   = [];
  tmp.cumtapcnt(nans(1,:))     = [];
  tmp.dimord = 'rpttap_chan_freq';
  
  % identify ~finite trials, i.e. where the selected time slice coincided
  % with an artifact in the original data
  
else
  % concatenate all tois
  if isfield(freq, 'time'),
    tmp = mtmconvol2mtmfft(freq, 200);
  else
    tmp = freq;
  end
end
freq = tmp; clear tmp; 

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

% select trials that (1) have latency of interest 
%                    (2) balanced between conditions (sentences and sequences)
% mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_balanced_-02-05ds}');
% freq = ft_selectdata(freq, 'rpt', data.seltotal);

% suff = '_balanced_-02-05ds';
% mous_db_getdata(subjectname, ['meg_bfica_freq', suff], rootdir);

% get necessary geometrical information
headmodel = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
sourcemodel = mous_db_getdata(subjectname, ['meg_anatomy_sourcemodel3D_nonlin',num2str(res),'mm']);

tmp = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparse');
tmp = ft_checkdata(tmp, 'cmbrepresentation', 'sparsewithpow');

% compute leadfields
cfg = [];
cfg.grid = sourcemodel;
cfg.vol = headmodel;
cfg.channel = 'MEG';
cfg.grad = ft_struct2double(freq.grad);
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

% estimate fwhm of spatial filters for voxel specific smoothing
cfg = [];
cfg.fwhm = 'yes';
source = ft_sourcedescriptives(cfg, source);
newinside = source.inside(:)';
oldinside = sourcemodel.inside(:)';
%newinside = sourcemodel.inside(:)';
%oldinside = sourcemodel.inside(:)';