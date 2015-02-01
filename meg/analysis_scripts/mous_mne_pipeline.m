% specification of flags that determine which section(s) of the pipeline
% will be executed
if ~exist('domne_main',       'var'),  domne_main        = 0; end
if ~exist('domne_parametric', 'var'),  domne_parametric  = 0; end
if ~exist('domne_parcellate', 'var'),  domne_parcellate  = 0; end
if ~exist('domne_parcellate2', 'var'), domne_parcellate2 = 0; end
if ~exist('domne_denoise',     'var'), domne_denoise     = 0; end
if ~exist('dodspm',            'var'), dodspm            = 0; end     
if ~exist('domne_earlylate',   'var'), domne_earlylate   = 0; end
if ~exist('domne_parametric_rc', 'var'), domne_parametric_rc = 0; end

% specify the directory into which the results will be saved
if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/MEG';
end
  
if domne_main,
  % This section computes the the minimum-norm solution for the two
  % original main conditions of interest: sentences and sequences,
  % based on a 'common' spatial filter, i.e. the inverse operator
  % is computed with a regularisation noise covariance matrix that
  % has been computed across the conditions of interest. 
  % 
  % - the noise covariance is computed based on a specified datafile
  %   containing a 'raw' data structure, based on suffix_rawdata,
  %   taking only the pre-zero timewindow of the first word in the sentence/sequence
  % - the source level data is computed by projecting sensor level
  %   ERFs through the inverse operator. the datafile for the ERFs
  %   is based on suffix_erfdata
  % - the results will be saved in file, based on suffix_mnedata
  % - the assumption is that the suffix_erfdata file contains the
  %   ERFs of the respective main conditions

  % specify the suffices if not specified by the user
  if ~exist('suffix_rawdata', 'var'), suffix_rawdata = 'meg_erf_allwords_02-nextword'; end
  if ~exist('suffix_erfdata', 'var'), suffix_erfdata = 'meg_erf_allwords_02-nextword-allwords-ag'; end
  if ~exist('suffix_mnedata', 'var'), suffix_mnedata = strrep(suffix_rawdata, 'erf', 'mne'); end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % computation of the noise covariance matrix
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % get the single trial data
  mous_db_getdata(subjectname, suffix_rawdata, rootdir);
  data.grad = ft_convert_units(data.grad, 'm');
 
  data     = ft_selectdata(data, 'toilim', [-inf 0.6]);
  database = ft_selectdata(data, 'toilim', [-inf 0]);

  % the following classifies the single words according to main condition and whether
  % it reflects the first word in the sentence, NOTE: this assumes the condition trigger
  % to be in the second column of the trialinfo field, and the ordinal word index in the 
  % fifth row of the trialinfo field
  selsent  = find(ismember(database.trialinfo(:,2),[1 2 5 6]) & database.trialinfo(:,5)==1);
  selseq   = find(ismember(database.trialinfo(:,2),[3 4 7 8]) & database.trialinfo(:,5)==1);
  
  % equate the number of trials that enter into the computation across conditions
  n        = min(numel(selsent),numel(selseq));
  tmp      = randperm(numel(selsent)); selsent = sort(selsent(tmp(1:n)));
  tmp      = randperm(numel(selseq));  selseq  = sort(selseq(tmp(1:n)));
  
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
  tlck                 = ft_timelockanalysis(cfg, database);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % preparation of the anatomical data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % load the 2D sourcemodel and deal with the midline
  mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D_surfreg');
  if exist('bnd', 'var'),
    sourcemodel = bnd; 
    clear bnd;
  end
  if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt'),
    sourcmodel.pos = sourcemodel.pnt;
    sourcemodel    = rmfield(sourcemodel, 'pnt');
  end
  sourcemodel = ft_convert_units(sourcemodel, 'm');  
  % NOTE: the areas of the triangles are not updated, I think that this is not a problem
  % because the area weighting is relative, i.e. the scale of the numbers shouldn't matter.
  % Yet, I am not 100% sure. FIXME
 
  % define the medial wall parcel as outside. NOTE: this assumes
  % the medial wall te have a value of 2
  load atlas_conte69_8196reg_LR_brodmann_subparc
  sourcemodel.inside  = find(atlas.parcellation~=2);
  sourcemodel.outside = find(atlas.parcellation==2);
  sourcemodelorig     = sourcemodel;
  
  % load the volume conduction model of the head
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  if exist('vol', 'var'),
    headmodel = vol; 
    clear vol;
  end
  headmodel = ft_convert_units(headmodel, 'm');
  
  % pre-compute the leadfields
  cfg          = [];
  cfg.grad     = tlck.grad;
  cfg.vol      = headmodel;
  cfg.grid     = sourcemodel;
  cfg.channel  = 'MEG';
  cfg.feedback = 'textbar';
  %cfg.normalize = 'yes';
  sourcemodel  = ft_prepare_leadfield(cfg);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % computation of the MNE inverse operator
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % this is a bit clunky, but in order to make the pipeline general purpose
  % (i.e. using uniform variable names), it has to try out the possible
  % naming schemes Annika adopted in the preprocessed data files. The if else
  % etc needs to be extended when needed. Now only assume the first case.
  % FIXME, also make the filename configurable, because now it will always
  % work.
  mous_db_getdata(subjectname, suffix_erfdata, rootdir);
  rootdir = '/project/3011020.09/MEG';
  if exist('senWord_AG', 'var')
    data1 = senWord_AG;
    data2 = seqWord_AG;
  else
    error('don''t know which variable to use');
  end
  
  % the following is to ensure the correct order of channels in the covariance
  % compared to the data. added 2014-06-20
  [a,b]     = match_str(data1.label,tlck.label);
  data1.cov = zeros(numel(data1.label));
  data2.cov = zeros(numel(data2.label));
  
  % add the covariance computed from both conditions
  data1.cov(a,a) = tlck.cov(b,b);
  data2.cov(a,a) = tlck.cov(b,b);

  % only select up until 0.6 seconds after word onset  
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
      sel              = find(sum(sourcemodelorig.tri==k,2));
      vertex_area(k,1) = sum(sourcemodelorig.area(sel))./numel(sel);
    end
    weightlim = 5;
    weightexp = 0.5;
    
    % this part computes the sum of squares of the leadfields, and uses the
    % inverse of it for depth weighting.
    Lss = zeros(8192,1)+nan;
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
  
  % don't keep the filter for the list condition,
  % the spatial filter will be the same as for source_sent.
  % added this line 2014-06-19
  cfg.mne.keepfilter  = 'no'; 
  source_seq          = ft_sourceanalysis(cfg, data2);
  
  
  cfg                = [];
  cfg.demean         = 'yes';
  cfg.baselinewindow = [-0.2 0];
  cfg.projectmom     = 'yes';
  cfg.zscore         = 'no';
  
  % we probably don't want the projection to be condition specific, rather
  % compute the orientation on the conditions combined.
  sd_Sent        = ft_sourcedescriptives(cfg, source_sent);
  sd_Seq         = ft_sourcedescriptives(cfg, source_seq);
  
  source         = source_sent;
  for k = 1:numel(source.inside)
    mom = (source.avg.mom{source.inside(k)} + source_seq.avg.mom{source.inside(k)})./2;
    source.avg.mom{source.inside(k)} = mom;
  end
  sd              = ft_sourcedescriptives(cfg, source);
  sd_Seq.avg.ori  = sd.avg.ori;
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
  if dodspm,
    npnt = size(sd_Sent.pos,1);
    sd_Sent.avg.dspm = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Sent.avg.pow;
    sd_Seq.avg.dspm  = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Seq.avg.pow;
  end
  
  sd_Sent.avg = rmfield(sd_Sent.avg, 'mom');
  sd_Seq.avg  = rmfield(sd_Seq.avg,  'mom');
  
  % save the output
  source = sd_Seq;
  mous_db_putdata(subjectname, [suffix_mnedata,'_seq'],  'source', rootdir, 1);
  
  source = sd_Sent;
  mous_db_putdata(subjectname, [suffix_mnedata,'_sent'], 'source', rootdir, 1);
end

if domne_parametric
  % This section computes the source level representation of the 'parametric'
  % effect, i.e. the slope fitted (for each time point in the ERF) as a function
  % of ordinal word position. 
  % This part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix_rawdata', 'var')
    suffix_rawdata = 'meg_erf_allwords_02-nextword';
    % error('you need to specify the file suffix for the preprocessed data');
  end
  mous_db_getdata(subjectname, suffix_rawdata, rootdir);
  
  if ~exist('suffix_mne', 'var')
    suffix_mne = strrep(suffix_rawdata, 'erf', 'mne');
    suffix_mne = cat(2, suffix_mne, '_sent');
    % error('you need to specify the file suffix for the mne data');
  end
  %IMPORTANT: always use the sent condition in the suffix, because this is
  %assumed later on. Otherwise the conditions will be swapped, and because
  %as of 2014-06-19 only the sentence condition file contains the spatial
  %filters
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
  data = ft_selectdata(data, 'toilim', [-inf 0.6]);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second, this is hard coded!
  data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
  
  [tlck_sent, stat_sent, stat2_sent, mu_sent] = mous_makecontrast(data, 'wordsent_parametric_blc', [], F);
  [tlck_seq,  stat_seq,  stat2_seq,  mu_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc',  [], F);
  
  tlck = ft_struct2single(tlck_sent);
  stat = stat_sent;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_sent);
  mous_db_putdata(subjectname, [suffix_mne,'_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
  tlck = ft_struct2single(tlck_seq);
  stat = stat_seq;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_seq);
  mous_db_putdata(subjectname, [strrep(suffix_mne, 'sent', 'seq'),'_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
end

if domne_parametric_rc
  % this part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix_rawdata', 'var')
    suffix_rawdata = 'meg_erf_allwords_02-nextword';
    % error('you need to specify the file suffix for the preprocessed data');
  end
  mous_db_getdata(subjectname, suffix_rawdata, rootdir);
  
  if ~exist('suffix_mne', 'var')
    suffix_mne = strrep(suffix_rawdata, 'erf', 'mne');
    suffix_mne = cat(2, suffix_mne, '_sent');
    % error('you need to specify the file suffix for the mne data');
  end
  %IMPORTANT: always use the sent condition in the suffix, because this is
  %assumed later on. Otherwise the conditions will be swapped, and because
  %as of 2014-06-19 only the sentence condition file contains the spatial
  %filters
  mous_db_getdata(subjectname, suffix_mne, rootdir);
  
  % create the spatial filter matrix
  F = zeros(8196, size(source.avg.filter{source.inside(1)},2));
  for k = 1:numel(source.inside)
    F(source.inside(k),:) = source.avg.ori{source.inside(k)}*source.avg.filter{source.inside(k)};
  end
 
  % make the number of trials per condition equal
  sel1 = find(ismember(data.trialinfo(:,2),[5 6])); % rc sent
  sel2 = find(ismember(data.trialinfo(:,2),[7 8])); % rc seq
  sel3 = find(ismember(data.trialinfo(:,2),[1 2])); % mix sent
  sel4 = find(ismember(data.trialinfo(:,2),[3 4])); % mix seq
  
  n1(1) = numel(sel1); sel1 = sel1(randperm(n1(1)));
  n1(2) = numel(sel2); sel2 = sel2(randperm(n1(2)));
  n1(3) = numel(sel3); sel3 = sel3(randperm(n1(3)));
  n1(4) = numel(sel4); sel4 = sel4(randperm(n1(4)));
  
  n  = min(n1);
  %do rc  sent and seq
  sel1 = sort(sel1(1:n));
  sel2 = sort(sel2(1:n));
  data1 = ft_selectdata(data, 'rpt', [sel1(:);sel2(:)]);
  data1 = ft_selectdata(data1, 'toilim', [-inf 0.6]);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data1.trialinfo = data1.trialinfo(:,[1 5 2 3 4]);
  
  [tlck_sent, stat_sent, stat2_sent, mu_sent] = mous_makecontrast(data1, 'wordsent_parametric_blc', [], F);
  [tlck_seq,  stat_seq,  stat2_seq,  mu_seq]  = mous_makecontrast(data1, 'wordseq_parametric_blc',  [], F);
  
  tlck = ft_struct2single(tlck_sent);
  stat = stat_sent;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_sent);
  mous_db_putdata(subjectname, [suffix_mne,'_rc_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
  tlck = ft_struct2single(tlck_seq);
  stat = stat_seq;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_seq);
  mous_db_putdata(subjectname, [strrep(suffix_mne, 'sent', 'seq'),'_rc_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
  
  %do mix  sent and seq
  sel3 = sort(sel3(1:n));
  sel4 = sort(sel4(1:n));
  data2 = ft_selectdata(data, 'rpt', [sel3(:);sel4(:)]);
  data2 = ft_selectdata(data2, 'toilim', [-inf 0.6]);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data2.trialinfo = data2.trialinfo(:,[1 5 2 3 4]);
  
  [tlck_sent, stat_sent, stat2_sent, mu_sent] = mous_makecontrast(data2, 'wordsent_parametric_blc', [], F);
  [tlck_seq,  stat_seq,  stat2_seq,  mu_seq]  = mous_makecontrast(data2, 'wordseq_parametric_blc',  [], F);
  
  tlck = ft_struct2single(tlck_sent);
  stat = stat_sent;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_sent);
  mous_db_putdata(subjectname, [suffix_mne,'_mix_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
  tlck = ft_struct2single(tlck_seq);
  stat = stat_seq;
  stat = rmfield(stat, {'prob', 'mask', 'cirange'});
  mu   = single(mu_seq);
  mous_db_putdata(subjectname, [strrep(suffix_mne, 'sent', 'seq'),'_mix_parametric_blc'], 'tlck', 'stat', 'mu', rootdir,1);
end

if domne_earlylate
  % do a quick and dirty (don't use mous_makecontrast) comparison by
  % projecting the sensor ERFs throught the spatial filter, and save the
  % difference waveform
  
  if ~exist('suffix_mne', 'var')
    suffix_mne = 'meg_mne_allwords_02-nextword';
    suffix_mne = cat(2, suffix_mne, '_sent');
    % error('you need to specify the file suffix for the mne data');
  end
  
  mous_db_getdata(subjectname, suffix_mne);
  F = zeros(8196, size(source.avg.filter{source.inside(1)},2));
  for kk = 1:numel(source.inside)
    k = source.inside(kk);
    F(k,:) = source.avg.ori{k}*source.avg.filter{k};
  end
  
  tlck1 = mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword_wordsentRC_early');
  tlck2 = mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword_wordsentRC_late');
  tlck3 = mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword_wordsentMIX_early');
  tlck4 = mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword_wordsentMIX_late');
  sel   = match_str(tlck1.label, ft_channelselection('MEG', tlck1.label));
  
  tlck1 = ft_selectdata(tlck1, 'toilim', [-inf 0.6]);
  tlck2 = ft_selectdata(tlck2, 'toilim', [-inf 0.6]);
  tlck3 = ft_selectdata(tlck3, 'toilim', [-inf 0.6]);
  tlck4 = ft_selectdata(tlck4, 'toilim', [-inf 0.6]);
  
  dat1  = (F*tlck1.avg(sel,:));
  dat2  = (F*tlck2.avg(sel,:));
  dat3  = (F*tlck3.avg(sel,:));
  dat4  = (F*tlck4.avg(sel,:));
  ix    = nearest(tlck1.time, 0);
  dat1  = dat1 - repmat(nanmean(dat1(:,1:ix),2),[1 size(dat1,2)]);
  ix    = nearest(tlck2.time, 0);
  dat2  = dat2 - repmat(nanmean(dat2(:,1:ix),2),[1 size(dat2,2)]);
  ix    = nearest(tlck3.time, 0);
  dat3  = dat3 - repmat(nanmean(dat3(:,1:ix),2),[1 size(dat3,2)]);
  ix    = nearest(tlck4.time, 0);
  dat4  = dat4 - repmat(nanmean(dat4(:,1:ix),2),[1 size(dat4,2)]);
  dpow  = abs(dat1)-abs(dat2); clear dat1 dat2
  dpow2 = abs(dat3)-abs(dat4); clear dat3 dat4
  
  source = rmfield(source, 'avg');
  source.avg.pow = dpow;
  mous_db_putdata(subjectname, 'meg_mne_allwords_02-nextword_wordsentRC_early-late', 'source');
  source.avg.pow = dpow2;
  mous_db_putdata(subjectname, 'meg_mne_allwords_02-nextword_wordsentMIX_early-late', 'source');
    
end

if domne_parcellate
    
  % this part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix_erfdata', 'var')
    error('you need to specify the file suffix for the timelocked data');
  end
  mous_db_getdata(subjectname, suffix_erfdata);%, rootdir);
  if exist('senWord_AG', 'var')
    tlck(1) = senWord_AG;
    tlck(2) = seqWord_AG;
  elseif exist('stat', 'var')
    tmp1 = tlck;
    %tmp1.avg = stat.stat;
    %tmp1.dof = ones(size(tmp1.avg)); % dummy variable, needed below, for weighting the conditions
  
    % assume the need to load in another file where the 'sent' is replaced
    % with 'seq', and that the required variable is called 'stat'
    mous_db_getdata(subjectname, strrep(suffix_erfdata, 'sent', 'seq'));
    tmp2 = tlck;
    %tmp2.avg = stat.stat;
    %tmp2.dof = ones(size(tmp2.avg));
    
    tlck(1) = tmp1;
    tlck(2) = tmp2;
    clear tmp1 tmp2;
  elseif exist('tlck', 'var')
    % do nothing
  else
    error('cannot do the parcellation on the requested data');
  end
  
  for k = 1:numel(tlck)
    sel  = match_str(tlck(k).label, ft_channelselection('MEG',tlck(k).label));
    sel2 = nearest(tlck(k).time,-0.2):nearest(tlck(k).time, 0.6);
    tlck(k).label = tlck(k).label(sel);
    if isfield(tlck(k), 'avg'),    tlck(k).avg    = tlck(k).avg(sel,sel2);      end;
    if isfield(tlck(k), 'dof'),    tlck(k).dof    = tlck(k).dof(sel,sel2);      end;
    if isfield(tlck(k), 'stat'),   tlck(k).stat   = tlck(k).stat(sel,sel2);     end;
    if isfield(tlck(k), 'prob'),   tlck(k).prob   = tlck(k).prob(sel,sel2);     end;
    if isfield(tlck(k), 'mask'),   tlck(k).mask   = tlck(k).mask(sel,sel2);     end;
    if isfield(tlck(k), 'cirange'),   tlck(k).cirange   = tlck(k).cirange(sel,sel2);     end;
    
    if isfield(tlck(k), 'trial'), tlck(k).trial = tlck(k).trial(:,sel,sel2); end;
    if isfield(tlck(k), 'trial2'), tlck(k).trial2 = tlck(k).trial2(:,:,sel2); end;
    tlck(k).time = tlck(k).time(sel2);
  end
  
  tlck(end+1) = tlck(1);
  for k = 1:numel(tlck)-1
    if k==1
      tlck(end).avg = tlck(1).avg.*tlck(1).dof;
      tlck(end).dof = tlck(1).dof;
    else
      tlck(end).avg = tlck(end).avg+tlck(k).avg.*tlck(k).dof;
      tlck(end).dof = tlck(end).dof+tlck(k).dof;
    end
  end
  tlck(end).avg = tlck(end).avg./tlck(end).dof;
 
  if ~exist('suffix_mne', 'var')
    error('you need to specify the file suffix for the mne data');
  end
  mous_db_getdata(subjectname, suffix_mne);
  if ~exist('parcel_atlas', 'var')
      load atlas_conte69_8196reg_LR_brodmann_subparc;
  else
      load(atlas)
  end

  tmp = mous_mne_parcellate(source,tlck(end),atlas, 'svdmethod', 'projectavg');
  U            = tmp.U; 
  S            = tmp.S;
  N            = tmp.N;
  atlas.filter = tmp.F;
  
  data = tlck(1:end-1);
  clear tlck;
  for k = 1:numel(data)
    tmp            = mous_mne_parcellate(source,data(k),atlas);
    tmp.U          = U;
    tmp.S          = S;
    tmp.N          = N;
    tmp.suffix_mne = suffix_mne;
    tmp.suffix     = suffix_erfdata;
    if ~exist('suffix_output', 'var')
      error('you need to specify the file suffix for the output data');
    end
    if ~isempty(strfind(suffix_output, 'sent')) && numel(data)==2 && k==1
      tlck = tmp;
      mous_db_putdata(subjectname, suffix_output, 'tlck', rootdir);
    elseif ~isempty(strfind(suffix_output, 'sent')) && numel(data)==2 k==2
      tlck = tmp;
      mous_db_putdata(subjectname, strrep(suffix_output,'sent','seq'), 'tlck', rootdir);
    else
      tlck(k) = tmp;
    end
  end
  if numel(tlck)>1 || numel(data)==1
    mous_db_putdata(subjectname, suffix_output, 'tlck', rootdir);
  end
end
if domne_denoise
  % this assume domne_parametric and domne_parcellate to be done. it
  % operates on the parametric analysis results
  if ~exist('suffix', 'var')
    error('a file suffix should be given');
  end
  mous_db_getdata(subjectname, suffix, rootdir);
  
  addpath('/home/language/jansch/matlab/toolboxes/EP_den_auto/EP_den_Auto');
  handles.par.samples = 512;
  handles.par.scales  = 5;
  handles.par.stim    = nearest(tlck.time, 0);
  
  dat   = tlck.avg;
  dat   = dat - repmat(nanmean(dat(:,1:nearest(tlck.time,0)),2),[1 numel(tlck.time)]);
  dat   = cat(2, dat,                  zeros(   numel(tlck.label),512-numel(tlck.time)));
  trial = cat(3, tlck.trial(2:11,:,:), zeros(10,numel(tlck.label),512-numel(tlck.time)));
  
  cleandat   = dat+nan;
  cleantrial = trial+nan;
  for k = 1:numel(tlck.label)
    %fprinsuffix_rawdata = 'meg_erf_allwords_02-nextword';tf('denoising channel %d/%d\n',k,numel(tlck.label));
    if any(~isfinite(dat(k,:)))
      continue;
    else
      [~, cleandat(k,:), den_coeff, y] = Run_NZT(dat(k,:), handles);
      cleantrial(:,k,:)                = st_den(squeeze(trial(:,k,:))', den_coeff, handles);
    end
  end
  cleandat   = cleandat(:,1:numel(tlck.time));
  cleantrial = cleantrial(:,:,1:numel(tlck.time));
  
  tlck.trial = cleantrial;
  tlck.avg   = cleandat;
  mous_db_putdata(subjectname, [suffix,'_denoised'], 'tlck', rootdir);
end

if domne_parcellate2
  % this part assumes that it can use precomputed MNE filters, and that the
  % filters have been computed on the same data as the one that will be
  % projected
  
  if ~exist('suffix_erfdata', 'var')
    suffix_erfdata = 'meg_erf_allwords_02-nextword-allwords-ag';
  end
  mous_db_getdata(subjectname, suffix_erfdata);%, rootdir);
  tlck = senWord_AG;
  sel = match_str(tlck.label, ft_channelselection('MEG',tlck.label));
  sel2 = 1:nearest(tlck.time, 0.6);
  tlck.label = tlck.label(sel);
  if isfield(tlck, 'avg'),   tlck.avg   = tlck.avg(sel,sel2);     end;
  if isfield(tlck, 'dof'),   tlck.dof   = tlck.dof(sel,sel2);     end;
  if isfield(tlck, 'trial'), tlck.trial = tlck.trial(:,sel,sel2); end;
  tlck.time = tlck.time(sel2);
  tlcksent = tlck;
  
  %tlck= mous_db_getdata(subjectname, strrep(suffix_erfdata,'sent','seq'));%, rootdir);
  tlck = seqWord_AG;
  sel = match_str(tlck.label, ft_channelselection('MEG',tlck.label));
  sel2 = 1:nearest(tlck.time, 0.6);
  tlck.label = tlck.label(sel);
  if isfield(tlck, 'avg'),   tlck.avg   = tlck.avg(sel,sel2);     end;
  if isfield(tlck, 'dof'),   tlck.dof   = tlck.dof(sel,sel2);     end;
  if isfield(tlck, 'trial'), tlck.trial = tlck.trial(:,sel,sel2); end;
  tlck.time = tlck.time(sel2);
  tlckseq = tlck;
  
  parcellation = mous_mne_makeparcellation(subjectname, 200);
  
  mous_db_getdata(subjectname, 'meg_mne_allwords_02-nextword_sent');
  tlcksent = mous_mne_parcellate(source,tlcksent,parcellation, 'svdmethod', 'projectavg');
  tlckseq  = mous_mne_parcellate(source,tlckseq, parcellation, 'svdmethod', 'projectavg');

  if ~exist('suffix_output', 'var')
    error('you need to specify the file suffix for the output data');
  end
  tlck = tlcksent;
  mous_db_putdata(subjectname, suffix_output, 'tlck', 'parcellation', rootdir);
  tlck = tlckseq;
  mous_db_putdata(subjectname, strrep(suffix_output,'sent','seq'), 'tlck', 'parcellation', rootdir);
end

