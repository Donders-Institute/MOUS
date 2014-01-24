function [comp, comp2, avgpre, avgcomp, avgpst, sel1, sel2, compsel, fdlow, fdhigh, cohlow, cohhigh, icohlow, icohhigh] = mous_restingstate_cardiacconfound(subjectname)

rootdir     = '/project/3011020.09/jansch';

%% load the data
mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
eval('ecgdata = ecg;');
data = ft_appenddata([], data, ecgdata);

%if strcmp(subjectname, 'V1020')
  % for an unknown reason the last trial(s) contains a lot of 0's
  data = ft_selectdata(data, 'rpt', 1:(numel(data.trial)-2));
%end

%% cut into 2-second snippets
cfg         = [];
cfg.length  = 2;
cfg.overlap = 0.5;
data        = ft_redefinetrial(cfg, data);

%% extract the spatial components that look like cardiac activity
[comp, avgpre, avgcomp] = mous_restingstate_dss(data);

%% reject cardiac components
v = var(avgcomp,[],2);
v = v./v(1);

cfg           = [];
cfg.component = find(v>0.05);
data2         = ft_rejectcomponent(cfg, comp, data);
s.state       = 1;
params        = comp.cfg.dss.denf.params;
[~,~,avgpst]  = denoise_avg2(params, data2.trial, s);


%% do an ordinary ICA on the cardiac-cleaned data
% to be able to select a 'dipole' component,
% based on which to divide the trials
cfg                 = [];
cfg.method          = 'fastica';
cfg.cellmode        = 'yes';
cfg.fastica.g       = 'tanh';
cfg.fastica.lastEig = 50;
cfg.fastica.maxNumIterations = 2000;
cfg.numcomponent    = 50;
cfg.channel         = 'MEG';
comp2               = ft_componentanalysis(cfg, data2);

%% spectral analysis of component time series
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 40];
cfg.tapsmofrq = 1;
freq2         = ft_freqanalysis(cfg, comp2);

%% pick a component with a strong alpha peak
ix  = nearest(freq2.freq, 10);
tmp = freq2.powspctrm(:,ix);
[sx, ix] = sort(tmp, 'descend');
compsel  = ix(1);

%% split the trials according to the single trial alpha of the identified
% component
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.foilim = [0 40];
cfg.tapsmofrq = 1;
cfg.keeptrials = 'yes';
cfg.channel    = comp2.label(compsel);
freq2trials    = ft_freqanalysis(cfg, comp2);

ix  = nearest(freq2.freq, 10);
tmp = freq2trials.powspctrm(:,:,ix);
[sx, ix] = sort(tmp, 'ascend');
n   = numel(ix);
n   = floor(n/2);

% sel1 contains the trials with low alpha power for the identified
% component, sel2 contains the trials with high alpha power for the
% identified component
sel1 = sort(ix(1:n));
sel2 = sort(ix((end-n+1):end));

% split the data
datalow  = ft_selectdata(data, 'rpt', sel1);
datahigh = ft_selectdata(data, 'rpt', sel2);

%% do spectral analysis for the high and low amplitude trials separately
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
cfg.foilim = [0 40];
cfg.tapsmofrq = 1;
freqlow  = ft_freqanalysis(cfg, datalow);
freqhigh = ft_freqanalysis(cfg, datahigh);

% for computational efficiency
tmplow  = ft_checkdata(freqlow, 'cmbrepresentation', 'fullfast');
tmphigh = ft_checkdata(freqhigh, 'cmbrepresentation', 'fullfast'); 

%% compute connectivity
cfg = [];
cfg.method  = 'coh';
cohlow  = ft_connectivityanalysis(cfg, tmplow);
cohhigh = ft_connectivityanalysis(cfg, tmphigh);
cfg.complex = 'imag';
icohlow  = ft_connectivityanalysis(cfg, tmplow);
icohhigh = ft_connectivityanalysis(cfg, tmphigh);

% differential coherence
cohdelta = cohlow;
cohdelta.cohspctrm = cohlow.cohspctrm-cohhigh.cohspctrm;

% differential imaginary part of coherency
icohdelta = icohlow;
icohdelta.cohspctrm = icohlow.cohspctrm-icohhigh.cohspctrm;

%% visualization
% cfg             = [];
% cfg.layout      = 'CTF275.lay';
% cfg.interactive = 'yes';
% cfg.refchannel  = 'EEG059';
% cfg.parameter   = 'cohspctrm';
% figure;ft_topoplotTFR(cfg, cohlow);
% figure;ft_topoplotTFR(cfg, icohlow);
% figure;ft_topoplotTFR(cfg, cohdelta);
% figure;ft_topoplotTFR(cfg, icohdelta);

%% compute powerspectra
fdhigh = ft_freqdescriptives([], freqhigh);
fdlow  = ft_freqdescriptives([], freqlow);

%% show the relative difference
% figure;plot(fdlow.freq, fdhigh.powspctrm./fdlow.powspctrm);

%% visualization of the average across the helmet
fd              = fdlow;
% cfg             = [];
% cfg.layout      = 'CTF275.lay';
% cfg.interactive = 'yes';
% fd.powspctrm = fdhigh.powspctrm./fdlow.powspctrm;
% figure;ft_topoplotTFR(cfg, fd);
% fd.powspctrm = squeeze(mean(cohdelta.cohspctrm));
% figure;ft_topoplotTFR(cfg, fd);
% fd.powspctrm = squeeze(mean(icohdelta.cohspctrm));
% figure;ft_topoplotTFR(cfg, fd);


% %% reconstruct sensor-level data keeping the cardiac activity and the single
% % component only
% cfg = [];
% cfg.component = compsel;
% data3         = ft_rejectcomponent(cfg, comp2, data2);
% 
% for k = 1:numel(data3.trial)
%   data3.trial{k}(1:273,:) = ft_preproc_baselinecorrect(data.trial{k}(1:273,:)-data3.trial{k}(1:273,:));
% end
% 
% % split the data
% data3low  = ft_selectdata(data3, 'rpt', sel1);
% data3high = ft_selectdata(data3, 'rpt', sel2);
% 
% % do spectral analysis
% cfg        = [];
% cfg.method = 'mtmfft';
% cfg.output = 'fourier';
% cfg.foilim = [0 40];
% cfg.tapsmofrq = 1;
% freq3low  = ft_freqanalysis(cfg, data3low);
% freq3high = ft_freqanalysis(cfg, data3high);
% 
% tmp3low  = ft_checkdata(freq3low, 'cmbrepresentation', 'fullfast');
% tmp3high = ft_checkdata(freq3high, 'cmbrepresentation', 'fullfast'); 
% 
% % compute connectivity
% cfg = [];
% cfg.method  = 'coh';
% cohlow  = ft_connectivityanalysis(cfg, tmp3low);
% cohhigh = ft_connectivityanalysis(cfg, tmp3high);
% cfg.complex = 'imag';
% icohlow  = ft_connectivityanalysis(cfg, tmp3low);
% icohhigh = ft_connectivityanalysis(cfg, tmp3high);
% 
% c1 = reshape(cohlow.cohspctrm, 274.^2, []);
% c2 = reshape(cohhigh.cohspctrm, 274.^2, []);
% ic1 = reshape(icohlow.cohspctrm, 274.^2, []);
% ic2 = reshape(icohhigh.cohspctrm, 274.^2, []);
% 
% cohdelta = cohlow;
% cohdelta.cohspctrm = cohlow.cohspctrm-cohhigh.cohspctrm;
% 
% icohdelta = icohlow;
% icohdelta.cohspctrm = icohlow.cohspctrm-icohhigh.cohspctrm;
% 
% % visualization
% cfg             = [];
% cfg.layout      = 'CTF275.lay';
% cfg.interactive = 'yes';
% cfg.refchannel  = 'EEG059';
% cfg.parameter   = 'cohspctrm';
% figure;ft_topoplotTFR(cfg, cohlow);
% figure;ft_topoplotTFR(cfg, icohlow);
% figure;ft_topoplotTFR(cfg, cohdelta);
% figure;ft_topoplotTFR(cfg, icohdelta);
% 
% fdhigh = ft_freqdescriptives([], freq3high);
% fdlow  = ft_freqdescriptives([], freq3low);
% 
% figure;plot(fdlow.freq, fdhigh.powspctrm./fdlow.powspctrm);
% 
% fd = fdlow;
% 
% cfg             = [];
% cfg.layout      = 'CTF275.lay';
% cfg.interactive = 'yes';
% fd.powspctrm = fdhigh.powspctrm./fdlow.powspctrm;
% figure;ft_topoplotTFR(cfg, fd);
% fd.powspctrm = squeeze(mean(cohdelta.cohspctrm));
% figure;ft_topoplotTFR(cfg, fd);
% fd.powspctrm = squeeze(mean(icohdelta.cohspctrm));
% figure;ft_topoplotTFR(cfg, fd);
% 
