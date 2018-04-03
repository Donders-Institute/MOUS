
if ~exist('rootdir',         'var'), rootdir         = '/project/3011020.09/MEG/';  end
if ~exist('computedata',     'var'), computedata     = false;                       end
if ~exist('computedata_seq', 'var'), computedata_seq = false;                       end
if ~exist('cleandata',       'var'), cleandata       = false;                       end
if ~exist('cleandata_seq',   'var'), cleandata_seq   = false;                       end
if ~exist('dolcmv',          'var'), dolcmv          = false;                       end
if ~exist('dolcmv_seq',      'var'), dolcmv_seq      = false;                       end
if ~exist('computealignment', 'var'), computealignment = false;             end
if ~exist('computealignment_seq', 'var'), computealignment_seq = false;             end
if ~exist('domscca_searchlight', 'var'),     domscca_searchlight     = false;       end
if ~exist('domscca_searchlight_seq', 'var'), domscca_searchlight_seq = false;       end
if ~exist('domscca_searchlight_stretch', 'var'), domscca_searchlight_stretch = false;       end
if ~exist('create_shuffle_indx', 'var'), create_shuffle_indx = false; end
if ~exist('create_shuffle_indx_seq', 'var'), create_shuffle_indx_seq = false; end
if ~exist('makemodels', 'var'), makemodels = false; end

if ~exist('subjectname', 'var') && ~exist('scenario', 'var')
  error('at least a subjectname or a scenario number needs to be defined');
end

if exist('scenario', 'var')
  subj = mous_db_getfilename('allAV', 'subjectname');
  sce  = mous_db_getfilename(subj,    'scenario');
  sel  = strncmp(sce, num2str(scenario), 1);
  subj = subj(sel);
  sce  = sce(sel);
end

if computedata
  data = mous_erf_sentences(subjectname, 1);
  mous_db_putdata(subjectname, 'meg_multisetcca_data', 'data', rootdir);
end

if computedata_seq
  data = mous_erf_sentences(subjectname, 2);
  mous_db_putdata(subjectname, 'meg_multisetcca_data_seq', 'data', rootdir);
end

if cleandata
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_data');
    cfg = [];
    cfg.method = 'summary';
    cfg.keeptrial = 'nan';
    cfg.channel = 'MEG';
    data = ft_rejectvisual(cfg, data);
    mous_db_putdata(subj{k}, 'meg_multisetcca_data', 'data');
  end
end

if cleandata_seq
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_data_seq');
    cfg = [];
    cfg.method = 'summary';
    cfg.keeptrial = 'nan';
    cfg.channel = 'MEG';
    data = ft_rejectvisual(cfg, data);
    mous_db_putdata(subj{k}, 'meg_multisetcca_data_seq', 'data');
  end
end
  
if dolcmv
  mous_db_getdata(subjectname, 'meg_multisetcca_data');
  [source_parc, filterlabel] = mous_multisetcca_lcmv(subjectname, data);
  mous_db_putdata(subjectname, 'meg_multisetcca_lcmv_parc', 'source_parc', 'filterlabel', rootdir);
end

if dolcmv_seq
  mous_db_getdata(subjectname, 'meg_multisetcca_data_seq');
  [source_parc, filterlabel] = mous_multisetcca_lcmv(subjectname, data);
  mous_db_putdata(subjectname, 'meg_multisetcca_lcmv_parc_seq', 'source_parc', 'filterlabel', rootdir);
end

if computealignment || computealignment_seq
  % this chunk of code creates a file for each subject that has been
  % presented with the same paradigm, which contains information about how
  % to align the trials such that the timing is optimised for multisetcca
  
  % use case specific stuff without duplicating the following large block
  % of code. This mutually excludes both flags to be true at the same time
  if computealignment && computealignment_seq
    error('not both can be true at the same time');
  elseif computealignment
    suffix = ''; % the filenames don't have a suffix
  elseif computealignment_seq
    suffix = '_seq';
  end
 
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s',suffix));
    if strcmp(sce{k}(2:end), 'Vis')
      timinginfo = mous_multisetcca_adjusttiming_vis(subj{k}, data);
      elseif strcmp(sce{k}(2:end), 'Aud')
      timinginfo = mous_multisetcca_adjusttiming_aud(subj{k}, data);
    end
    mous_db_putdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',suffix), 'timinginfo');
  end
  
  % the following chunk of code is needed to get a specification of how to
  % align the trials across subjects, and to accommodate the different time
  % axes within modality (potentially due to block breaks etc), and to
  % accommodate the time axes across modalities.
  D = cell(1,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',suffix));
    D{k} = timinginfo;
  end
  
  trialid = (1:1000)';
  sel     = false(1000,numel(D));
  nsmp    =   nan(1000,numel(D));
  begtim  =   nan(1000,numel(D));
  
  for k = 1:numel(D)
    % identify the sentences that occur in any of the input datasets
    tmp = D{k}.trialinfo(:,end);
    seltmp = isfinite(tmp);
    tmp = tmp(seltmp);
    sel(tmp,k)    = true;
    nsmp(tmp,k)   = cellfun('size',D{k}.time(seltmp),2);
    begtim(tmp,k) = cell2mat(cellcolselect(D{k}.time(seltmp),1));
  end
  ix = ~all(sel==false,2);
  
  trialid = trialid(ix);
  ntrl    = numel(trialid);
  sel     = sel(ix,:);
  nsmp    = nsmp(ix,:);
  begtim  = begtim(ix,:);
  endtim  = begtim+(nsmp-1)./120;
  
  maxnsmp = max(nsmp,[],2);
  mintim  = min(begtim,[],2);
  maxtim  = max(endtim,[],2);
  
  groupinfo.trialid = trialid;
  groupinfo.ntrl    = ntrl;
  groupinfo.sel     = sel;
  groupinfo.nsmp    = nsmp;
  groupinfo.begtim  = begtim;
  groupinfo.endtim  = endtim;
  groupinfo.maxnsmp = maxnsmp;
  groupinfo.mintim  = mintim;
  groupinfo.maxtim  = maxtim;
  groupinfo.subj    = subj;
  
  % add some stimulus information to the structure
  load mous_stimuli
  stimuli = stimuli(trialid);
  for k = 1:numel(trialid)
    stiminfo(k) = keepfields(stimuli(k),{'words','string','id','timinginfo_visual','timinginfo'});
    stiminfo(k).timinginfo_visual = stiminfo(k).timinginfo_visual(:,1:2);
  end
  groupinfo.stiminfo = stiminfo;
  
  for k = 1:numel(subj)
    mous_db_putdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',suffix), 'groupinfo');
  end
end

if create_shuffle_indx
  mous_db_getdata(subj{1},'meg_multisetcca_groupinfo');
  for m = 1:500
    [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
    savedir = '/project/3011020.09/jansch/mscca_group';
    save(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
    clear reorder stimid;
  end
end

if create_shuffle_indx_seq
  mous_db_getdata(subj{1},'meg_multisetcca_groupinfo_seq');
  for m = 1:500
    [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
    savedir = '/project/3011020.09/jansch/mscca_group';
    save(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d_seq',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
    clear reorder stimid;
  end
end

if domscca_searchlight || domscca_searchlight_seq
  if domscca_searchlight &&  domscca_searchlight_seq
    error('not both can be true at the same time');
  elseif domscca_searchlight
    suffix = ''; % the filenames don't have a suffix
  elseif domscca_searchlight_seq
    suffix = '_seq';
  end
  
  load mous_stimuli; 
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  shift = zeros(1,numel(subj));
  stretch = zeros(1,numel(subj));
  if ~exist('shuftype', 'var')
    shuftype = 'none';
  end
  if ~exist('skip_noshuffle', 'var')
    skip_noshuffle = false;
  end
  if ~exist('parcel_indx', 'var')
    error('a parcel index needs to be specified');
  end
  if ~exist('nrand', 'var')
    nrand = 100;
  end
  if numel(nrand)==1
    nrand = 1:nrand;
  end
  % this step does a mscca on a specified parcel, and requires the
  % parcellation to have been computed. Also, it is a bit inefficient,
  % because it processes the data up until the level of a parcellated
  % representation, but that is for memory reasons
  groupdata   = cell(1,numel(subj));
  subjectdata = cell(1,numel(subj));
  subjecttiming = cell(1,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s',suffix));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc%s',suffix));
    source_parc.filterlabel = filterlabel; % for checking channel order
    subjectdata{1,k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    if strncmp(subj{k}, 'sub-2', 5)
      % align the trials' time axes to the onset of the first word, rather
      % than the onset of the audio file
      tmp = subjectdata{1,k}.time;
      stim_id = subjectdata{1,k}.trialinfo(:,end);
      for kk = 1:numel(tmp)
        tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
        tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
      end
      subjectdata{1,k}.time = tmp;
    end
    for kk = 1:numel(subjectdata{1,k}.trial)
      tmp = subjectdata{1,k}.trial{kk};
      tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
      subjectdata{1,k}.trial{kk} = tmp;
    end
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',suffix));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',suffix));
    subjecttiming{1,k} = timinginfo; % subject specific information about timing
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch(k));
  
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
    for kk = 1:numel(groupdata{1,k}.trial)
      sel = nearest(groupdata{1,k}.time{kk},-0.1);
      groupdata{1,k}.trial{kk} = groupdata{1,k}.trial{kk}(:,sel:end);
      groupdata{1,k}.time{kk}  = groupdata{1,k}.time{kk}(sel:end);
    end
  end
  
  if ~skip_noshuffle
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj);
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 4, [],false);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    [cohstim, coh]       = mous_multisetcca_coh(comp);
    comp                 = ft_struct2single(comp);
    savedir = '/project/3011020.09/jansch/mscca_group';
    system(sprintf('mkdir -p %s', savedir));
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
    %filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dpcoh',scenario,parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'coh', 'cohstim');
  end
  
  switch shuftype
    case 'lenient'
      % lenient shuffling, that maintins the timing within sensory
      % modality, but does not obey individual word onsets across
      % modalities
      
      selaudio = find(strncmp(subj, 'sub-2', 5));
      selvis   = find(strncmp(subj, 'sub-1', 5));
      for m = nrand(:)'
        [groupdatashuf, allshufvec] = mous_multisetcca_shuffle(groupdata, {selvis(:)' selaudio(:)'}); % shuffle before folding
        stimdata                    = mous_multisetcca_shufflestimdata(groupdata{1}, allshufvec([selvis(1) selaudio(1)],:));
        T = stimdata{1}.trialinfo;
        cfg = [];
        cfg.operation = 'add';
        cfg.parameter = 'trial';
        stimdata = ft_math(cfg, stimdata{:});
        stimdata.trialinfo = T;
        
        % perform the cca
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(groupdatashuf, nfold, 4, [], false);
        [compshuf, rhoshuf] = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        % reorder the stimonset data
        reorder = zeros(numel(stimdata.trial),1);
        for k = 1:numel(reorder)
          reorder(k) = find(stimdata.trialinfo(:,end)==compshuf.trialinfo(k));
        end
        stimdata.trialinfo = stimdata.trialinfo(reorder,:);
        stimdata.time      = stimdata.time(reorder);
        stimdata.trial     = stimdata.trial(reorder);
        for k = 1:numel(stimdata.trial)
          stimdata.trial{k}(~isfinite(stimdata.trial{k})) = 0;
        end
        % compute coherence etc
        [cohshufstim(m), cohshuf(m)] = mous_multisetcca_coh(compshuf,stimdata);
        Rshuf(:,:,:,m)              = single(rhoshuf);
      end
      Cshuf = single(cat(4,cohshuf.cohspctrm));
      Cshuf = Cshuf(:,:,1:41,:);
      Cshufstim = single(cat(3,cohshufstim.cohspctrm));
      Cshufstim = Cshufstim(:,1:41,:);
      foi   = cohshuf(1).freq(1:41);
      savedir = '/project/3011020.09/jansch/mscca_group';
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf',scenario,parcel_indx));
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Cshuf = cat(4,tmp.Cshuf,Cshuf);
        Rshuf = cat(4,tmp.Rshuf,Rshuf);
        Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
      end
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim');
    
    case 'conservative'
      % unfold the audio data to maintain word onsets across modalities,
      % but after swapping sentences
            
      selaudio = find(strncmp(subj, 'sub-2', 5));
      selvis   = find(strncmp(subj, 'sub-1', 5));
      groupdatashuf = groupdata;
      
      cnt = 0;
      Cshufstim = zeros(81,2,numel(nrand));
      Cshuf     = zeros(81,3,numel(nrand));
      for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        load(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,m,suffix))); % use precomputed ordering for consistency across parcels
        
        groupdatashuf(selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(selaudio), subjecttiming(selaudio), groupinfo, reorder, stimid, shift, stretch);
        
        for k = 1:numel(groupdatashuf)
          for kk = 1:numel(groupdatashuf{1,k}.trial)
            sel = nearest(groupdatashuf{1,k}.time{kk},-0.1);
            groupdatashuf{1,k}.trial{kk} = groupdatashuf{1,k}.trial{kk}(:,sel:end);
            groupdatashuf{1,k}.time{kk}  = groupdatashuf{1,k}.time{kk}(sel:end);
          end
        end
        % perform the cca
        tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf, subj);
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(tmpdata, nfold, 4, [], false);
        [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        % compute coherence etc
        [cohshufstim, cohshuf] = mous_multisetcca_coh(compshuf);
        Rshuf(:,:,:,cnt)       = single(rhoshuf);
        
        tmpCshuf       = cohshuf.cohspctrm;
        Cshuf(:,1,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
        Cshuf(:,2,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
        Cshuf(:,3,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
      
        tmpCshufstim       = cohshufstim.cohspctrm;
        Cshufstim(:,1,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
        Cshufstim(:,2,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
      end
      
      
      foi   = cohshuf(1).freq;
      savedir = '/project/3011020.09/jansch/mscca_group';
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf2%s',scenario,parcel_indx,suffix));
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Cshuf = cat(3,tmp.Cshuf,Cshuf);
        Rshuf = cat(4,tmp.Rshuf,Rshuf);
        Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
      end
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim');
    
  end
end

if domscca_searchlight_stretch
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  shift = zeros(1,numel(subj));
  stretch = zeros(1,numel(subj));
  if ~exist('shuftype', 'var')
    shuftype = 'none';
  end
  
  if ~exist('parcel_indx', 'var')
    error('a parcel index needs to be specified');
  end
  if ~exist('nrand', 'var')
    nrand = 100;
  end
  % this step does a mscca on a specified parcel, and requires the
  % parcellation to have been computed. Also, it is a bit inefficient,
  % because it processes the data up until the level of a parcellated
  % representation, but that is for memory reasons
  groupdata   = cell(1,numel(subj));
  subjectdata = cell(1,numel(subj));
  subjecttiming = cell(1,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_multisetcca_data');
    mous_db_getdata(subj{k}, 'meg_multisetcca_lcmv_parc');
    source_parc.filterlabel = filterlabel; % for checking channel order
    subjectdata{1,k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    
    mous_db_getdata(subj{k}, 'meg_multisetcca_timinginfo');
    mous_db_getdata(subj{k}, 'meg_multisetcca_groupinfo');
    subjecttiming{1,k} = timinginfo; % subject specific information about timing
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch(k));
  end
  for k = 1:numel(subj)
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
  end
  
  [W, A, rho, C, comp, nfold] = mous_multisetcca(groupdata, nfold, 4, [],false);
  [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  [cohstim, coh]       = mous_multisetcca_coh(comp);
  
  % unfold the audio data to maintain word onsets across modalities,
  % but after 'stretching' of the audio time scale
  selaudio = find(strncmp(subj, 'sub-2', 5));
  selvis   = find(strncmp(subj, 'sub-1', 5));
  groupdatastretch = groupdata;
  
  stretch_vals = [1.05 1.10 1.15 1.20 1.25];
  nstretch = numel(stretch_vals);
  for m = 1:nstretch
    for k = selaudio(:)'
      groupdatastretch{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch_vals(m));
    
      cfg = [];
      cfg.method = 'acrosschannel';
      groupdatastretch{1,k} = ft_channelnormalise(cfg, groupdatastretch{1,k});
    end
  
    % perform the cca
    [Wstretch, Astretch, rhostretch, ~, compstretch] = mous_multisetcca(groupdatastretch, nfold, 4, [], false);
    [compstretch, rhostretch] = mous_multisetcca_postprocess(compstretch, rhostretch, source_parc.label{parcel_indx});
    
    % compute coherence etc
    [cohstretchstim(m), cohstretch(m)] = mous_multisetcca_coh(compstretch);
    Rstretch(:,:,:,m)                  = rhostretch;
    Cstretch(:,:,:,m)                  = cohstretch(m).cohspctrm(:,:,1:41);
    Cstretchstim(:,:,m)                = cohstretchstim(m).cohspctrm(:,1:41);
  end
  foi   = cohstretch(1).freq(1:41);
  savedir = '/project/3011020.09/jansch/mscca_group';
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dstretch2',scenario,parcel_indx));
  if exist([filename,'.mat'], 'file')
    tmp = load(filename);
    Cstretch = cat(4,tmp.Cstretch,Cstretch);
    Rshuf = cat(4,tmp.Rshuf,Rshuf);
    Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
  end
  save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim');
  
    
  savedir = '/project/3011020.09/jansch/mscca_group';
  system(sprintf('mkdir -p %s', savedir));
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d_stretch',scenario,parcel_indx));
  %filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dpcoh',scenario,parcel_indx));
  save(filename, 'rho', 'W', 'A', 'comp', 'coh', 'cohstim');
  
end

if makemodels
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  suffix = ''; % for now
  loaddir = '/project/3011020.09/jansch/mscca_group';
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'comp');
  
  % this part gets the number of 'trials' that went into each fold. The
  % rationale is to fit the beta-weights for each fold separately, and to
  % combine the models to get an F statistic.
  nfold = 5;
  nobs  = numel(comp.trial);
  ix    = round(linspace(0,nobs,nfold+1)); % indices of observations that go into the test sample
  testfold = cell(nfold,1);
  for k = 1:nfold
    testfold{k,1} = (ix(k)+1):ix(k+1);
  end
  [tlck, X, V, ivar, statsall, words] = mous_multisetcca_regress(comp, stimuli, testfold);
  
  % identify the nouns, adjectives and verbs
  sel = cell(1,5);
  for k = 1:5
    sel{k} =          double(strncmp([words{k}.POS], 'N',   1))*1;
    sel{k} = sel{k} + double(strncmp([words{k}.POS], 'WW',  2))*2;
    sel{k} = sel{k} + double(strncmp([words{k}.POS], 'ADJ', 3))*3;
  end
  
  % select these from the data
  for k = 1:5
    words{k}.POS      = words{k}.POS(sel{k}>0);
    words{k}.duration = words{k}.duration(sel{k}>0);
    words{k}.word     = words{k}.word(sel{k}>0);
    
    cfg        = [];
    cfg.trials = find(sel{k});
    tlck{k}    = ft_selectdata(cfg, tlck{k});
    
    X{k} = X{k}(sel{k}>0,:);
    V{k} = V{k}(sel{k}>0,:);
  end
  [~,~,~,~,stats] = mous_multisetcca_regress(tlck,V,X);
  
  tlck_smooth = tlck;
  for k = 1:numel(tlck)
    tmp = tlck{k};
    for m = 1:size(tmp.trial,1)
      tmp.trial(m,:,:) = ft_preproc_smooth(squeeze(tmp.trial(m,:,:)),6);
    end
    tlck_smooth{k} = tmp;
  end
  [~,~,~,~,stats_smooth] = mous_multisetcca_regress(tlck_smooth,V,X);
  
  
  nrand = 250;
  for j = 1:nrand
    % mean subtracted duration is in column 4, this shuffles the words
    % maintaining the distribution in binned duration
    for k = 1:numel(X)
      dur = X{k}(:,4);
      edges = -0.2:0.05:0.15;
      edges(end+1) = 0.5;
      [n,bin] = histc(dur,edges);
      r_idx = (1:numel(dur))';
      for m = 1:numel(n)-1
        tmp = r_idx(bin==m);
        r_idx(bin==m)=tmp(randperm(numel(tmp)));
      end
      Xtmp{k} = X{k}(r_idx,:);
      Vtmp{k} = V{k}(r_idx,:);
    end
    [~,~,~,~,stats_rand(j)] = mous_multisetcca_regress(tlck_smooth,Vtmp,Xtmp);
    stats_rand(j).w2v.F      = stats_rand(j).w2v.F(1:3,:);
    stats_rand(j).w2v_orth.F = stats_rand(j).w2v_orth.F(1:3,:);
    stats_rand(j).x.F        = stats_rand(j).x.F(1:3,:,:);
    stats_rand(j).xorth.F    = stats_rand(j).xorth.F(1:3,:,:);
    
  end
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_models',scenario,parcel_indx,suffix));
  save(filename, 'ivar', 'X', 'V', 'statsall', 'stats', 'words', 'stats_smooth', 'stats_rand');
end
