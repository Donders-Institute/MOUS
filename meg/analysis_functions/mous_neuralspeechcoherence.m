function [data, coherence] = mous_neuralspeechcoherence(subjectname)
% This function calculates the coherence between the neural signal to the
% speech envelope

%% load raw data
dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

%% define trials, remove artifacts, preprocess data
if numel(dataset) == 1
  mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
  artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  [data, speech] = computedata(dataset{1}, artfctcfg);
 
elseif numel(dataset) > 1
  for k = 1:numel(dataset)
    tmpdataset = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg);
    
    if k==1,
      tmpsens1(k) = tmpdata.grad;
      weights1(k) = numel(tmpdata.trial);
      data       = tmpdata;
      
      tmpsens2(k) = tmpdata.grad;
      weights2(k) = numel(tmpdata.trial);
      speech     = tmpspeech;
    else
      % update the sentence counter
      tmpdata.trialinfo(:,1)   = tmpdata.trialinfo(:,1)   + data.trialinfo(end,1);
      tmpsens1(k)             = tmpdata.grad;
      weights1(k)             = numel(tmpdata.trial);
      data                   = ft_appenddata([], data, tmpdata);
      
      tmpspeech.trialinfo(:,1) = tmpspeech.trialinfo(:,1) + speech.trialinfo(end,1);
      tmpsens2(k)             = tmpdata.grad;
      weights2(k)             = numel(tmpdata.trial);
      speech                 = ft_appenddata([], speech, tmpspeech);
    end
    
  end
  data.grad   = ft_average_sens(tmpsens1, 'weights', weights1);   
  speech.grad = ft_average_sens(tmpsens2, 'weights', weights2);   
end

%% concatenate into one dataset
data = ft_appenddata([],data,speech);

%% cut the data into fragments with overlap (increase data - like welch method)
cfg = [];
cfg.length  = 2;  
cfg.overlap = 0.5; % 0 to 1 (exclusive)
data = ft_redefinetrial(cfg, data);

%% calculate power- and cross-spectra
%  mtmfft:   fourier spectra; contains amplitude and phase
%            Cross-spectral density matrix inferred from fourier matrix
%            (infer CSD from fourier coefficients)
%  powandcsd:  cross-spectra, power-spectra; 

cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'powandcsd'; 
cfg.foilim     = [0 60];         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 1;         % 2 Hz smoothing
% cfg.tapsmofrq  = 2;           % 4 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';     % keeptrials?? we don't use them
cfg.channel    = {'MEG' 'UADC003' 'audio_avg'};
cfg.channelcmb = {'MEG' 'UADC003';'MEG' 'audio_avg'};
freq           = ft_freqanalysis(cfg,data);

%% calculate coherence 
% mkdir('nscoh') %neuralspeechcoherence
cfg = [];
cfg.method      = 'coh';
cfg.channelcmb  = {'MEG' 'UADC003'};
coherence       = ft_connectivityanalysis(cfg,freq);
% NOTE: please don't save the data within the function, but pass output
% arguments
% ALSO: why save the time domain data as well (lots of space needed)
%mous_db_putdata(subjectname,'meg_other_neuspeechcoh_tapsmofrq1_trialdur2','coherence','data','/project/3011020.09/MEG/',1);


function [data, speech] = computedata(dataset, artfctcfg)

%% define trial
cfg                   = [];
cfg.dataset           = dataset;
cfg.trialfun          = 'trialfun_auditory_sentence';
cfg.trialdef.prestim  = 'audioonset';
cfg.trialdef.poststim = 0.2;
cfg = ft_definetrial(cfg);

%% define audio onset to be time point 0, and remove artifacts
trl = cfg.trl;
trl(:,3) = 0;
trl = mous_artifact_remove(trl, dataset, artfctcfg, 'partial', 1); % don't do the horizontal EOG

%% preprocess neural data and speech audio file
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
cfg.bsfreq     = [49 51];
cfg.bsfilttype = 'firws';
cfg.usefftfilt = 'yes';
data           = ft_preprocessing(cfg);

cfg.channel    = 'UADC003';
cfg.hpfilter   = 'yes';
cfg.hpfreq     = 10;     % remove slow drifts/fluctations. envelope is determined by high frequency activity
cfg.rectify    = 'yes';  % XOR: hilbert transform or rectify (in data make -ve values +ve using abs())
% cfg.boxcar     = 0.025;  % remove boxcar!
speech         = ft_preprocessing(cfg);

% load in the audioenvelopes as constructed from the wav files.
previous_sentid = 0;
for k = 1:numel(data.trial)
  sentid = num2str(data.trialinfo(k,5),'%03d');
  if previous_sentid ~= sentid
    load(fullfile('/project/3011020.09/MEG/misc/audiostimuli',['audiodata_envelope',sentid]));
  end
  i1 = nearest(audio.time{1},data.time{k}(1));
  i2 = nearest(audio.time{1},data.time{k}(end));
  i3 = nearest(data.time{k},audio.time{1}(1));
  i4 = nearest(data.time{k},audio.time{1}(end));
  speech.trial{k}(2,:) = 0;
  speech.trial{k}(2,i3:i4) = audio.trial{1}(end,i1:i2);
  previous_sentid = sentid;
end
speech.label = [speech.label;{'audio_avg'}];

%% downsample
% ASK:  why downsample and then concatenate dataset
%       is it not better to concatenate prior to downsampling?
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);

%% plot and inspect peaks in coherence spectrum
%   manual inspection is probably better?
% only project frequencies with large coherence into source space

% 
% %%%%%%%%%%%%%%%%
% %%% Plotting %%%
% %%%%%%%%%%%%%%%%
%% sensor level plotting
% cfg                  = [];
% cfg.parameter        = 'cohspctrm';
% cfg.xlim             = [0 60];
% % cfg.ylim             = [0 0.2];
% % cfg.showlabels       = 'yes';
% cfg.refchannel       = 'UADC003';
% cfg.channel          = {'MRC32' 'MRC42' 'MRP23' 'MRP34' 'MRP35'};
% cfg.layout           = 'CTF275.lay';
% figure; ft_singleplotER(cfg, coherence)
% title('taps2')

% % source level plotting
% 
% % interpolate prior to plotting
% 
% % plot
% cfg = [];
% cfg.method        = 'ortho';
% cfg.funparameter  = 'avg.pow';
% ft_sourceplot(cfg,sourcecoh4);
% % ft_sourceplot(cfg,source_coh6);
