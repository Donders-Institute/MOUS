% This script does a Granger causality analysis at the source level

if ~exist('subjectname', 'var')
  error('a subjectname needs to be provided');
end

if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/jansch';
end

if ~exist('dopreproc', 'var'), dopreproc = 0; end
if ~exist('dofreq',    'var'), dofreq    = 0; end
if ~exist('dolcmv',    'var'), dolcmv    = 0; end
if ~exist('doparcellated', 'var'), doparcellate = 0; end
if ~exist('dogranger', 'var'), dogranger = 0; end

if dopreproc
  % do preprocessing with minimal filtering, and sufficient padding for
  % dftfilter
  mous_db_makesubjdir(subjectname)

  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  % get the description of the artifacts
  tmp = mous_db_getdata(subjectname, 'meg_artifact_cfg');
  trl = mous_defineTrial(filename{1}, -0.2, 0.6, 'all', 'visual_word'); %FIXME only for V* for now
  trl = mous_artifact_remove(trl, filename{1}, tmp);

  cfg            = [];
  cfg.dataset    = filename{1};
  cfg.trl        = trl;
  cfg.continuous = 'yes';
  cfg.channel    = 'MEG';
  cfg.dftfilter  = 'yes';
  cfg.padding    = 2;
  cfg.demean     = 'yes';
  data           = ft_preprocessing(cfg);
  
  nsmp = cellfun('size', data.trial, 2);
  data = ft_selectdata(data, 'rpt', find(nsmp==480));
  
  cfg            = [];
  cfg.covariance = 'yes';
  tlck           = ft_timelockanalysis(cfg, data);
  
  % do visual artifact rejection to be sure that the trials are more or
  % less well behaved
end

if dofreq
  % do spectral analysis and save the results as chan_chan_freq
  % cross-spectral matrices, initially for conditions combined, and for the
  % sequence/sentence conditions. FIXME we may need different selections of
  % trials eventually
  
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end

  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'fourier';
  cfg.tapsmofrq = 5;
  cfg.foilim = [0 200];
  freq       = ft_freqanalysis(cfg, data);
  
  csd_all    = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
  csd_sent   = ft_selectdata(freq, 'rpt', find(ismember(freq.trialinfo(:,2), [1 2 5 6])));
  csd_sent   = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
  csd_seq    = ft_selectdata(freq, 'rpt', find(ismember(freq.trialinfo(:,2), [3 4 7 8])));
  csd_seq    = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
  
end

if dolcmv
  % compute spatial filters
  
  [source, tlck, trialinfo] = mous_lcmv_source(subjectname, data, rootdir);
  
end

if doparcellated
  % compute parcellation based on graph cut algorithm, chunking together
  % vertices with high zero-lag correlation, i.e. volume-conducted
  
  [source, parcellation] = mous_lcmv_parcellate(subjectname, tlck);
end
 
if dogranger
  % do pairwise-parcel granger
  
end
