dataset = '/home/coherence/jansch/MOUS/data/p001BigUmVis_600hz_20110818_01.ds';

cfg          = [];
cfg.dataset  = dataset;
cfg.trialfun = 'word';
cfg2         = ft_definetrial(cfg);
cfg.trialfun = 'sentence';
cfg          = ft_definetrial(cfg);

cfg.channel    = {'MEG'};
cfg.demean     = 'yes';
cfg.continuous = 'yes';
data = ft_preprocessing(cfg);

% add at 'stim' channel
trial{1} = zeros(1, max(cfg.trl(:)));
trial{1}(cfg2.trl(:,1)) = cfg2.trl(:,end);

stim          = [];
stim.label{1} = 'STIM';
stim.time{1}  = (1:numel(trial{1}))/(mean(diff(data.time{1})));
stim.trial    = trial;

% redefine
cfg3     = [];
cfg3.trl = cfg.trl;
stim     = ft_redefinetrial(cfg3, stim);
stim.time = data.time;

% get eog
cfg.channel  = {'EEG057' 'EEG058'};
cfg.bpfilter = 'yes';
cfg.bpfreq   = [1 40];
eog          = ft_preprocessing(cfg);

% downsample
cfg            = [];
cfg.resamplefs = 200;
cfg.detrend    = 'no';
cfg.demean     = 'yes';
data = ft_resampledata(cfg, data);
eog  = ft_resampledata(cfg, eog);

for k = 1:numel(stim.trial)
  stim.time{k}  = data.time{k}
  tmp = zeros(3,size(stim.time{k},2));
  tmp(1:numel(stim.trial{k})) = stim.trial{k};
  stim.trial{k} = sum(tmp);
end

% post process eog data
eog  = ft_channelnormalise([], eog);

% compute peak times for eog
for k = 1:numel(eog.trial)
  p{k} = peakdetect2(eog.trial{k}(end,:),4,1);
end
sel = find(~cellfun('isempty', p));

% convert to linear array
nsmp = cellfun('size', eog.trial, 2);
[p,begsmp,endsmp] = peaks2continuous(p, nsmp, 60, 120);

% do componentanalysis
addpath /home/coherence/jansch/matlab/toolboxes/dss_1-0
params.tr = p(:);
params.tr_begin = begsmp(:);
params.tr_end   = endsmp(:);

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avgJM';
cfg.dss.denf.params   = params;
cfg.channel           = 'MEG';
cfg.numcomponent      = 20;
comp                  = ft_componentanalysis(cfg, data);

s.X           = 1;
[~,~,avgpre]  = denoise_avgJM(params,cat(2,data.trial{:}),s);
[~,~,avgcomp] = denoise_avgJM(params,cat(2,comp.trial{:}),s);

cfg           = [];
cfg.component = 1:5;
cfg.feedback  = 'textbar';
data2         = ft_rejectcomponent(cfg, comp, data);
[~,~,avgpst]  = denoise_avgJM(params,cat(2,data2.trial{:}),s);

data = data2;
clear data2;

clear p;

% do peak detection on the stim channel
for k = 1:numel(stim.trial)
  p{k} = peakdetect2(stim.trial{k}(end,:),0.9,1);
end

% convert to linear array
nsmp = cellfun('size', stim.trial, 2);
[p,begsmp,endsmp] = peaks2continuous(p, nsmp, 0, 200);

% do componentanalysis
addpath /home/coherence/jansch/matlab/toolboxes/dss_1-0
params.tr = p(:);
params.tr_begin = begsmp(:);
params.tr_end   = endsmp(:);

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avgJM';
cfg.dss.denf.params   = params;
cfg.channel           = 'MEG';
cfg.numcomponent      = 50;
comp2                 = ft_componentanalysis(cfg, data);

s.X           = 1;
[~,~,avgpre2]  = denoise_avgJM(params,cat(2,data.trial{:}),s);
[~,~,avgcomp2] = denoise_avgJM(params,cat(2,comp2.trial{:}),s);

cfg = [];
cfg.component = 26:50;
data2 = ft_rejectcomponent(cfg, comp2);


cfg = [];
cfg.preproc.demean = 'yes';
cfg.preproc.baselinewindow = [-0.1 0];
cfg.vartrllength = 2;
cfg.channel = 'MEG';
tlck = ft_timelockanalysis(cfg, data2);




cfg.channel = {'MEGREF' '-B*'};
%cfg.dftfilter = 'yes';
%cfg.dftinvert = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfilttype = 'fir';
cfg.bpfiltord  = 100;
cfg.bpfreq   = [48 52;98 102];
cfg.padding = 4;
refdata = ft_preprocessing(cfg);

dataorig = data;

% cfg = [];
% cfg.truncate = 3;
% cfg.shift    = (-2:2);
% data = ft_denoise_tsr(cfg, dataorig, refdata);


cfg = [];
cfg.method = 'summary';
data = ft_rejectvisual(cfg, data);

cfg = [];
cfg.toilim = [-0.5 0-1/300];
pre = ft_redefinetrial(cfg, data);
cfg.toilim = [0.25 0.75-1/300];
pst = ft_redefinetrial(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.keeptrials = 'yes';
cfg.foilim = [0 100];
cfg.tapsmofrq = 4;
%cfg.taper = 'hanning';
freqpre = ft_freqanalysis(cfg, pre);
freqpst = ft_freqanalysis(cfg, pst);
