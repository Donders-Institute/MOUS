% This script does a Granger causality analysis at the source level

if ~exist('subjectname', 'var')
  error('a subjectname needs to be provided');
end

if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/jansch';
end

if ~exist('dopreproc',      'var'), dopreproc      = 0; end
if ~exist('dopreproc_sub',  'var'), dopreproc_sub  = 0; end
if ~exist('dofreq',         'var'), dofreq         = 0; end
if ~exist('dofreq_sub',     'var'), dofreq_sub     = 0; end
if ~exist('dolcmv',         'var'), dolcmv         = 0; end
if ~exist('doparcellate',   'var'), doparcellate   = 0; end
if ~exist('dogranger',      'var'), dogranger      = 0; end
if ~exist('dogranger_sent', 'var'), dogranger_sent = 0; end
if ~exist('dogranger_seq',  'var'), dogranger_seq  = 0; end
if ~exist('dogranger_sub',  'var'), dogranger_sub  = 0; end
if ~exist('dogranger_sub2',  'var'), dogranger_sub2  = 0; end
if ~exist('dogranger_earlylate',  'var'), dogranger_earlylate  = 0; end
if ~exist('dogranger_earlylate2', 'var'), dogranger_earlylate2 = 0; end
if ~exist('dograngerpow_earlylate', 'var'), dograngerpow_earlylate = 0; end
if ~exist('dopow_sub2',     'var'), dopow_sub2     = 0; end

if dopreproc
  % do preprocessing with minimal filtering, and sufficient padding for
  % dftfilter
  mous_db_makesubjdir(subjectname);

  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  % get the description of the artifacts
  mous_db_getdata(subjectname, 'meg_artifact_cfg');
  try
    mous_db_getdata(subjectname, 'meg_artifact_cfg_manual');
  catch
    cfgmanual.visual.artifact = [];
    cfgmanual.artfctdef.type = [];
  end
  
  trl = mous_defineTrial(filename{1}, -0.2, 0.6, 'visual_word'); %FIXME only for V* for now
  trl = mous_artifact_remove(trl, filename{1}, {cfgeog1 cfgeog2 cfgjump cfgmuscle cfgmanual});
  

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

if dopreproc_sub
  % do preprocessing with minimal filtering, and sufficient padding for
  % dftfilter
  mous_db_makesubjdir(subjectname);

  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  for j = 1:numel(filename)
    
    if numel(filename)>1
      
      mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(j)]);
      cfgmanual.visual.artifact = [];
      cfgmanual.artfctdef.type  = [];
    else
      
      % get the description of the artifacts
      mous_db_getdata(subjectname, 'meg_artifact_cfg');
      try
        mous_db_getdata(subjectname, 'meg_artifact_cfg_manual');
      catch
        cfgmanual.visual.artifact = [];
        cfgmanual.artfctdef.type = [];
      end
      
    end
    %trl = mous_defineTrial(filename{j}, -0.2, 0.6, 'visual_word'); %FIXME only for V* for now
    trl = mous_defineTrial(filename{j}, 0.1, 0.6, 'visual_word'); %FIXME only for V* for now
    trl = mous_artifact_remove(trl, filename{j}, {cfgeog1 cfgeog2 cfgjump cfgmuscle cfgmanual});
    
    trl = trl(trl(:,2)-trl(:,1)+1==840,:); % only use the trials that are 'full'
    
    T        = trl(:,[4 8]);
    nw       = unique(T(:,1));
    for k = 1:size(nw,1)
      nw(k,2) = max(T(T(:,1)==nw(k,1),2));
    end
    
    % create 4 sets of trial indices:
    % word 2-4 sentence
    % word (n-3)-(n-1) sentence
    % word 2-4 sequence
    % word (n-3)-(n-1) sequence
    sel1 = zeros(0,1);
    sel2 = zeros(0,1);
    sel3 = zeros(0,1);
    sel4 = zeros(0,1);
    
    for k = 1:size(trl,1)
      T      = trl(k,4:end);
      sel    = find(nw(:,1)==T(1));
      wordok = [2 3 4 nw(sel,2)-(3:-1:1)];
      if ~ismember(T(5), wordok)
        continue;
      end
      
      if ismember(T(2), [1 2 5 6])
        % it's a sentence word
        if ismember(T(5), wordok(1:3))
          % it's and early word
          sel1 = [sel1;k];
        else
          sel2 = [sel2;k];
        end
      elseif ismember(T(2), [3 4 7 8])
        % it's a wordlist word
        if ismember(T(5), wordok(1:3))
          % it's and early word
          sel3 = [sel3;k];
        else
          sel4 = [sel4;k];
        end
      end
    end
    
    cfg            = [];
    cfg.dataset    = filename{j};
    cfg.trl        = trl([sel1(:);sel2(:);sel3(:);sel4(:)],:);
    cfg.continuous = 'yes';
    cfg.channel    = 'MEG';
    cfg.dftfilter  = 'yes';
    cfg.dftfreq    = [50 100 150 200 250 300]; cfg.dftfreq = [cfg.dftfreq cfg.dftfreq+0.5 cfg.dftfreq-0.5];
    cfg.padding    = 2;
    cfg.demean     = 'yes';
    %cfg.detrend    = 'yes';
    tmpdata        = ft_preprocessing(cfg);
    
    %nsmp    = cellfun('size', tmpdata.trial, 2);
    %tmpdata = ft_selectdata(tmpdata, 'rpt', find(nsmp==480));
    if j==1,
      data = tmpdata;
    else
      data = ft_appenddata([], data, tmpdata);
    end
    
  end
 
  cfg            = [];
  cfg.preproc.demean     = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
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

if dofreq_sub
  %cfg         = [];
  %cfg.detrend = 'yes';
  %data        = ft_preprocessing(cfg, data);
  data = ft_selectdata(data, 'toilim', [0.2 0.6-1/1200]);
  
  % do spectral analysis and save the results as chan_chan_freq
  % cross-spectral matrices, initially for conditions combined, and for the
  % sequence/sentence conditions. FIXME we may need different selections of
  % trials eventually
  
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end
 
  % get the original trl description to extract the number of words per
  % stimulus
%   nw       = [];
%   filename = mous_db_getfilename(subjectname, 'meg_ds_task');
%   trl      = mous_defineTrial(filename{1}, -0.2, 0.6, 'visual_word');
%   T        = trl(:,[4 8]);
%   nw(:,1)  = unique(T(:,1));
%   for k = 1:size(nw,1)
%     nw(k,2) = max(T(T(:,1)==nw(k,1),2));
%   end
%   
  % create 4 sets of trial indices:
  % word 2-4 sentence
  % word (n-3)-(n-1) sentence
  % word 2-4 sequence
  % word (n-3)-(n-1) sequence
  sel1 = zeros(0,1);
  sel2 = zeros(0,1);
  sel3 = zeros(0,1);
  sel4 = zeros(0,1);
  for k = 1:numel(data.trial)
    T      = data.trialinfo(k,:);
    %sel    = find(nw(:,1)==T(1));
    %wordok = [2 3 4 nw(sel,2)-(3:-1:1)];
    wordok = [2 3 4 7:13]; % use a more lenient definition of the words that
    % are allowed, which is based on the assumption
    % that the correct n-4,n-3,n-2 selection has taken place at the
    % preprocessing step. this is to accommodate the fact that a few
    % datasets consists of >1 *.ds directories
    if ~ismember(T(5), wordok)
      continue;
    end
    
    if ismember(T(2), [1 2 5 6])
      % it's a sentence word
      if ismember(T(5), wordok(1:3))
        % it's and early word
        sel1 = [sel1;k];
      else
        sel2 = [sel2;k];
      end
    elseif ismember(T(2), [3 4 7 8])
      % it's a wordlist word
      if ismember(T(5), wordok(1:3))
        % it's and early word
        sel3 = [sel3;k];
      else
        sel4 = [sel4;k];
      end
    end
  end
  
  N   = min([numel(sel1) numel(sel2) numel(sel3) numel(sel4)]);
  tmp = randperm(numel(sel1));sel1 = sort(sel1(tmp(1:N)));
  tmp = randperm(numel(sel2));sel2 = sort(sel2(tmp(1:N)));
  tmp = randperm(numel(sel3));sel3 = sort(sel3(tmp(1:N)));
  tmp = randperm(numel(sel4));sel4 = sort(sel4(tmp(1:N)));
  
  data = ft_selectdata(data, 'rpt', [sel1(:);sel2(:);sel3(:);sel4(:)]);
  sel1 = (1:N);
  sel2 = (1:N)+N;
  sel3 = (1:N)+2*N;
  sel4 = (1:N)+3*N;
  
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'fourier';
  cfg.tapsmofrq = 7.5;
  cfg.foilim = [0 300];
  cfg.pad    = 1;
  cfg.trials = sel1;
  csd_sent_early = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_sent_early', 'csd_sent_early', rootdir); clear csd_sent_early;
  cfg.trials = sel2;
  csd_sent_late  = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_sent_late',  'csd_sent_late',  rootdir); clear csd_sent_late;
  cfg.trials = sel3;
  csd_seq_early  = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_seq_early',  'csd_seq_early',  rootdir); clear csd_seq_early;
  cfg.trials = sel4;
  csd_seq_late   = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_seq_late',   'csd_seq_late',   rootdir); clear csd_seq_late;
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
  %addpath('/home/language/jansch/matlab/toolboxes/Ncut_9');
  
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

if dogranger_earlylate
  
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_early', rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation',   rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  tmp = parcellation.filter(sel);
  for k = 1:numel(tmp)
    F(k,:) = tmp{k}(1,:);
  end
   
  csd_all = ft_struct2double(csd_sent_early); clear csd_sent_early;
  
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  cfg.granger.checkconvergence = false;
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_sent_early', 'g', rootdir);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late', rootdir);
  csd_all   = ft_struct2double(csd_sent_late); clear csd_sent_late;
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  cfg.granger.checkconvergence = false;
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_sent_late', 'g', rootdir);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early', rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation',   rootdir);
  csd_all   = ft_struct2double(csd_seq_early); clear csd_seq_early;
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  cfg.granger.checkconvergence = false;
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_seq_early', 'g', rootdir);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late', rootdir);
  csd_all   = ft_struct2double(csd_seq_late); clear csd_seq_late;
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.granger.sfmethod = 'bivariate';
  cfg.granger.checkconvergence = false;
  g            = ft_connectivityanalysis(cfg, csd_all);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  
  warning off; g = ft_struct2single(g); warning on;
  mous_db_putdata(subjectname, 'meg_granger_granger_seq_late', 'g', rootdir);

end

if dogranger_earlylate2
  
  % do pairwise-parcel granger, using 2 components per parcel, rather than
  % 1
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % get the spatial filters: use the first 2 components
  mous_db_getdata(subjectname, 'meg_granger_parcellation',   rootdir);
  notsel = match_str(parcellation.label, {'L_???_01' 'L_MEDIAL.WALL_01' 'R_???_01' 'R_MEDIAL.WALL_01'});
  for k = 1:numel(parcellation.label)
    ncomp(k,1) = numel(parcellation.s{k});
  end
  notsel = [notsel(:);find(ncomp(:)<=10)];
  
  sel = setdiff(find(~cellfun(@isempty, parcellation.filter)), notsel);
  tmp = parcellation.filter(sel);
  F   = zeros(numel(sel)*2, size(tmp{1},2));
  for k = 1:numel(tmp)
    F((k-1)*2+(1:2),:) = tmp{k}(1:2,:);
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %%%%%%%%%%%%
  % prepare the chunkings
  cmb = tril(ones(numel(sel)),-1);
  cmb(cmb>0) = 1:sum(cmb(:));
  chunk = cmb;
  for k = 1:size(chunk,2)-1
    chunk(k+1:end,k) = chunk(k+1:end,k)-chunk(k+1,k)+1;
  end
  chunk = ceil(chunk./100);
  indx1 = {};
  indx2 = {};
  for k = 1:size(chunk,2)-1
    tmp  = chunk(:,k);
    utmp = unique(tmp);
    utmp = utmp(2:end);
    for m = 1:numel(utmp)
      indx1{end+1} = k;
      indx2{end+1} = find(tmp==utmp(m));
    end
  end
      
  % deal with which condition(s) to do the computation on
  if ~exist('condition', 'var')
    condition = {'sent_early' 'sent_late' 'seq_early' 'seq_late'};
  elseif ischar(condition)
    condition = {condition};
  end
  
  for kk = 1:numel(condition)
    
    loadsuffix = ['meg_granger_csd_',condition{kk}];
    
    tmp     = mous_db_getdata(subjectname, loadsuffix, rootdir);
    csd_all = ft_struct2double(tmp); clear tmp;
    G       = zeros(numel(sel), numel(sel), 256);
    G2      = zeros((numel(sel)-1)*numel(sel)*0.5, 256);
    G_rev   = G;
    
    g        = [];
    g.label  = parcellation.label(sel);
    g.dimord = 'chan_chan_freq';
    g.freq   = csd_all.freq(1:256);
    
    g_rev = g;
    
    g2        = [];
    g2.dimord = 'chancmb_freq';
    g2.freq   = csd_all.freq(1:256);
    
    labelcmb = cell(0,2);
    cnt = 0;
    for k = 1:numel(indx1)
      tic;
      fprintf('computing Granger for chunk %d/%d...', k, numel(indx1));
      sel1 = (indx1{k}-1)*2+(1:2);
      sel2 = [(indx2{k}(:)-1)*2+1;(indx2{k}(:)-1)*2+2];
      sel2 = sort(sel2(:));
      f1 = F(sel1,:);
      f2 = F(sel2,:);
      f  = [f1;f2];
      
      labelcmb = [labelcmb;repmat(g.label(indx1{k}),numel(indx2{k}),1) g.label(indx2{k})];
      
      tmp     = zeros(size(f,1),size(f,1),256)+1i.*zeros(size(f,1),size(f,1),256);
      for j = 1:256
        tmp(:,:,j) = f*csd_all.crsspctrm(:,:,j)*f';
      end
      cmbindx = [ones(numel(indx2{k}),1) ones(numel(indx2{k}),1)*2 (3:2:size(tmp,1))' (4:2:size(tmp,1))'];
      
      [tmpg, tmpg_toti] = do_granger4x4(tmp, csd_all.freq(1:256), cmbindx);
      tmpg_rev          = do_granger4x4(conj(tmp), csd_all.freq(1:256), cmbindx);
      
      G(indx1{k},indx2{k},:) = shiftdim(tmpg(1,2,:,:));
      G(indx2{k},indx1{k},:) = shiftdim(tmpg(2,1,:,:));
      G_rev(indx1{k},indx2{k},:) = shiftdim(tmpg_rev(1,2,:,:));
      G_rev(indx2{k},indx1{k},:) = shiftdim(tmpg_rev(2,1,:,:));
      G2(cnt+(1:size(tmpg_toti,1)),:) = tmpg_toti;
      cnt = cnt + size(tmpg_toti,1);
      
      toc;
    end
    g.grangerspctrm = G;
    g2.totispctrm   = G2;
    g_rev.grangerspctrm = G_rev;
    warning off; 
      g = ft_struct2single(g);
      g2 = ft_struct2single(g2);
      g_rev = ft_struct2single(g_rev);
    warning on;
    
    savesuffix = ['meg_granger_granger_',condition{kk}];
    mous_db_putdata(subjectname, savesuffix, 'g', 'g2', 'g_rev', rootdir, 1);
  end
  
end

if dograngerpow_earlylate
  
  % do pairwise-parcel power estimation
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_early', rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation',   rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  tmp = parcellation.filter(sel);
  for k = 1:numel(tmp)
    F(k,:) = tmp{k}(1,:);
  end
   
  csd_all   = ft_struct2double(csd_sent_early); clear csd_sent_early;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_sent_early = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late', rootdir);
  csd_all   = ft_struct2double(csd_sent_late); clear csd_sent_late;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_sent_late = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early', rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation',   rootdir);
  csd_all   = ft_struct2double(csd_seq_early); clear csd_seq_early;
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_seq_early = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late', rootdir);
  csd_all   = ft_struct2double(csd_seq_late); clear csd_seq_late;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_seq_late  = pow;
  
  mous_db_putdata(subjectname, 'meg_granger_pow_earlylate', 'pow_sent_early', 'pow_sent_late', 'pow_seq_early', 'pow_seq_late', rootdir);
  
end

if dogranger_sent
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent',     rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  F   = cat(1, parcellation.filter{sel});
   
  csd_all = csd_sent; clear csd_sent;
  
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
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

if dogranger_sub
  ref  = 'L_44';
  
  % do granger for each of the subdivisions of the trials
  
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  F   = cat(1, parcellation.filter{sel});
  
  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_early',     rootdir);
  csd_all        = csd_sent_early; clear csd_sent_early;
  csd_all        = ft_struct2double(csd_all);
  crsspctrm      = zeros(size(F,1),size(F,1),256);
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  lab1 = csd_all.label(strncmp(csd_all.label,ref,numel(ref)));
  x    = ft_channelcombination([lab1 repmat({'all'},[numel(lab1) 1])],csd_all.label);
  x    = x(~(strncmp(x(:,1),ref,4)&strncmp(x(:,2),ref,4)),:);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.channelcmb = x;
  g            = ft_connectivityanalysis(cfg, csd_all);
  
  mous_db_putdata(subjectname, ['meg_granger_granger_sent_early_',ref], 'g', rootdir,0);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late',     rootdir);
  csd_all        = csd_sent_late; clear csd_sent_late;
  csd_all        = ft_struct2double(csd_all);
  crsspctrm      = zeros(size(F,1),size(F,1),256);
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  lab1 = csd_all.label(strncmp(csd_all.label,ref,numel(ref)));
  x    = ft_channelcombination([lab1 repmat({'all'},[numel(lab1) 1])],csd_all.label);
  x    = x(~(strncmp(x(:,1),ref,4)&strncmp(x(:,2),ref,4)),:);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.channelcmb = x;
  g            = ft_connectivityanalysis(cfg, csd_all);
  
  mous_db_putdata(subjectname, ['meg_granger_granger_sent_late_',ref], 'g', rootdir,0);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early',     rootdir);
  csd_all        = csd_seq_early; clear csd_seq_early;
  csd_all        = ft_struct2double(csd_all);
  crsspctrm      = zeros(size(F,1),size(F,1),256);
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  lab1 = csd_all.label(strncmp(csd_all.label,ref,numel(ref)));
  x    = ft_channelcombination([lab1 repmat({'all'},[numel(lab1) 1])],csd_all.label);
  x    = x(~(strncmp(x(:,1),ref,4)&strncmp(x(:,2),ref,4)),:);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.channelcmb = x;
  g            = ft_connectivityanalysis(cfg, csd_all);
  
  mous_db_putdata(subjectname, ['meg_granger_granger_seq_early_',ref], 'g', rootdir,0);

  % do pairwise-parcel granger
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late',     rootdir);
  csd_all        = csd_seq_late; clear csd_seq_late;
  csd_all        = ft_struct2double(csd_all);
  crsspctrm      = zeros(size(F,1),size(F,1),256);
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  csd_all.crsspctrm = crsspctrm;
  csd_all.label     = parcellation.label(sel);
  csd_all.freq      = csd_all.freq(1:256);
  
  lab1 = csd_all.label(strncmp(csd_all.label,ref,numel(ref)));
  x    = ft_channelcombination([lab1 repmat({'all'},[numel(lab1) 1])],csd_all.label);
  x    = x(~(strncmp(x(:,1),ref,4)&strncmp(x(:,2),ref,4)),:);
  
  cfg          = [];
  cfg.method   = 'granger';
  cfg.channelcmb = x;
  g            = ft_connectivityanalysis(cfg, csd_all);
  
  mous_db_putdata(subjectname, ['meg_granger_granger_seq_late_',ref], 'g', rootdir,0);

end

if dogranger_sub2
  ref  = 'L_44';%_B05_092';
  %ref  = 'R_44';
  
  % do granger for each of the subdivisions of the trials
  
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  
  parcellation.filter = parcellation.filter(sel);
  parcellation.s      = parcellation.s(sel);
  parcellation.u      = parcellation.u(sel);
  parcellation.label  = parcellation.label(sel);
  
  selref = find(strncmp(parcellation.label, ref, numel(ref)));
  nref   = numel(selref);
  nparc  = numel(parcellation.label);
  
  % do pairwise-parcel blockwise granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_early',     rootdir);
  csd_all        = csd_sent_early; clear csd_sent_early;
  csd_all        = ft_struct2double(csd_all);
  g              = mous_granger_blockwise_parcellation(csd_all, parcellation, parcellation.label(selref));
  mous_db_putdata(subjectname, ['meg_granger_block_sent_early_',ref], 'g', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late',     rootdir);
  csd_all        = csd_sent_late; clear csd_sent_late;
  csd_all        = ft_struct2double(csd_all);
  g              = mous_granger_blockwise_parcellation(csd_all, parcellation, parcellation.label(selref));
  mous_db_putdata(subjectname, ['meg_granger_block_sent_late_',ref], 'g', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early',     rootdir);
  csd_all        = csd_seq_early; clear csd_seq_early;
  csd_all        = ft_struct2double(csd_all);
  g              = mous_granger_blockwise_parcellation(csd_all, parcellation, parcellation.label(selref));
  mous_db_putdata(subjectname, ['meg_granger_block_seq_early_',ref], 'g', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late',     rootdir);
  csd_all        = csd_seq_late; clear csd_seq_late;
  csd_all        = ft_struct2double(csd_all);
  g              = mous_granger_blockwise_parcellation(csd_all, parcellation, parcellation.label(selref));
  mous_db_putdata(subjectname, ['meg_granger_block_seq_late_',ref], 'g', rootdir,0);
  
end

if dopow_sub2
  % compute power for each of the subdivisions of the trials for each of
  % the parcellations, keeping the 95% variance per parcel
  
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  sel = find(~cellfun(@isempty, parcellation.filter));
  
  parcellation.filter = parcellation.filter(sel);
  parcellation.s      = parcellation.s(sel);
  parcellation.u      = parcellation.u(sel);
  parcellation.label  = parcellation.label(sel);
  
  % do pairwise-parcel blockwise granger
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_early',     rootdir);
  csd_all        = csd_sent_early; clear csd_sent_early;
  csd_all        = ft_struct2double(csd_all);
  pow            = mous_lcmv_parcellation_pow(csd_all, parcellation);
  mous_db_putdata(subjectname, 'meg_granger_pow_sent_early', 'pow', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late',     rootdir);
  csd_all        = csd_sent_late; clear csd_sent_late;
  csd_all        = ft_struct2double(csd_all);
  pow            = mous_lcmv_parcellation_pow(csd_all, parcellation);
  mous_db_putdata(subjectname, 'meg_granger_pow_sent_late', 'pow', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early',     rootdir);
  csd_all        = csd_seq_early; clear csd_seq_early;
  csd_all        = ft_struct2double(csd_all);
  pow            = mous_lcmv_parcellation_pow(csd_all, parcellation);
  mous_db_putdata(subjectname, 'meg_granger_pow_seq_early', 'pow', rootdir,0);

  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late',     rootdir);
  csd_all        = csd_seq_late; clear csd_seq_late;
  csd_all        = ft_struct2double(csd_all);
  pow            = mous_lcmv_parcellation_pow(csd_all, parcellation);
  mous_db_putdata(subjectname, 'meg_granger_pow_seq_late', 'pow', rootdir,0);
  
end
