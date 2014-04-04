if ~exist('domne_main', 'var')
  domne_main = 0;
end

if ~exist('domne_parametric', 'var')
  domne_parametric = 0;
end

if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/MEG';
end
  
if domne_main,
  if ~exist('suffix_rawdata', 'var')
    suffix_rawdata = 'meg_processed_{_preProcERFvisual_word_all_02-1ds}';
  end
  if ~exist('suffix_erfdata', 'var')
    suffix_erfdata = 'meg_processed_{_erf_visual_word_all_02-1ds-ag}';
  end
  if ~exist('suffix_mnedata', 'var')
    suffix_mnedata = strrep(suffix_rawdata, 'erf', 'mne');
  end
  
  % compute covariance matrix of the noise
  % use an equal amount of sentence and sequence 'baselines' for the cov
  mous_db_getdata(subjectname, suffix_rawdata, rootdir);
  data.grad = ft_convert_units(data.grad, 'm'); % this is related to an FT issue with the units
  % if all is explicitly set to 'm' it should be OK. 
 
  data     = ft_selectdata(data, 'toilim', [-inf 0.6]);
  database = ft_selectdata(data, 'toilim', [-inf 0]);
  selsent  = find(ismember(database.trialinfo(:,2),[1 2 5 6]) & database.trialinfo(:,end)==1);
  selseq   = find(ismember(database.trialinfo(:,2),[3 4 7 8]) & database.trialinfo(:,end)==1);
  n        = min(numel(selsent),numel(selseq));
  tmp      = randperm(numel(selsent));selsent=sort(selsent(tmp(1:n)));
  tmp      = randperm(numel(selseq));selseq=sort(selseq(tmp(1:n)));
  
  cfg                  = [];
  cfg.channel          = 'MEG';
  cfg.vartrllength     = 2;
  cfg.feedback         = 'textbar';
  cfg.covariance       = 'yes';
  cfg.covariancewindow = [-inf 0]; % timepoints that are before the zero-time point in the trials
  cfg.preproc.demean   = 'yes';
  cfg.preproc.baselinewindow = [-inf 0];
  cfg.keeptrials       = 'no';
  cfg.trials           = sort([selsent(:);selseq(:)]);
  tlck = ft_timelockanalysis(cfg, database);
  
  % load the 2D sourcemodel and deal with the midline
  mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D_surfreg');
  if exist('bnd', 'var')
    sourcemodel = bnd; clear bnd;
  end
  if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
    sourcmodel.pos = sourcemodel.pnt;
    sourcemodel    = rmfield(sourcemodel, 'pnt');
  end
  sourcemodel = ft_convert_units(sourcemodel, 'm'); % due to an FT issue related to units
  % explicit conversion to 'm'. This should be OK  
  % NOTE: the areas of the triangles are not updated, I think that this is not a problem
  % because the area weighting is relative, i.e. the scale of the numbers shouldn't matter.
  % Yet, I am not 100% sure. FIXME
 
  load atlas_conte69_8196reg
  sourcemodel.inside  = find(atlas.parcellation3==1);% & atlas.parcellation2~=1);
  sourcemodel.outside = find(atlas.parcellation3==2);% | atlas.parcellation2==1);
  sourcemodelorig     = sourcemodel;
  
  % load the volume conductor model of the head
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  if exist('vol', 'var')
    headmodel = vol; clear vol;
  end
  %headmodel = ft_convert_units(headmodel, 'cm');
  headmodel = ft_convert_units(headmodel, 'm');
  
  % Compute the leadfields
  cfg          = [];
  cfg.grad     = tlck.grad;
  cfg.vol      = headmodel;
  cfg.grid     = sourcemodel;
  cfg.channel  = 'MEG';
  cfg.feedback = 'textbar';
  %cfg.normalize = 'yes';
  sourcemodel  = ft_prepare_leadfield(cfg);
  
  
  %% Compute MNE for each condition
  
  % this is a bit clunky, but in order to make the pipeline general purpose
  % (i.e. using uniform variable names), it has to try out the possible
  % naming schemes Annika adopted in the preprocessed data files. The if else
  % etc needs to be extended when needed. Now only assume the first case.
  % FIXME, also make the filename configurable, because now it will always
  % work.
  mous_db_getdata(subjectname, suffix_erfdata, rootdir);
  if exist('senWord_AG', 'var')
    data1 = senWord_AG;
    data2 = seqWord_AG;
  else
    error('don''t know which variable to use');
  end
  data1.cov = tlck.cov; % add the covariance computed from both conditions
  data2.cov = tlck.cov;
  
  data1 = ft_selectdata(data1, 'toilim', [-inf 0.6]);
  data2 = ft_selectdata(data2, 'toilim', [-inf 0.6]);
  
  if 1,
    % this part computes the area per triangle and uses the squared area as a
    % prior on the source covariance matrix. This is equivalent to how it's
    % done in brainstorm
    
    % the areas need to be defined per vertex, not per triangle
    % take hs1
    vertex_area = zeros(size(sourcemodelorig.pos,1),1);
    for k = 1:size(sourcemodelorig.pos,1)
      sel = find(sum(sourcemodelorig.tri==k,2));
      vertex_area(k,1) = sum(sourcemodelorig.area(sel))./numel(sel);
    end
    
    weightlim = 5;
    weightexp = 0.5;
    
    
    % this part computes the sum of squares of the leadfields, and uses the
    % inverse of it for depth weighting.
    Lss = zeros(8193,1)+nan;
    for k = 1:numel(sourcemodel.inside)
      indx = sourcemodel.inside(k);
      lf   = sourcemodel.leadfield{indx};
      Lss(indx,:) = sum(sum(lf.^2));
    end
    Lss    = (1./Lss)';
    minLss = min(Lss(sourcemodelorig.inside));
    Lss(Lss>minLss.*weightlim.^2) = minLss.*weightlim.^2;
    
    A = ((vertex_area(:).^2).*Lss(:)).^weightexp;
    A = repmat(A(sourcemodel.inside),[1 3])';
    
    % create a source covariance matrix that is equivalent to the area(^2)
    % times the 1./leadfield-sum-of-square to the power of weightexp
    % weighting in bst_wmne
    S = spdiags(A(:),0,speye(numel(A)));
    
  end
  
  cfg                 = [];
  cfg.method          = 'mne';
  cfg.vol             = headmodel;
  cfg.grid            = sourcemodel;
  cfg.mne.prewhiten   = 'yes';
  cfg.mne.lambda      = 3; % used to be 2
  cfg.mne.scalesourcecov  = 'yes';
  cfg.mne.keepfilter  = 'yes';
  cfg.mne.noiselambda = 0.2*trace(data1.cov)./size(data1.cov,1);
  cfg.mne.sourcecov   = S;
  source_sent         = ft_sourceanalysis(cfg, data1);
  source_seq          = ft_sourceanalysis(cfg, data2);
  
  cfg            = [];
  cfg.demean     = 'yes';
  cfg.projectmom = 'yes';
  cfg.zscore     = 'no';
  
  % we probably don't want the projection to be condition specific, rather
  % compute the orientation on the conditions combined.
  
  sd_Sent        = ft_sourcedescriptives(cfg, source_sent);
  sd_Seq         = ft_sourcedescriptives(cfg, source_seq);
  
  source         = source_sent;
  % source.avg.pow = (source_sent.avg.pow+source_seq.avg.pow)./2;
  for k = 1:numel(source.inside)
    mom = (source.avg.mom{source.inside(k)} + source_seq.avg.mom{source.inside(k)})./2;
    source.avg.mom{source.inside(k)} = mom;
  end
  sd             = ft_sourcedescriptives(cfg, source);
  sd_Seq.avg.ori = sd.avg.ori;
  sd_Sent.avg.ori = sd.avg.ori;
  % replace the pow with the orientation from the combined data
  for k = 1:numel(sd.inside)
    indx = sd.inside(k);
    sd_Sent.avg.pow(indx,:) = abs(sd.avg.ori{indx}*source_sent.avg.mom{indx});
    sd_Seq.avg.pow(indx,:)  = abs(sd.avg.ori{indx}*source_seq.avg.mom{indx});
  end
  
  sd_Sent.tri = sourcemodelorig.tri;
  sd_Seq.tri  = sourcemodelorig.tri;
  
  % do the normalisation to get a 'dSPM'
  npnt = size(sd_Sent.pos,1);
  sd_Sent.avg.dspm = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Sent.avg.pow;
  sd_Seq.avg.dspm  = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Seq.avg.pow;
  
  sd_Sent.avg = rmfield(sd_Sent.avg, 'mom');
  sd_Seq.avg  = rmfield(sd_Seq.avg,  'mom');
  
  % save the solution
  source = sd_Seq;
  mous_db_putdata(subjectname, [suffix_mnedata,'-seq_currentdensity_weighted'],  'source', rootdir);
  
  source = sd_Sent;
  mous_db_putdata(subjectname, [suffix_mnedata,'-sent_currentdensity_weighted'], 'source', rootdir);
end

if domne_parametric
  % this part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix_rawdata', 'var')
    error('you need to specify the file suffix for the preprocessed data');
  end
  mous_db_getdata(subjectname, suffix_rawdata, rootdir);
  
  if ~exist('suffix_mne', 'var')
    error('you need to specify the file suffix for the mne data');
  end
  %IMPORTANT: always use the sent condition in the suffix, because this is
  %assumed later on. Otherwise the conditions will be swapped
  mous_db_getdata(subjectname, suffix_mne, rootdir);
  
  % create the spatial filter matrix
  F = zeros(8196, size(source.avg.filter{source.inside(1)},2));
  for k = 1:numel(source.inside)
    F(source.inside(k),:) = source.avg.ori{source.inside(k)}*source.avg.filter{source.inside(k)};
  end
 
  % make the number of trials per condition equal
  sel1 = find(ismember(data.trialinfo(:,2),[1 2 5 6]));
  sel2 = find(ismember(data.trialinfo(:,2),[3 4 7 8]));
  
  n1 = numel(sel1); sel1 = sel1(randperm(n1));
  n2 = numel(sel2); sel2 = sel2(randperm(n2));
  n  = min(n1,n2);
  sel1 = sort(sel1(1:n));
  sel2 = sort(sel2(1:n));
  data = ft_selectdata(data, 'rpt', [sel1(:);sel2(:)]);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
  
  [tlck_sent, stat_sent, stat2_sent, mu_sent] = mous_makecontrast(data, 'wordsent_parametric_blc', [], F);
  [tlck_seq,  stat_seq,  stat2_seq,  mu_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc',  [], F);
  
  tlck = tlck_sent;
  stat = stat_sent;
  mu   = mu_sent;
  mous_db_putdata(subjectname, [suffix_mne,'_parametric_blc'], 'tlck', 'stat', 'mu', rootdir);
  tlck = tlck_seq;
  stat = stat_seq;
  mu   = mu_seq;
  mous_db_putdata(subjectname, [strrep(suffix_mne, 'sent', 'seq'),'_parametric_blc'], 'tlck', 'stat', 'mu', rootdir);
end

if domne_parcellate
  % this part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix', 'var')
    error('you need to specify the file suffix for the timelocked data');
  end
  mous_db_getdata(subjectname, suffix);%, rootdir);
  sel = match_str(tlck.label, ft_channelselection('MEG',tlck.label));
  tlck.label = tlck.label(sel);
  if isfield(tlck, 'avg'),   tlck.avg   = tlck.avg(sel,:);     end;
  if isfield(tlck, 'trial'), tlck.trial = tlck.trial(:,sel,:); end;
  tlcksent = tlck;
  mous_db_getdata(subjectname, strrep(suffix,'sent','seq'));%, rootdir);
  sel = match_str(tlck.label, ft_channelselection('MEG',tlck.label));
  tlck.label = tlck.label(sel);
  if isfield(tlck, 'avg'),   tlck.avg   = tlck.avg(sel,:);     end;
  if isfield(tlck, 'trial'), tlck.trial = tlck.trial(:,sel,:); end;
  tlckseq = tlck;
  
  tlck.avg = (tlcksent.avg.*tlcksent.dof(sel,:)+tlckseq.avg.*tlckseq.dof(sel,:))./(tlcksent.dof(sel,:)+tlckseq.dof(sel,:));
  
  if ~exist('suffix_mne', 'var')
    error('you need to specify the file suffix for the mne data');
  end
  mous_db_getdata(subjectname, suffix_mne);
  
  load atlas_conte69_8196reg_LR_brodmann_subparc;
  
  tlck         = mous_mne_parcellate(source,tlck,atlas);
  U = tlck.U; 
  S = tlck.S;
  N = tlck.N;
  atlas.filter = tlck.F;
  
  tlck            = mous_mne_parcellate(source,tlcksent,atlas);
  tlck.U          = U;
  tlck.S          = S;
  tlck.N          = N;
  tlck.suffix_mne = suffix_mne;
  tlck.suffix     = suffix;
  if ~exist('suffix_output', 'var')
    error('you need to specify the file suffix for the output data');
  end
  mous_db_putdata(subjectname, suffix_output, 'tlck', rootdir);
  tlck            = mous_mne_parcellate(source,tlckseq,atlas);
  tlck.U          = U;
  tlck.S          = S;
  tlck.N          = N;
  tlck.suffix_mne = suffix_mne;
  tlck.suffix     = suffix;
  mous_db_putdata(subjectname, strrep(suffix_output,'sent','seq'), 'tlck', rootdir);

  
end