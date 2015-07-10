function [varargout] = mous_neuralneuralcoherence_sourcedata(subjectname,foi,cdtn,varargin)
% mous_neuralspeechcoherence_sourcedata computes source-level data for the
% specified frequency(ies).
% Raw data is preprocessed once, and then use for all coherence calculations 

% beamformer dics using refdip is inflexible:
% If give multiple refdips, a single dip is produced using SVD, instead of
  % an average across coherence values between all refdips
% Alternative is to give one refdip each time and calculate mean
  % from each output of ft_sourceanalysis
  % this is time consuming
% These methods don't account for the strong coherence that will occur to
  % vertices near the refdip. Coherence values are correlated to the distance
  % between refdip and dipole of interest.
% Considering something similar to partial coherence, where the activity
% from speech to audcortex is regressed out from the audcort to whole
% brain - see Schoffelen 2008

% NL 01-02-2015

if nargin < 5
  datpp = [];
elseif nargin == 5
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

  datpp = ft_appenddata([],datpp,speech);  % axial gradiometers, for subj-specific frequency search

  
  % cut the data into fragments with overlap (increase data - like welch method)
  cfg = [];
  cfg.length  = 2;  
  cfg.overlap = 0.5; % 0 to 1 (exclusive)
  datpp = ft_redefinetrial(cfg, datpp);


%% divide trials %%%%
% divide data
  cfg = [];
  cfg.trials = find(ismember(datpp.trialinfo(:,2),[1 5])); % sent
  data1  = ft_selectdata(cfg,datpp); 

  if strcmp(cdtn,'common') || strcmp(cdtn,'wl')
    cfg.trials = find(ismember(datpp.trialinfo(:,2),[3 7])); % WL
    data2  = ft_selectdata(cfg,datpp); 
  end
  
end % end preprocessing steps

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

%% calculate fourier data (output is a fourier spectra)
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'fourier'; % not 'powandcsd; compute csd online in ft_sourceanalysis;
cfg.foi        = foi;         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 2;           % 4 Hz smoothing 10.04.2015 to be consistent with sensor-level results
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channel    = {'all' '-UADC003'};
fourier1       = ft_freqanalysis(cfg, data1);

% % normalize
% rpttap X chan
selchan = match_str(fourier1.label, {'audio_avg'});
fourier1.fourierspctrm(:,selchan,:) = fourier1.fourierspctrm(:,selchan,:)./abs(fourier1.fourierspctrm(:,selchan,:));

%% compute augmented leadfield matrix
% load forward model (headmodel) 
headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

% load sourcemodel surfreg 8196 vertices
% this doesn't contain a leadfield field, therefore it is computed below
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');

load('/home/language/nielam/MOUS/meg/templates/atlas_conte69_8196reg_LR.mat')
% % index: 21 = L_41_B05   64 = R_41_B05   
iL41 = find(atlas.parcellation == 21);
% iR41 = find(atlas.parcellation == 64);
% 
% % index: 24 = L_42_B05   67 = R_42_B05
% iL42 = find(atlas.parcellation == 24);
% iR42 = find(atlas.parcellation == 6);

% sourcemodel.inside = false(size(sourcemodel.pos,1),1);
% sourcemodel.inside(1:10) = true; iL41=1;

cfg = [];
cfg.grid      = sourcemodel;
cfg.vol       = headmodel;
cfg.channel   = 'MEG';
cfg.grad      = ft_struct2double(fourier1.grad);
cfg.normalize = 'yes';
                  % fixed dipole            % varied dipole 
sourcemodel   = ft_prepare_leadfield(cfg);

% now we are going to expand the leadfields in the sourcemodel (in
% principle this should also work within the 'pcc' framework, but let's not
% go there now)
refleadfield = cat(2,sourcemodel.leadfield{iL41});
[u,s,v] = svd(refleadfield, 'econ');
refleadfield = u(:,1:15);

indx = find(sourcemodel.inside);
sourcemodel2 = sourcemodel;
for k = indx(:)'
  sourcemodel2.leadfield{k} = [sourcemodel.leadfield{k} refleadfield]; 
end

%% compute spatial filters using augmented leadfield and save spatial filters
%  save spatial filters, and apply to all frequencies because LF is not
%  dependent on data
cfg = [];
cfg.method            = 'pcc';
cfg.refchan           = 'audio_avg';
cfg.frequency         = foi;
cfg.vol               = headmodel;
cfg.grid              = sourcemodel2;
cfg.pcc.realfilter   = 'yes';  % consider real+complex filter; complex may try to rotate back to 'original phase'
cfg.pcc.keepcsd      = 'yes';
cfg.pcc.lambda       = '5%';
cfg.pcc.projectnoise = 'yes';
cfg.grad              = fourier1.grad;
source                = ft_sourceanalysis(cfg,fourier1);
coh = zeros(size(source.pos,1),1);
for k = indx(:)'
  tmp = source.avg.csd{k};
  crs = svd(tmp(1:3,end));  % understand why 1:3 (crs = cross-spectrum)
  pow = svd(tmp(1:3,1:3));
  coh(k) = crs./sqrt(pow(1)); % normalize with power; % what is value in pow(1)
end



%% source-level

cfg = [];
cfg.method    = 'dics';
cfg.frequency = foi;
cfg.refchan   = 'audio_avg';
cfg.vol       = headmodel;
cfg.grid      = spatialfilter;
% cfg.dics.fixedori     = 'yes';  % fixedori not supported for cortico-cortico coherence; used SVD
cfg.dics.realfilter   = 'yes';  % consider real+complex filter; complex may try to rotate back to 'original phase'
cfg.dics.keepfilter   = 'yes'; 
cfg.dics.lambda       = '5%';
cfg.dics.projectnoise = 'yes';
cfg.grad      = fourier1.grad;
sourcesen     = ft_sourceanalysis(cfg,fourier1);


% mous_db_putdata(subjectname,['meg_coh_sourcedata_nn_',savefoi,'_surface_ampnorm_sentpeak'],'sourcesen');

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
cfg.trl        = trl(1:3,:);
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
   

