function [freq] = mous_bfica_freq(subjectname, frequency, rootdir, options)

if nargin==1
  frequency = 20;
end

if nargin<3
  rootdir = '/project/3011020.09/MEG/jansch';
end

if nargin<4
  options.tapsmofrq  = 8;
  options.t_ftimwin  = 0.25;
  options.resamplefs = 200;
else
  % don't define anything but rely on how it's dealt with below
end

dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');
if numel(dataset)>1
  for k = 1:numel(dataset)
    tmpdataset   = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    mous_db_getdata(subjectname, 'meg_bfica_comp', rootdir);           % one *combined) file for ecg components - see mous_bfica_dss.
    tmpcomp      = {avgcomp avgpre comp};
    tmpdata      = compute_data(tmpdataset, tmpartfctcfg, tmpcomp, options);
    
    if k==1,
      tmpsens(k) = tmpdata.grad;
      weights(k) = numel(tmpdata.trial);
      data       = tmpdata;
    else
      % update the sentence counter
      tmpdata.trialinfo(:,1) = tmpdata.trialinfo(:,1) + data.trialinfo(end,1);
      tmpsens(k)             = tmpdata.grad;
      weights(k)             = numel(tmpdata.trial);
      data                   = ft_appenddata([], data, tmpdata);
    end
  end
  data.grad = ft_average_sens(tmpsens, 'weights', weights);     
else
  mous_db_getdata(subjectname, 'meg_artifact_cfg');
  artfctcfg = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  mous_db_getdata(subjectname, 'meg_bfica_comp', rootdir);
  comp      = {avgcomp avgpre comp};
  data      = compute_data(dataset{1}, artfctcfg, comp, options);
end
freq = compute_freq(data, options, frequency);

function data = compute_data(dataset, artfctcfg, comp, options)

options.dftfilter = ft_getopt(options.dftfilter, 'no');
options.padding   = ft_getopt(options.padding, 0);

avgcomp   = comp{1};
avgpre    = comp{2};
comp      = comp{3};

% get data and apply artifact rejection
cfg          = [];
cfg.dataset  = dataset;
%cfg.trialfun = 'trialfun_visual_sentence';
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = 0.3;
cfg.trialdef.poststim = 'nextword';
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
%trl          = mous_artifact_remove(trl, dataset, artfctcfg([1 3 4]), 'partial', 1); % don't do the horizontal EOG
trl          = mous_artifact_remove(trl, dataset, artfctcfg([1 2 3 4]), 'partial', 1); % don't do the horizontal EOG
%dataStats    = mous_samplestats(trl);

% trl > 2 second does not make sense, sanity check: FIXME
nsmp = trl(:,2)-trl(:,1);
trl  = trl(nsmp<2400,:);

cfg            = [];
cfg.dataset    = dataset;
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.dftfilter  = options.dftfilter;
cfg.padding    = options.padding;
data           = ft_preprocessing(cfg);

% downsample
cfg            = [];
cfg.demean     = 'yes';
cfg.detrend    = 'no';
cfg.resamplefs = options.resamplefs;
data           = ft_resampledata(cfg, data);

% reject cardiac components
v = var(avgcomp,[],2);
v = v./v(1);

% dummy trial to fool ft_rejectcomponent
comp.trial = comp.time;

% NOTE: this avoids a crash later on, but not sure which grad structure is
% used in ft_rejectcomponent.
if isfield(comp,'grad')
    comp = rmfield(comp, 'grad');
end 

cfg           = [];
cfg.component = find(v>0.1);
data          = ft_rejectcomponent(cfg, comp, data);

function freq = compute_freq(data, options, frequency)

tapsmofrq  = ft_getopt(options, 'tapsmofrq', 8);
t_ftimwin  = ft_getopt(options, 't_ftimwin', 0.250);
taper      = ft_getopt(options, 'taper', 'dpss');

cfg        = [];
cfg.method = 'mtmconvol';
cfg.output = 'fourier';
cfg.toi    = -0.2:0.05:0.8;
cfg.foi    = frequency;
cfg.t_ftimwin = t_ftimwin;
cfg.tapsmofrq = tapsmofrq;
cfg.taper  = taper;
cfg.pad    = 4;
freq       = ft_freqanalysis(cfg, data);
warning off;
freq = ft_struct2single(freq);
