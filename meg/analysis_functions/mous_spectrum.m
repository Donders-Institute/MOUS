%function [freq, freqbaseline] = mous_spectrum(subjectname)
function mous_spectrum(subjectname)

filename = mous_db_getfilename(subjectname, 'meg_ds_task');

cfg          = [];
cfg.dataset  = filename{1};
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = 0.8;
cfg.trialdef.poststim = -1./1200;
cfg = ft_definetrial(cfg);
T1  = cfg.trl; % for the baseline

cfg = rmfield(cfg, 'trl');
cfg.trialdef.prestim  = 0.5;
cfg.trialdef.poststim = 1-1./1200;
cfg = ft_definetrial(cfg);
T2  = cfg.trl; % for the post word onset spectra

% cfg for preprocessing
cfg1 = [];
cfg1.dataset = filename{1};
cfg1.channel = 'MEG';
cfg1.demean  = 'yes';
cfg1.continuous = 'yes';
cfg1.padding = 2;
cfg1.dftfilter = 'yes';
cfg1.feedback  = 'none';

% cfg for freqanalysis
cfg2 = [];
cfg2.method = 'mtmfft';
cfg2.output = 'pow';
cfg2.foilim = [0 120];
%cfg2.taper  = 'dpss';
%cfg2.tapsmofrq = 2;
cfg2.taper     = 'hanning';
cfg2.feedback  = 'none';

% process baseline
cfg1.trl     = T1(T1(:,8)==1,:);
data         = ft_preprocessing(cfg1);
freq         = ft_freqanalysis(cfg2, data);
freqbaseline = freq;
clear data freq;

cfg2        = [];
cfg2.method = 'mtmconvol';
cfg2.output = 'pow';
cfg2.foi    = 2.5:2.5:40;
cfg2.t_ftimwin = ones(1,numel(cfg2.foi))*0.4;
cfg2.taper  = 'hanning';
cfg2.toi    = -0.3:0.05:0.8;
cfg2.pad    = 2;
%cfg2.keeptrials = 'yes';

nwords = max(T2(:,8));
for k = 1:nwords
  cfg1.trl = T2(T2(:,8)==k,:);
  data     = ft_preprocessing(cfg1);
  nsmp     = cellfun('size', data.trial, 2);
  cfg2.trials = find(ismember(data.trialinfo(:,2),[1 2 5 6]) & nsmp(:)==1800);
  freq{k,1}   = ft_freqanalysis(cfg2, data);
  cfg2.trials = find(ismember(data.trialinfo(:,2),[3 4 7 8]) & nsmp(:)==1800);
  freq{k,2}   = ft_freqanalysis(cfg2, data);
  clear data;
end

mous_db_putdata(subjectname,'meg_processed_{freqTFRword}',freq,freqbaseline);


