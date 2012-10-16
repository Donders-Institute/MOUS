function [source, trialinfo] = mous_bfica_source(subjectname, freq, toi)
  
% get necessary geometrical information
headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin10mm');

if nargin==3
  % toi exist
  tmp = ft_selectdata(freq, 'toilim', toi+[-eps eps]);
  tmp = ft_checkdata(tmp,  'cmbrepresentation', 'fullfast');
  tmp = ft_checkdata(tmp,  'cmbrepresentation', 'sparse');
  tmp = ft_checkdata(tmp,  'cmbrepresentation', 'sparsewithpow');
  tmp = rmfield(tmp, 'time');
else
  % concatenate all tois
  tmp = mtmconvol2mtmfft(freq, 200);
  tmp = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
  tmp = ft_checkdata(tmp,  'cmbrepresentation', 'sparse');
  tmp = ft_checkdata(tmp,  'cmbrepresentation', 'sparsewithpow');
end

% compute leadfields
cfg         = [];
cfg.grid    = sourcemodel;
cfg.vol     = headmodel;
cfg.channel = 'MEG';
cfg.grad    = freq.grad;
cfg.normalize = 'yes';
sourcemodel = ft_prepare_leadfield(cfg);

% compute spatial filters
cfg                 = [];
cfg.method          = 'dics';
cfg.frequency       = freq.freq;
cfg.dics.fixedori   = 'yes';
cfg.dics.realfilter = 'yes';
cfg.dics.keepfilter = 'yes';
cfg.dics.lambda     = '5%';
cfg.vol             = headmodel;
cfg.grid            = sourcemodel;
source              = ft_sourceanalysis(cfg, tmp);
trialinfo           = freq.trialinfo;
