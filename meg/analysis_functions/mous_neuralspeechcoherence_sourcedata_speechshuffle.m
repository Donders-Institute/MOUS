function mous_neuralspeechcoherence_sourcedata_speechshuffle(subjectname,foi,numshuffle,varargin)
% mous_neuralspeechcoherence_sourcedata computes source-level data shuffled
% pairings of the MEG data and speech data
% Raw data is preprocessed once, and then use for all coherence calculations 
% NL 01-06-2015

if nargin < 4
  datpp = [];
elseif nargin == 4
  datpp = varargin{1};
end

%% PREPROCESS DATA
if isempty(datpp)

  % load raw data
  dataset   = mous_db_getfilename(subjectname, 'meg_raw_task');

  % define trials, remove artifacts, preprocess data
  if numel(dataset) == 1
    mous_db_getdata(subjectname,'meg_artifact_cfg','/project/3011020.09/MEG/');
    artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [datpp, speech] = computedata(dataset{1}, artfctcfg);

  elseif numel(dataset) > 1
    for k = 1:numel(dataset)
      tmpdataset = dataset{k};
      mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
      tmpartfctcfg         = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
      [tmpdata, tmpspeech] = computedata(tmpdataset, tmpartfctcfg);

      if k==1,
        tmpsens1(k) = tmpdata.grad;
        weights1(k) = numel(tmpdata.trial);
        datpp       = tmpdata;

        tmpsens2(k) = tmpdata.grad;
        weights2(k) = numel(tmpdata.trial);
        speech     = tmpspeech;
      else
        % update the sentence counter
        tmpdata.trialinfo(:,1)  = tmpdata.trialinfo(:,1)   + datpp.trialinfo(end,1);
        tmpsens1(k)             = tmpdata.grad;
        weights1(k)             = numel(tmpdata.trial);
        datpp                   = ft_appenddata([], datpp, tmpdata);

        tmpspeech.trialinfo(:,1) = tmpspeech.trialinfo(:,1) + speech.trialinfo(end,1);
        tmpsens2(k)             = tmpdata.grad;
        weights2(k)             = numel(tmpdata.trial);
        speech                 = ft_appenddata([], speech, tmpspeech);
      end

    end
    datpp.grad   = ft_average_sens(tmpsens1, 'weights', weights1);   
    speech.grad = ft_average_sens(tmpsens2, 'weights', weights2);   
  end

  % concatenate into one dataset
  datpp = ft_appenddata([],datpp,speech);  % axial gradiometers, for subj-specific frequency search

  % cut the data into fragments with overlap (increase data - like welch method)
  cfg = [];
  cfg.length  = 2;  
  cfg.overlap = 0.5; % 0 to 1 (exclusive)
  datpp = ft_redefinetrial(cfg, datpp);
end

  % divide data
  cfg = [];
  cfg.trials = find(ismember(datpp.trialinfo(:,2),[1 5])); % sent
  data1  = ft_selectdata(cfg,datpp); 

  cfg.trials = find(ismember(datpp.trialinfo(:,2),[3 7])); % WL
  data2  = ft_selectdata(cfg,datpp); 

  
%% use peak frequency for each subject
% freq refers to frequency range of interest because a specific frequency has been
% predetermined for each subject (mous_neuralspeechcoherence_peakdetect)
% freq is the column index for the subjxfreq matrix
% 1 = delta; 2 = theta; 3 = alpha; 4 = beta;

% subj x freq range matrix
[subj,~] = mous_db_getfilename('allA','subjectname');
root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
load([root,'/coherencePeakdetect_stage2_thres001_smoothing_sent']);
idx      = find(ismember(subj,subjectname));

% get foi
switch foi
  case 'delta'
    freqcol = 1;
  case 'theta'
    freqcol = 2;
  case 'alpha'
    freqcol = 3;
  case 'beta'
    freqcol = 4;
end
foi         = peakfreqfirst(idx,freqcol);

% calculate fourier data (output is a fourier spectra)
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'fourier'; % not 'powandcsd; compute csd online in ft_sourceanalysis;
cfg.foi        = foi;         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 2;           % 4 Hz smoothing 10.04.2015 to be consistent with sensor-level results
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channel    = {'all' '-UADC003'};
fourier1       = ft_freqanalysis(cfg, data1);
fourier2       = ft_freqanalysis(cfg, data2);

% rpttap X chan
selchan = match_str(fourier1.label, {'audio_avg'});
fourier1.fourierspctrm(:,selchan,:) = fourier1.fourierspctrm(:,selchan,:)./abs(fourier1.fourierspctrm(:,selchan,:));
fourier2.fourierspctrm(:,selchan,:) = fourier2.fourierspctrm(:,selchan,:)./abs(fourier2.fourierspctrm(:,selchan,:));

% create a condition with sentence and word lists
cfg  = [];
cfg.parameter = 'fourierspctrm'; 
fourier3      = ft_appendfreq(cfg,fourier1,fourier2);

%% shuffle speech
% cannot shuffle prior to cutting data into fragments because each trial
% (sentence) is a different length

speechshuffle1 = zeros(size(fourier1.fourierspctrm,1),numshuffle);

% shuffle across blocks of tapers (taper 1-7 of one trial need to to stick together) 
for k = 1:numshuffle
  shuf = zeros(fourier1.cumtapcnt(1),numel(fourier1.cumtapcnt)); % tapers x trials
  shuf(:) = 1:numel(shuf);                                       % fill with indices 1-70
  shuf = shuf(:,randperm(size(shuf,2)));                         % shuffle 2nd dimension: taper block
  shuf = shuf(:);                                                % column vector
  speechshuffle1(:,k) = fourier1.fourierspctrm(shuf,selchan);    % output is correct, checked 11.06.2015NL
end
  
%% source-level
% load forward model (headmodel) 
headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

% load sourcemodel surfreg
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');

cfg = [];
cfg.method    = 'dics';
cfg.frequency = foi;
cfg.refchan   = 'audio_avg';
cfg.vol       = headmodel;
cfg.grid      = sourcemodel;
cfg.dics.fixedori     = 'yes';
cfg.dics.realfilter   = 'yes';  % consider real+complex filter; complex may try to rotate back to 'original phase'
cfg.dics.keepfilter   = 'yes'; 
cfg.dics.lambda       = '5%';
cfg.dics.projectnoise = 'yes';
cfg.grad      = fourier1.grad;
sourcesen     = ft_sourceanalysis(cfg,fourier1);

%% compute sensor-level shuffled coherence and project thru spatial filter
%  matrix multiply neural(fourierspectra) x %  speech(fourierspectra)  =
%  source projection of fourier values; does NOT calculate coherence

for k = 1:numshuffle
  freqdata           = fourier1;
  freqdata.fourierspctrm(:,selchan) = speechshuffle1(:,k);
  cfg.grid.filter    = sourcesen.avg.filter;
  tmp                = ft_sourceanalysis(cfg,freqdata);
  sourcesenshuf(:,k) = tmp.avg.coh;
end
% senscoh        = fourier1.fourierspctrm(:,1:273)'*speechshuffle1; % chan-rpttap X rpttap-1
% filter         = cat(1,sourcesen.avg.filter{:});  % 8196x273
% sourcesenshuf  = filter*senscoh;

mous_db_putdata(subjectname,'meg_coh_cohshuffle_sourcedata_delta','sourcesen','sourcesenshuf');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % average MEG-speechshuffle pairs
% for k = 1:numshuffle
%   if k == 1
%     senshuf = sourcesenshuf{k};
%     allshuf = sourceallshuf{k};
%   else
%     senshuf.avg.coh = senshuf.avg.coh + sourcesenshuf{k}.avg.coh;
%     allshuf.avg.coh = allshuf.avg.coh + sourceallshuf{k}.avg.coh;
%   end
% end
% 
% senshuf.avg.coh/numel(subj);
% allshuf.avg.coh/numel(subj);
% 
% %% pass sensor-level coherence through spatial filter
% for k = 1:numshuffle
%    
%   % create current MEG-speechshuffle pair
%   tmp1 = fourier1;
%   tmp1.fourierspctrm(:,selchan) = speechshuffle1(:,k); % column vector
%   
%   tmp3 = fourier3;
%   tmp3.fourierspctrm(:,selchan) = speechshuffle3(:,k);
%   
%   cfg.grid.filter = sourcesen.avg.filter;
%   sourcesenshuf{k}     = ft_sourceanalysis(cfg,tmp1);
%   cfg.grid.filter = sourceall.avg.filter;
%   sourceallshuf{k}     = ft_sourceanalysis(cfg,tmp3);
% end


% plot observed coherence

% plot average of shuffled coherence

% % return results
% varargout{1} = sourcesen;
% varargout{2} = sourceall;
% if nargout > 1
%   varargout{3} = datpp;
% end

%%%%%%%%%%%%%%%
%% subfunction%
%%%%%%%%%%%%%%%

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
trl = mous_artifact_remove(trl, dataset, artfctcfg, 'partial', 1); 

%% preprocess neural data and speech audio file
cfg.trl        = trl;
cfg.continuous = 'yes';
cfg.demean     = 'yes';
cfg.channel    = 'MEG';
cfg.bsfilter   = 'yes';  % temporary replacement for job of dftfilter
cfg.bsfreq     = [49 51];
cfg.bsfilttype = 'firws';
cfg.usefftfilt = 'yes';  % fftfilt used instead of firws
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
  if ~strcmp(previous_sentid,sentid)
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
cfg = [];
cfg.detrend     = 'no';
cfg.demean      = 'no';  
cfg.resamplefs  = 300;
data            = ft_resampledata(cfg,data);
speech          = ft_resampledata(cfg,speech);

    

