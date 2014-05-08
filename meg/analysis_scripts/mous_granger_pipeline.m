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
if ~exist('doparcellate', 'var'), doparcellate = 0; end
if ~exist('dogranger', 'var'), dogranger = 0; end
if ~exist('dogranger_sent', 'var'), dogranger_sent = 0; end
if ~exist('dogranger_seq', 'var'),  dogranger_seq  = 0; end

if dopreproc
  % do preprocessing with minimal filtering, and sufficient padding for
  % dftfilter
  mous_db_makesubjdir(subjectname)

  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  % get the description of the artifacts
  mous_db_getdata(subjectname, 'meg_artifact_cfg');
  %trl = mous_defineTrial(filename{1}, -0.2, 0.6, 'all', 'visual_word'); %FIXME only for V* for now
  trl = mous_defineTrial(filename{1}, -0.2, 0.6, 'visual_word'); %FIXME only for V* for now
  trl = mous_artifact_remove(trl, filename{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle});

  cfg            = [];
  cfg.dataset    = filename{1};
  cfg.trl        = trl;
  cfg.continuous = 'yes';
  cfg.channel    = 'MEG';
  cfg.dftfilter  = 'yes';
  cfg.dftfreq    = [50 100 150 200 250 300];
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
  mous_db_putdata(subjectname, 'meg_granger_tlck', 'tlck', rootdir);
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
  cfg.foilim = [0 300];
  cfg.pad    = 1;
  
  % call freqanalysis in a loop, because otherwise memory will be blown up
  % and split according to condition
  sel1   = find(ismember(data.trialinfo(:,2), [1 2 5 6]));
  chunk1 = [0:400:numel(sel1) numel(sel1)];
  for k = 1:numel(chunk1)-1
    cfg.trials = sel1((chunk1(k)+1):chunk1(k+1));
    tmpfreq    = ft_freqanalysis(cfg, data);
    tmpfreq    = ft_checkdata(tmpfreq, 'cmbrepresentation', 'fullfast');
    if k==1,
      csd_sent = tmpfreq;
    else
      csd_sent.crsspctrm = (csd_sent.crsspctrm.*sel1(chunk1(k)) + tmpfreq.crsspctrm.*numel(cfg.trials))./(sel1(chunk1(k))+numel(cfg.trials));
    end
    clear tmpfreq;
  end
  csd_sent.dof = 2*numel(sel1)*3; %FIXME assume 3 tapers
  
  sel2   = find(ismember(data.trialinfo(:,2), [3 4 7 8]));
  chunk2 = [0:400:numel(sel2) numel(sel2)];
  for k = 1:numel(chunk2)-1
    cfg.trials = sel2((chunk2(k)+1):chunk2(k+1));
    tmpfreq    = ft_freqanalysis(cfg, data);
    tmpfreq    = ft_checkdata(tmpfreq, 'cmbrepresentation', 'fullfast');
    if k==1,
      csd_seq = tmpfreq;
    else
      csd_seq.crsspctrm = (csd_seq.crsspctrm.*sel2(chunk2(k)) + tmpfreq.crsspctrm.*numel(cfg.trials))./(sel1(chunk2(k))+numel(cfg.trials));
    end
    clear tmpfreq;
  end
  csd_seq.dof = 2*numel(sel2)*3; %FIXME assume 3 tapers
  
  % mous_db_putdata(subjectname, 'meg_granger_csd_all',  'csd_all',  rootdir);
  mous_db_putdata(subjectname, 'meg_granger_csd_sent', 'csd_sent', rootdir);
  mous_db_putdata(subjectname, 'meg_granger_csd_seq',  'csd_seq',  rootdir);
end

if dolcmv
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end

  % compute spatial filters
  [source, tlck, trialinfo] = mous_lcmv_source(subjectname, data, '/project/3011020.09/MEG');
  
  mous_db_putdata(subjectname, 'meg_granger_source', 'tlck', 'trialinfo', 'source', rootdir);
end

if doparcellate
  % compute parcellation based on graph cut algorithm, chunking together
  % vertices with high zero-lag correlation, i.e. volume-conducted
  addpath('/home/language/jansch/matlab/toolboxes/Ncut_9');
  
  mous_db_getdata(subjectname, 'meg_granger_source', rootdir);
  if ~isfield(source, 'tri')
    load cortex_midthickness_8196reg;
    source.tri = sourcemodel.tri;
  end
  load atlas_conte69_8196reg_LR_brodmann_subparc
  [source, parcellation] = mous_lcmv_parcellate(source, tlck, 'method', 'parcellation', 'parcellation', atlas);
  mous_db_putdata(subjectname, 'meg_granger_parcellation', 'parcellation', 'source', rootdir);
end
 
if dogranger
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq',      rootdir);
  mous_db_getdata(subjectname, 'meg_granger_csd_sent',     rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  F   = cat(1, parcellation.filter{sel});
  
  csd_all = csd_sent; clear csd_sent;
  csd_all.crsspctrm = (csd_all.crsspctrm.*csd_all.dof+csd_seq.crsspctrm.*csd_seq.dof)./(csd_all.dof+csd_seq.dof);
  clear csd_seq;
  
  %crsspctrm = zeros(size(F,1),size(F,1),numel(csd_all.freq));
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  %for k = 1:numel(csd_all.freq)
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  mous_db_putdata(subjectname, 'meg_granger_granger', 'g', rootdir);
end

if dogranger_sent
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent',     rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  F   = cat(1, parcellation.filter{sel});
  %F   = F./repmat(sum(F.^2,2),[1 size(F,2)]);
   
  csd_all = csd_sent; clear csd_sent;
  
  %crsspctrm = zeros(size(F,1),size(F,1),numel(csd_all.freq));
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  %for k = 1:numel(csd_all.freq)
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_sent', 'g', rootdir);
end

if dogranger_seq
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq',     rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  F   = cat(1, parcellation.filter{sel});
  %F   = F./repmat(sum(F.^2,2),[1 size(F,2)]);
  
  csd_all = csd_seq; clear csd_seq;
  
  %crsspctrm = zeros(size(F,1),size(F,1),numel(csd_all.freq));
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  %for k = 1:numel(csd_all.freq)
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_seq', 'g', rootdir);
end
