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
if ~exist('dofreq_parcellate_stratify', 'var'), dofreq_parcellate_stratify = 0; end
if ~exist('dolcmv',         'var'), dolcmv         = 0; end
if ~exist('doparcellate',   'var'), doparcellate   = 0; end
if ~exist('doparcellate_stratify', 'var'), doparcellate_stratify = 0; end
if ~exist('dogranger',      'var'), dogranger      = 0; end
if ~exist('dogranger_sent', 'var'), dogranger_sent = 0; end
if ~exist('dogranger_seq',  'var'), dogranger_seq  = 0; end
if ~exist('dogranger_sub',  'var'), dogranger_sub  = 0; end
if ~exist('dogranger_sub2',  'var'), dogranger_sub2  = 0; end
if ~exist('dogranger_earlylate',    'var'), dogranger_earlylate    = 0; end
if ~exist('dogranger_earlylate2',   'var'), dogranger_earlylate2   = 0; end
if ~exist('dograngerpow_earlylate', 'var'), dograngerpow_earlylate = 0; end
if ~exist('dopow_sub2',             'var'), dopow_sub2             = 0; end
if ~exist('dodssaseo',              'var'), dodssaseo              = 0; end
if ~exist('dodssaseo_clean',        'var'), dodssaseo_clean        = 0; end
if ~exist('dogranger_new',          'var'), dogranger_new          = 0; end

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
    
    [indx_early, indx_late] = extract_earlylate(trl(:,4:end));
    indx = sort([indx_early(:);indx_late(:)]);
    
    cfg            = [];
    cfg.dataset    = filename{j};
    cfg.trl        = trl(indx,:);
    cfg.continuous = 'yes';
    cfg.channel    = 'MEG';
    cfg.dftfilter  = 'yes';
    cfg.dftfreq    = [50 100 150 200 250 300]; cfg.dftfreq = [cfg.dftfreq cfg.dftfreq+0.5 cfg.dftfreq-0.5];
    cfg.padding    = 2;
    cfg.demean     = 'yes';
    %cfg.detrend    = 'yes';
    cfg.hpfilter   = 'yes';
    cfg.hpfilttype = 'firws';
    cfg.hpfreq     = 0.5;
    cfg.usefftfilt = 'yes';
    tmpdata        = ft_preprocessing(cfg);
    
    %nsmp    = cellfun('size', tmpdata.trial, 2);
    %tmpdata = ft_selectdata(tmpdata, 'rpt', find(nsmp==480));
    if j==1,
      data = tmpdata;
    else
      data = ft_appenddata([], data, tmpdata);
    end
    
    % this subsection is meant to filter out spikes in the powerspectrum
    % that pollute the granger spectra. It seems that they are present both
    % at the MEG and at the reference sensors, so use ft_denoise_pca for
    % this
    if strcmp(subjectname, 'V1046')
      % upon inspection V1063 seems to have genuine strong 30 Hz activity,
      % which is not visible on the references.
      % something similar goes for subject V1080.
      
      
      cfg.dftfilter = 'no';
      cfg.hpfilter  = 'no';
      cfg.bpfilter  = 'yes';
      cfg.bpfilttype = 'firws';
      cfg.channel   = 'MEGREF';
      
      % implement a comb-filter in a for-loop (inefficient, but does not seem to work otherwise)
      switch subjectname
        case 'V1046'      
          bpfreqs = [20 26; 76 84; 60 66; 89 95; 102 112; 115 125];
        
        otherwise
      end
      for kk = 1:size(bpfreqs,1)
        cfg.bpfreq = bpfreqs(kk,:);
        tmptmp     = ft_preprocessing(cfg);
        if kk==1,
          tmpref = tmptmp;
        else
          tmpref.trial = tmpref.trial+tmptmp.trial;
        end
      end
      
      if j==1,
        refdata = tmpref;
      else
        refdata = ft_appenddata([], refdata, tmpref);
      end
    end
    
  end
 
  if exist('refdata', 'var')
    % do a pca denoising
    cfg =[];
    cfg.truncate = 0.0001;
    data = ft_denoise_pca(cfg, data, refdata);
  end
  
%   cfg            = [];
%   cfg.preproc.demean     = 'yes';
%   cfg.preproc.baselinewindow = [-0.1 0];
%   cfg.covariance = 'yes';
%   tlck           = ft_timelockanalysis(cfg, data);
%   
%   % do visual artifact rejection to be sure that the trials are more or
%   % less well behaved
%   mous_db_putdata(subjectname, 'meg_granger_tlck', 'tlck', rootdir);
end


if dofreq_sub
  data = ft_selectdata(data, 'toilim', [0.2 0.6-1/1200]);
  
  % do spectral analysis and save the results as chan_chan_freq
  % cross-spectral matrices, initially for conditions combined, and for the
  % sequence/sentence conditions. FIXME we may need different selections of
  % trials eventually
  
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end
  
  L = log10(extract_lexfreq(data.trialinfo));
  [indx_early, indx_late] = extract_earlylate(data.trialinfo);
  T = data.trialinfo(:,2);
  
  cfg = [];
  indx1 = intersect(find(ismember(T,[1 2 5 6])), indx_early);
  cfg.trials = indx1;
  data_sent_early = ft_selectdata(cfg, data);
  indx2 = intersect(find(ismember(T,[1 2 5 6])), indx_late);
  cfg.trials = indx2;
  data_sent_late = ft_selectdata(cfg, data);
  indx3 = intersect(find(ismember(T,[3  4 7 8])), indx_early);
  cfg.trials = indx3;
  data_seq_early = ft_selectdata(cfg, data);
  indx4 = intersect(find(ismember(T,[3 4 7 8])), indx_late);
  cfg.trials = indx4;
  data_seq_late = ft_selectdata(cfg, data);
  
  cfg = [];
  cfg.binedges    = -2:0.2:4.8;
  [data_sent_early, data_sent_late, data_seq_early, data_seq_late] = mous_stratify(cfg, ...
    {data_sent_early L(indx1)}, {data_sent_late L(indx2)}, {data_seq_early L(indx3)}, {data_seq_late L(indx4)});
  
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'fourier';
  cfg.tapsmofrq = 7.5;
  cfg.foilim = [0 300];
  cfg.pad    = 1;
  csd_sent_early = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data_sent_early), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_sent_early', 'csd_sent_early', rootdir); clear csd_sent_early;
  csd_sent_late  = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data_sent_late), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_sent_late',  'csd_sent_late',  rootdir); clear csd_sent_late;
  csd_seq_early  = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data_seq_early), 'cmbrepresentation', 'fullfast'));
  mous_db_putdata(subjectname, 'meg_granger_csd_seq_early',  'csd_seq_early',  rootdir); clear csd_seq_early;
  csd_seq_late   = ft_struct2single(ft_checkdata(ft_freqanalysis(cfg, data_seq_late), 'cmbrepresentation', 'fullfast'));
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
  mous_db_putdata(subjectname, 'meg_granger_parcellation', 'parcellation', 'source', rootdir,0);
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
    
    if ~strcmp(condition{kk}, 'all')
      compute_reverse = false;
      loadsuffix = ['meg_granger_csd_',condition{kk}];
    
      tmp     = mous_db_getdata(subjectname, loadsuffix, rootdir);
      csd_all = ft_struct2double(tmp); clear tmp;
    else
      compute_reverse = true;
      
      tmp = mous_db_getdata(subjectname, 'meg_granger_csd_sent_early', rootdir);
      csd_all = ft_struct2double(tmp); clear tmp;
      tmp = mous_db_getdata(subjectname, 'meg_granger_csd_sent_late', rootdir);
      csd_all.crsspctrm = csd_all.crsspctrm + tmp.crsspctrm;
      tmp = mous_db_getdata(subjectname, 'meg_granger_csd_seq_early', rootdir);
      csd_all.crsspctrm = csd_all.crsspctrm + tmp.crsspctrm;
      tmp = mous_db_getdata(subjectname, 'meg_granger_csd_seq_late', rootdir);
      csd_all.crsspctrm = csd_all.crsspctrm + tmp.crsspctrm;
      csd_all.crsspctrm = csd_all.crsspctrm./4;
      
    end  
        
    G       = zeros(numel(sel), numel(sel), 256);
    if compute_reverse
      G2      = zeros((numel(sel)-1)*numel(sel)*0.5, 256);
      G_rev   = G;
    end
    
    g        = [];
    g.label  = parcellation.label(sel);
    g.dimord = 'chan_chan_freq';
    g.freq   = csd_all.freq(1:256);
    
    if compute_reverse
      g_rev = g;
    
      g2        = [];
      g2.dimord = 'chancmb_freq';
      g2.freq   = csd_all.freq(1:256);
    end
    
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
      
      % variance normalization step, as mentioned in Martin's paper, to be
      % necessary to evaluate the instantaneous influence strength; it does
      % not affect the GC estimates.
      doscale = 1;
      if doscale
        for j = 1:256
          tmppow(:,j) = abs(diag(tmp(:,:,j)));
        end
        scale = diag(1./sqrt(sum(tmppow,2)./256));
        for j = 1:256
          tmp(:,:,j) = scale*tmp(:,:,j)*scale';
        end
      end
      
      cmbindx = [ones(numel(indx2{k}),1) ones(numel(indx2{k}),1)*2 (3:2:size(tmp,1))' (4:2:size(tmp,1))'];
      
      [tmpg, tmpg_toti] = do_granger4x4(tmp, csd_all.freq(1:256), cmbindx);
      if compute_reverse,
        tmpg_rev          = do_granger4x4(conj(tmp), csd_all.freq(1:256), cmbindx);
      end
      
      G(indx1{k},indx2{k},:) = shiftdim(tmpg(1,2,:,:));
      G(indx2{k},indx1{k},:) = shiftdim(tmpg(2,1,:,:));
      if compute_reverse,
        G_rev(indx1{k},indx2{k},:) = shiftdim(tmpg_rev(1,2,:,:));
        G_rev(indx2{k},indx1{k},:) = shiftdim(tmpg_rev(2,1,:,:));
        G2(cnt+(1:size(tmpg_toti,1)),:) = tmpg_toti;
      end
      cnt = cnt + size(tmpg_toti,1);
      
      toc;
    end
    g.grangerspctrm = G;
    warning off;
    g = ft_struct2single(g);
    warning on;
    if compute_reverse,
      g2.totispctrm   = G2;
      g_rev.grangerspctrm = G_rev;
      warning off; 
      g2 = ft_struct2single(g2);
      g_rev = ft_struct2single(g_rev);
      warning on;
    else
      g2    = [];
      g_rev = [];
    end
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
    F((k-1)*2+(1:2),:) = tmp{k}(1:2,:);
  end
  
  % create a matrix to quickly sum 2 consecutive rows (the first 2
  % components were used for each parcel
  P = zeros(size(F,1)./2, size(F,1));
  for k = 1:size(P,1)
    P(k,(k-1)*2+(1:2)) = 1;
  end
  
  
  csd_all   = ft_struct2double(csd_sent_early); clear csd_sent_early;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = P*powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_sent_early = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_sent_late', rootdir);
  csd_all   = ft_struct2double(csd_sent_late); clear csd_sent_late;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = P*powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_sent_late = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_early', rootdir);
  csd_all   = ft_struct2double(csd_seq_early); clear csd_seq_early;
  crsspctrm = zeros(size(F,1),size(F,1),256); % anecdotally this speeds up the fft
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = P*powspctrm;
  pow.label     = parcellation.label(sel);
  pow.freq      = csd_all.freq(1:256);
  pow_seq_early = pow;
  
  mous_db_getdata(subjectname, 'meg_granger_csd_seq_late', rootdir);
  csd_all   = ft_struct2double(csd_seq_late); clear csd_seq_late;
  powspctrm = zeros(size(F,1),256); % anecdotally this speeds up the fft
  for k = 1:size(powspctrm,2)
    powspctrm(:,k) = abs(diag(F*csd_all.crsspctrm(:,:,k)*F'));
  end
  pow.powspctrm = P*powspctrm;
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






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% re-construction of the whole pipeline as it will be used for the
% publication. refer to the stuff below, with the exception of the
% dopreproc_sub code, this is done above.

% run the pipeline -> always start off with dopreproc_sub = 1, this chunk
% code is above

if ~exist('dodssaseo','var'), dodssaseo = 0; end % this is the feature to clean the data from evoked activity, using the aseo algorithm in combination with dss.

rootdir = '/project/3011020.09/jansch';
if dodssaseo,
  if ~exist('data', 'var'), error('data does not exist, run dopreproc_sub frst and keep the session open'); end
  [dataout, avgorig, avgnew, avgcomp, comp, r1, r2] = mous_dss_aseo_clean(data,'Ncomp',5);
  mous_db_putdata(subjectname, 'meg_granger_dssaseo', 'avgorig', 'avgnew', 'avgcomp', 'comp', 'r1', 'r2', rootdir);
end
if dodssaseo_clean,
  if ~exist('data', 'var'), error('data does not exist, run dopreproc_sub first and keep the session open'); end
  mous_db_getdata(subjectname, 'meg_granger_dssaseo', rootdir);
  for k = 1:numel(comp)
    % this could in principle be done without a for-loop
    fprintf('removing dss-aseo component %d\n',k);
    data.trial = data.trial - comp(k).topo*r1(k).trial;
  end
end
if dofreq
  % do spectral analysis and save the results as chan_chan_freq
  % cross-spectral matrices, initially for conditions combined, and for the
  % sequence/sentence conditions. FIXME we may need different selections of
  % trials eventually
  
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end
  
  cfg = [];
  cfg.latency = [0.2 0.6];
  data = ft_selectdata(cfg, data);
  
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'fourier';
  cfg.tapsmofrq = 5;%2.0001./0.7;
  cfg.foilim = [0 150];
  cfg.pad    = 2;
  
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
      csd_seq.crsspctrm = (csd_seq.crsspctrm.*sel2(chunk2(k)) + tmpfreq.crsspctrm.*numel(cfg.trials))./(sel2(chunk2(k))+numel(cfg.trials));
    end
    clear tmpfreq;
  end
  csd_seq.dof = 2*numel(sel2)*3; %FIXME assume 3 tapers
  
  % mous_db_putdata(subjectname, 'meg_granger_csd_all',  'csd_all',  rootdir);
  mous_db_putdata(subjectname, 'meg_granger_csd_sent', 'csd_sent', rootdir, 1);
  mous_db_putdata(subjectname, 'meg_granger_csd_seq',  'csd_seq',  rootdir, 1);
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
  mous_db_putdata(subjectname, 'meg_granger_parcellation', 'parcellation', 'source', rootdir,0);
end
if dogranger_new
  % do pairwise-parcel granger for the edges of interest
  mous_db_getdata(subjectname, 'meg_granger_csd_sent',     rootdir);
  mous_db_getdata(subjectname, 'meg_granger_csd_seq',      rootdir);
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  
  [C, label, P, list, lay] = mous_edgesofinterest;
  [sel1 ,sel2]             = match_str(parcellation.label, label(:,1));
  C                        = C(sel2,sel2);
  label                    = label(sel2,:);
  
  parcellation.label  = parcellation.label(sel1);
  parcellation.filter = parcellation.filter(sel1);
 
  csd_all = csd_sent; clear csd_sent;
  csd_all.crsspctrm = (csd_all.crsspctrm.*csd_all.dof + csd_seq.crsspctrm.*csd_seq.dof)./(csd_all.dof+csd_seq.dof);
  clear csd_seq;
  
  % only select the parcels that are nodes-of-interest, to compute the
  % concatenated spatial filter
  sel = sum(C>0,2)>0;
  
  C     = C(sel,sel);
  label = label(sel,:);
  parcellation.label  = parcellation.label(sel);
  parcellation.filter = parcellation.filter(sel);
  for k = 1:numel(parcellation.label)
    F((k-1)*2+(1:2),:) = parcellation.filter{k}(1:2,:);
  end
  
  crsspctrm = zeros(size(F,1),size(F,1),numel(csd_all.freq));
  for k = 1:size(crsspctrm,3)
    crsspctrm(:,:,k) = F*csd_all.crsspctrm(:,:,k)*F';
  end
  
  Cindx   = tril(C>0);
  [i1,i2] = find(Cindx);
  cmbindx = [i1(:) i2(:)];
  labelcmb = [parcellation.label(i1) parcellation.label(i2)];
  ncmb     = size(labelcmb,1);
  
  cmbindx4x4 = [i1*2-1 i1*2 i2*2-1 i2*2];
  chunk      = [1:100:ncmb ncmb+1];
  
  G     = zeros(ncmb*2,numel(csd_all.freq));
  G_rev = zeros(ncmb*2,numel(csd_all.freq));
  for k = 1:numel(chunk)-1
    fprintf('computing chunk %d/%d\n',k,numel(chunk)-1);
    subindx = chunk(k):(chunk(k+1)-1);
    tmp1 = dogranger4x4(crsspctrm, csd_all.freq, cmbindx4x4(subindx,:)); 
    tmp2 = dogranger4x4(conj(crsspctrm), csd_all.freq, cmbindx4x4(subindx,:));
    
    G(subindx,:)          = squeeze(tmp1(1,2,:,:));
    G(subindx+ncmb,:)     = squeeze(tmp1(2,1,:,:));
    G_rev(subindx,:)      = squeeze(tmp2(1,2,:,:));
    G_rev(subindx+ncmb,:) = squeeze(tmp2(2,1,:,:));
  end
  labelcmb = [labelcmb;labelcmb(:,2) labelcmb(:,1)];
  
  g = [];
  g.grangerspctrm = G;
  g.labelcmb      = labelcmb;
  g.freq          = csd_all.freq;
  g.dimord        = 'chancmb_freq';
  
  g_rev = g;
  g_rev.grangerspctrm = G_rev;
  
  mous_db_putdata(subjectname, 'meg_granger_granger_roi', 'g', 'g_rev', rootdir);
end
 
if doparcellate_stratify
  % This step follows a dopreproc_sub (in memory) and a dolcmv/doparcellate
  % combo. The idea is to do a stratification of the trials (across the 4
  % conditions), based on the time-domain total variance per parcel-pair
  % used for the connectivity analysis, as well as for the lexical
  % frequency. It returns a boolean matrix with the selected trials for
  % each condition as a function of parcel pair.
  % This step has been implemented 20150702
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end

  % select only from 200 ms post word onset
  %data = ft_selectdata(data, 'toilim', [0.2 0.6]);
  
  % get the spatial filters
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  
  % get a specification of the parcel combination
  load(fullfile('/project/3011020.09/MEG/misc','grangermask'), 'labelcmb');
  
  % compute a per trial variance measure of the parcels.
  label = unique(labelcmb(:));
  V = zeros(numel(data.trial), numel(label));
  F = cell(numel(label),1);
  for k = 1:numel(label)
    fprintf('%d/%d\n',k,numel(label));
    ix = match_str(parcellation.label, label{k});
    F{k} = parcellation.filter{ix}(1:2,:);  
  end
  F = cat(1,F{:});
  for m = 1:numel(data.trial)
    fprintf('%d/%d\n',m,numel(data.trial));
    trial = F*data.trial{m};
    trial = trial - repmat(mean(trial,2),[1 size(trial,2)]);
    V(m,:) = (sum(trial(1:2:end,:).^2,2)'+sum(trial(2:2:end,:).^2,2)')./(size(trial,2)-1);
  end
  
  % get some additional quantities
  L = log10(extract_lexfreq(data.trialinfo));
  T = data.trialinfo(:,2);
  [indx_early, indx_late] = extract_earlylate(data.trialinfo);
  
  % extract the indices of the trials belonging to the individual
  % conditions
  indx1 = intersect(find(ismember(T,[1 2 5 6])), indx_early);
  indx2 = intersect(find(ismember(T,[1 2 5 6])), indx_late);
  indx3 = intersect(find(ismember(T,[3 4 7 8])), indx_early);
  indx4 = intersect(find(ismember(T,[3 4 7 8])), indx_late);
  
  cfg             = [];
  cfg.equalbinavg = 'no';
  cfg.binedges{1} = -2:0.5:5; % this is the range for the lexfreq
  
  sel1 = false(size(labelcmb,1), numel(indx1));
  sel2 = false(size(labelcmb,1), numel(indx2));
  sel3 = false(size(labelcmb,1), numel(indx3));
  sel4 = false(size(labelcmb,1), numel(indx4));
  for k = 1:size(labelcmb,1)
    ix = match_str(label,labelcmb(k,:)'); 
    v  = log10(V(:,ix));
    minv = min(v,[],1);
    maxv = max(v,[],1);
    cfg.binedges{2} = floor(minv(1)*5)/5:0.2:ceil(maxv(1)*5)/5;
    cfg.binedges{3} = floor(minv(2)*5)/5:0.2:ceil(maxv(2)*5)/5;
    out = ft_stratify(cfg, [L(indx1) v(indx1,:)]', [L(indx2) v(indx2,:)]', [L(indx3) v(indx3,:)]', [L(indx4) v(indx4,:)]');
    sel1(k,:) = isfinite(out{1}(1,:));
    sel2(k,:) = isfinite(out{2}(1,:));
    sel3(k,:) = isfinite(out{3}(1,:));
    sel4(k,:) = isfinite(out{4}(1,:));
  end
  
  % compute the source level stratified ERF per parcel-pair (for later
  % to be used later for correction)
  
  % first make a list of indices for efficient reordering
  for m = 1:size(labelcmb,1)
    ix = match_str(label, labelcmb(m,:)');
    ix = [(ix(:)-1)*2+1 (ix(:)-1)*2+2]';
    ix = ix(:);
    Ix(:,m) = ix;
  end
  
  for k = 1:numel(data.trial)
    fprintf('%d/%d\n',k,numel(data.trial));
    if any(k==indx1),
      cndtn = 1;
      sel   = reshape(transpose(repmat(sel1(:,indx1==k),[1 4])),[],1);
    elseif any(k==indx2),
      cndtn = 2;
      sel   = reshape(transpose(repmat(sel2(:,indx2==k),[1 4])),[],1);
    elseif any(k==indx3),
      cndtn = 3;
      sel   = reshape(transpose(repmat(sel3(:,indx3==k),[1 4])),[],1);
    elseif any(k==indx4),
      cndtn = 4;
      sel   = reshape(transpose(repmat(sel4(:,indx4==k),[1 4])),[],1);
     end
  
    if k==1
      % initialize the averages
      avg       = cell(1,4);
      avg_strat = avg;
      for m = 1:numel(avg)
        avg{m}(4*size(labelcmb,1),numel(data.time{1}))       = 0;
        avg_strat{m}(4*size(labelcmb,1),numel(data.time{1})) = 0;
      end
    end
    
    tmpdat = F*data.trial{k};
    tmp    = tmpdat(Ix,:);
    
    avg{1,cndtn}       = avg{1,cndtn} + tmp;
    avg_strat{1,cndtn}(sel,:) = avg_strat{1,cndtn}(sel,:) + tmp(sel,:);
  end
 
  % normalise for the number of trials that contributed
  avg{1} = avg{1}./numel(indx1);
  avg{2} = avg{2}./numel(indx2);
  avg{3} = avg{3}./numel(indx3);
  avg{4} = avg{4}./numel(indx4);
  for m = 1:size(labelcmb,1)
    avg_strat{1}((m-1)*4+(1:4),:) = avg_strat{1}((m-1)*4+(1:4),:)./sum(sel1(m,:));
    avg_strat{2}((m-1)*4+(1:4),:) = avg_strat{2}((m-1)*4+(1:4),:)./sum(sel2(m,:));
    avg_strat{3}((m-1)*4+(1:4),:) = avg_strat{3}((m-1)*4+(1:4),:)./sum(sel3(m,:));
    avg_strat{4}((m-1)*4+(1:4),:) = avg_strat{4}((m-1)*4+(1:4),:)./sum(sel4(m,:));
  end
  
  mous_db_putdata(subjectname, 'meg_granger_parcellation_stratify', 'avg', 'avg_strat', 'sel1', 'sel2', 'sel3', 'sel4', 'indx1', 'indx2', 'indx3', 'indx4', 'V', 'L', 'label', 'labelcmb', rootdir, 0);
end

if dofreq_parcellate_stratify
  % This step computes the frequency transform at the source level for the
  % stratified trials, i.e. different trials per parcel pair. It represents
  % the frequency data as cell array of frequency structures, one per
  % parcel-pair.
  if ~exist('data', 'var'),
    error('data needs to be computed, because it is not saved in the current version of the pipeline, set dopreproc = 1');
  end
  mous_db_getdata(subjectname, 'meg_granger_parcellation_stratify', rootdir);
  
  if numel(data.trial)~=max([indx1;indx2;indx3;indx4]),
    error('mismatch in the expected number of trials');
  end
  
  % get the spatial filters in a single matrix
  mous_db_getdata(subjectname, 'meg_granger_parcellation', rootdir);
  
  F = cell(numel(label),1);
  for k = 1:numel(label)
    fprintf('%d/%d\n',k,numel(label));
    ix = match_str(parcellation.label, label{k});
    F{k} = parcellation.filter{ix}(1:2,:);  
  end
  F = cat(1,F{:});
   
  % pre-specify the cfg for ft_freqanalysis
  cfg        = [];
  cfg.method = 'mtmfft';
  cfg.output = 'fourier';
  cfg.tapsmofrq = 7.5;
  %cfg.foilim = [0 300];
  cfg.pad    = 1;
  
  if ~exist('offsets', 'var')
    offsets = [-0.1 0 0.1 0.2]
  end
  for offset = offsets(:)'
    
    % pre-create some dummy structures
    tmp        = [];
    tmp.freq   = 0:600;
    tmp.dimord = 'chan_chan_freq';
    tmp.crsspctrm = zeros(3005,16)+1i*zeros(3005,16); %ntapers x freqbins %zeros(4,4,301) + 1i.*zeros(4,4,301);
    
    % create the fourier-transform of the ERFs, for the specified latency
    % the avg, and avg_strat matrices are ordered according to labelcmb (each
    % quadruplet)
    begsmp = nearest(data.time{1}, 0 + offset);
    endsmp = nearest(data.time{1}, 0.4 - 1./data.fsample + offset);
    tmp2.trial{1} = zeros(size(avg{1},1),480);
    tmp2.time{1}  = data.time{1}(begsmp:endsmp);
    for m = 1:size(avg{1},1)
      tmp2.label{m,1} = ['chan',num2str(m,'%03d')];
    end
    
    for m = 1:4
      avg_fourier{m} = tmp2;
      avg_fourier{m}.trial{1} = avg{m}(:,begsmp:endsmp);
      avg_fourier{m} = ft_freqanalysis(cfg, avg_fourier{m});
      avg_strat_fourier{m} = tmp2;
      avg_strat_fourier{m}.trial{1} = avg_strat{m}(:,begsmp:endsmp);
      avg_strat_fourier{m} = ft_freqanalysis(cfg, avg_strat_fourier{m});
    end
    
    % loop over trials
    for k = 1:numel(data.trial)
      fprintf('%d/%d\n',k,numel(data.trial));
      if any(k==indx1),
        cndtn = 1;
        sel   = sel1(:,indx1==k);
      elseif any(k==indx2),
        cndtn = 2;
        sel   = sel2(:,indx2==k);
      elseif any(k==indx3),
        cndtn = 3;
        sel   = sel3(:,indx3==k);
      elseif any(k==indx4),
        cndtn = 4;
        sel   = sel4(:,indx4==k);
      end
      
      if k==1,
        % allocate the memory for the output
        freq       = cell(size(labelcmb,1),4);
        for m = 1:size(labelcmb,1)
          tmplabel  = {[labelcmb{m,1},'_01'];[labelcmb{m,1},'_02'];[labelcmb{m,2},'_01'];[labelcmb{m,2},'_02']};
          tmp.label = tmplabel;
          freq{m,1} = tmp;
          freq{m,2} = tmp;
          freq{m,3} = tmp;
          freq{m,4} = tmp;
        end
        freq_strat = freq;
        
        % make a sparse projection matrix, mapping tapers to frequencies
        i1 = zeros(0,1);i2 = zeros(0,1);
        for q = 1:601
          i1((q-1)*5+(1:5)) = q;
          i2((q-1)*5+(1:5)) = (q-1)*5+(1:5);
        end
        P = sparse(i1,i2,0.2*ones(size(i1)));
        
      end
      
      tmpdata    = ft_selectdata(data, 'rpt', k, 'toilim', [0 0.4-1./data.fsample]+offset);
      tmpfreq    = ft_freqanalysis(cfg, tmpdata);
      tmpfourier = F * reshape(permute(tmpfreq.fourierspctrm, [2 1 3]),size(F,2),[]); %2nvoxx(ntapxnfreq)
      %tmpcsd     = zeros(301,4,4) + 1i*zeros(301,4,4);
      %tmpcsd     = zeros(1505,16) + 1i*zeros(1505,16);
      
      for m = 1:size(labelcmb,1)
        ix = match_str(label, labelcmb(m,:)');
        ix = [(ix(:)-1)*2+1 (ix(:)-1)*2+2]';
        ix = ix(:);
        
        tmp = transpose(tmpfourier(ix,:));
        
        % subtract the average (for now the unstratified, in order to not
        % further complicate matters
        tmp = tmp - reshape(permute(avg_fourier{cndtn}.fourierspctrm(:,(m-1)*4+(1:4),:), [1 3 2]),[],4);
        
        % this is a fancy way of computing the cross-spectrum
        i1 = repmat(1:4,[1 4]);
        i2 = [1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
        tmpcsd = tmp(:,i1).*conj(tmp(:,i2));
        
        freq{m,cndtn}.crsspctrm = freq{m,cndtn}.crsspctrm + tmpcsd;
        if sel(m),
          freq_strat{m,cndtn}.crsspctrm = freq_strat{m,cndtn}.crsspctrm + tmpcsd;
        end
      end
    end % for k = 1:numel(data.trial)
    
    % normalise for the number of trials that contributed
    for m = 1:size(labelcmb,1)
      freq{m,1}.crsspctrm = permute(reshape(P*freq{m,1}.crsspctrm./numel(indx1),[601 4 4]),[2 3 1]);
      freq{m,2}.crsspctrm = permute(reshape(P*freq{m,2}.crsspctrm./numel(indx2),[601 4 4]),[2 3 1]);
      freq{m,3}.crsspctrm = permute(reshape(P*freq{m,3}.crsspctrm./numel(indx3),[601 4 4]),[2 3 1]);
      freq{m,4}.crsspctrm = permute(reshape(P*freq{m,4}.crsspctrm./numel(indx4),[601 4 4]),[2 3 1]);
      freq_strat{m,1}.crsspctrm = permute(reshape(P*freq_strat{m,1}.crsspctrm./sum(sel1(m,:)),[601 4 4]),[2 3 1]);
      freq_strat{m,2}.crsspctrm = permute(reshape(P*freq_strat{m,2}.crsspctrm./sum(sel2(m,:)),[601 4 4]),[2 3 1]);
      freq_strat{m,3}.crsspctrm = permute(reshape(P*freq_strat{m,3}.crsspctrm./sum(sel3(m,:)),[601 4 4]),[2 3 1]);
      freq_strat{m,4}.crsspctrm = permute(reshape(P*freq_strat{m,4}.crsspctrm./sum(sel4(m,:)),[601 4 4]),[2 3 1]);
    end
    
    % compute granger
    g1ab = zeros(size(labelcmb,1),256);
    g2ab = zeros(size(labelcmb,1),256);
    g3ab = zeros(size(labelcmb,1),256);
    g4ab = zeros(size(labelcmb,1),256);
    g5ab = zeros(size(labelcmb,1),256);
    g1ba = zeros(size(labelcmb,1),256);
    g2ba = zeros(size(labelcmb,1),256);
    g3ba = zeros(size(labelcmb,1),256);
    g4ba = zeros(size(labelcmb,1),256);
    g5ba = zeros(size(labelcmb,1),256);
    g1i = zeros(size(labelcmb,1),256);
    g2i = zeros(size(labelcmb,1),256);
    g3i = zeros(size(labelcmb,1),256);
    g4i = zeros(size(labelcmb,1),256);
    g5i = zeros(size(labelcmb,1),256);
    g1ab_strat = zeros(size(labelcmb,1),256);
    g2ab_strat = zeros(size(labelcmb,1),256);
    g3ab_strat = zeros(size(labelcmb,1),256);
    g4ab_strat = zeros(size(labelcmb,1),256);
    g5ab_strat = zeros(size(labelcmb,1),256);
    g1ba_strat = zeros(size(labelcmb,1),256);
    g2ba_strat = zeros(size(labelcmb,1),256);
    g3ba_strat = zeros(size(labelcmb,1),256);
    g4ba_strat = zeros(size(labelcmb,1),256);
    g5ba_strat = zeros(size(labelcmb,1),256);
    g1i_strat = zeros(size(labelcmb,1),256);
    g2i_strat = zeros(size(labelcmb,1),256);
    g3i_strat = zeros(size(labelcmb,1),256);
    g4i_strat = zeros(size(labelcmb,1),256);
    g5i_strat = zeros(size(labelcmb,1),256);
    
    for m = 1:size(labelcmb,1)
      fprintf('%d/%d\n',m,size(labelcmb,1));
      [tmpg1,tmpg2] = do_granger4x4(freq{m,1}.crsspctrm(:,:,1:512),0:511,1:4);
      g1ab(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g1ba(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g1i(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq{m,2}.crsspctrm(:,:,1:512),0:511,1:4);
      g2ab(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g2ba(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g2i(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq{m,3}.crsspctrm(:,:,1:512),0:511,1:4);
      g3ab(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g3ba(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g3i(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq{m,4}.crsspctrm(:,:,1:512),0:511,1:4);
      g4ab(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g4ba(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g4i(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq{m,1}.crsspctrm(:,:,1:512)+freq{m,2}.crsspctrm(:,:,1:512)+freq{m,3}.crsspctrm(:,:,1:512)+freq{m,4}.crsspctrm(:,:,1:512),0:511,1:4);
      g5ab(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g5ba(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g5i(m,:)  = squeeze(tmpg2(:,1:256));
      
      [tmpg1,tmpg2] = do_granger4x4(freq_strat{m,1}.crsspctrm(:,:,1:512),0:511,1:4);
      g1ab_strat(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g1ba_strat(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g1i_strat(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq_strat{m,2}.crsspctrm(:,:,1:512),0:511,1:4);
      g2ab_strat(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g2ba_strat(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g2i_strat(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq_strat{m,3}.crsspctrm(:,:,1:512),0:511,1:4);
      g3ab_strat(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g3ba_strat(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g3i_strat(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq_strat{m,4}.crsspctrm(:,:,1:512),0:511,1:4);
      g4ab_strat(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g4ba_strat(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g4i_strat(m,:)  = squeeze(tmpg2(:,1:256));
      [tmpg1,tmpg2] = do_granger4x4(freq_strat{m,1}.crsspctrm(:,:,1:512)+freq_strat{m,2}.crsspctrm(:,:,1:512)+freq_strat{m,3}.crsspctrm(:,:,1:512)+freq_strat{m,4}.crsspctrm(:,:,1:512),0:511,1:4);
      g5ab_strat(m,:) = squeeze(tmpg1(1,2,:,1:256));
      g5ba_strat(m,:) = squeeze(tmpg1(2,1,:,1:256));
      g5i_strat(m,:)  = squeeze(tmpg2(:,1:256));
    end
    granger.freq = 0:255;
    granger.labelcmb = labelcmb;
    granger.dimord   = 'chanbcmb_freq';
    granger.sent_early = g1ab;
    granger.sent_late  = g2ab;
    granger.seq_early  = g3ab;
    granger.seq_late   = g4ab;
    granger.sent_early_2 = g1ba;
    granger.sent_late_2  = g2ba;
    granger.seq_early_2  = g3ba;
    granger.seq_late_2   = g4ba;
    granger.sent_early_i = g1i;
    granger.sent_late_i  = g2i;
    granger.seq_early_i  = g3i;
    granger.seq_late_i   = g4i;
    granger.all   = g5ab;
    granger.all_2 = g5ba;
    granger.all_i = g5i;
    
    granger_strat.freq = 0:255;
    granger_strat.labelcmb = labelcmb;
    granger_strat.dimord   = 'chanbcmb_freq';
    granger_strat.sent_early = g1ab_strat;
    granger_strat.sent_late  = g2ab_strat;
    granger_strat.seq_early  = g3ab_strat;
    granger_strat.seq_late   = g4ab_strat;
    granger_strat.sent_early_2 = g1ba_strat;
    granger_strat.sent_late_2  = g2ba_strat;
    granger_strat.seq_early_2  = g3ba_strat;
    granger_strat.seq_late_2   = g4ba_strat;
    granger_strat.sent_early_i = g1i_strat;
    granger_strat.sent_late_i  = g2i_strat;
    granger_strat.seq_early_i  = g3i_strat;
    granger_strat.seq_late_i   = g4i_strat;
    granger_strat.all   = g5ab_strat;
    granger_strat.all_2 = g5ba_strat;
    granger_strat.all_i = g5i_strat;
    
    
    tmp = zeros(4,256);
    tmp2 = zeros(4,256);
    for m = 1:numel(freq)
      for p = 1:256
        tmp(:,p) = diag(freq{m}.crsspctrm(:,:,p));
        tmp2(:,p) = diag(freq_strat{m}.crsspctrm(:,:,p));
      end
      freq{m}.powspctrm = tmp;
      freq_strat{m}.powspctrm = tmp2;
      freq{m} = rmfield(freq{m}, 'crsspctrm');
      freq_strat{m} = rmfield(freq_strat{m}, 'crsspctrm');
    end
    
    mous_db_putdata(subjectname, ['meg_granger_granger_roi_strat',num2str(round(offset*1000),'%03d')], 'granger', 'granger_strat', 'freq', 'freq_strat', rootdir,0);
  end
end
