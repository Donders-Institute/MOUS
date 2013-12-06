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
    tmpartfctcfg = mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpcomp      = mous_db_getdata(subjectname, 'meg_bfica_comp', rootdir);           % one *combined) file for ecg components - see mous_bfica_dss.
    tmpdata      = compute_data(tmpdataset, tmpartfctcfg, tmpcomp, options);
    if k==1,
      grad1 = tmpdata.grad;
      data  = tmpdata;
    else
      grad2 = tmpdata.grad; % assumes max. 2 datasets
      % FIXME! make it more generic, i.e. don't rely on only 2 datasets, 
      % and don't hard code subject names.     
 
      % update the sentence counter
      tmpdata.trialinfo(:,1) = tmpdata.trialinfo(:,1) + data.trialinfo(end,1);

      data  = ft_appenddata([], data, tmpdata);
      if strcmp(subjectname,'V1006')
          % dataset1: 177 trials vs. dataset2: 58 trials i.e. 3:1
          tmpsens(1) = grad1;
          tmpsens(2) = grad1;
          tmpsens(3) = grad1;
          tmpsens(4) = grad2;
          data.grad = ft_average_sens(tmpsens);
      elseif strcmp(subjectname,'V1090')
          % dataset1: 150 trials vs. dataset2: 88 trials i.e. 2:1
          tmpsens(1) = grad1;
          tmpsens(2) = grad1;
          tmpsens(3) = grad2; 
          data.grad = ft_average_sens(tmpsens); %FIXME: perhaps it's best to do the averaging outside the loop (is cleaner, and allows for > 2 datasets.
      end
    end       
  end
else
  artfctcfg = mous_db_getdata(subjectname, 'meg_artifact_cfg');
  comp      = mous_db_getdata(subjectname, 'meg_bfica_comp', rootdir);
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

