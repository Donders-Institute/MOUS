
if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/MEG/';  end
if ~exist('computedata',      'var'), computedata      = false;                       end
if ~exist('computedata_seq',  'var'), computedata_seq  = false;                       end
if ~exist('cleandata',        'var'), cleandata        = false;                       end
if ~exist('cleandata_seq',    'var'), cleandata_seq    = false;                       end
if ~exist('dolcmv',           'var'), dolcmv           = false;                       end
if ~exist('dolcmv_seq',       'var'), dolcmv_seq       = false;                       end
if ~exist('computealignment', 'var'), computealignment = false;             end
if ~exist('computealignment_seq', 'var'), computealignment_seq = false;             end
if ~exist('domscca_searchlight', 'var'),     domscca_searchlight     = false;       end
if ~exist('domscca_searchlight_seq', 'var'), domscca_searchlight_seq = false;       end
if ~exist('domscca_searchlight_stretch', 'var'), domscca_searchlight_stretch = false;       end
if ~exist('create_shuffle_indx', 'var'), create_shuffle_indx = false; end
if ~exist('create_shuffle_indx_seq', 'var'), create_shuffle_indx_seq = false; end
if ~exist('makemodels', 'var'), makemodels = false; end
if ~exist('dotrc', 'var'), dotrc = false; end

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
  stretch = ones(1,numel(subj));
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
  
   rng('default'); % reset the number generator, in order to be able to compare across parcels
   if ~skip_noshuffle
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj);
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 4, [],false);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    [cohstim, coh]       = mous_multisetcca_coh(comp);
    trc                  = mous_multisetcca_trc(comp, stimuli);
    comp                 = ft_struct2single(comp);
    savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d', scenario);
    system(sprintf('mkdir -p %s', savedir));
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
    %filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dpcoh',scenario,parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'coh', 'cohstim', 'trc');
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
        paramdir = '/project/3011020.09/jansch/mscca_group/';
        load(fullfile(paramdir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,m,suffix))); % use precomputed ordering for consistency across parcels
        
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
        trctmp                 = mous_multisetcca_trc(compshuf, stimuli);
        Rshuf(:,:,:,cnt)       = single(rhoshuf);
        
        if cnt==1
          trcshuf = trctmp;
        else
          trcshuf.rho(:,:,cnt) = trctmp.rho;
        end
                
        tmpCshuf       = cohshuf.cohspctrm;
        Cshuf(:,1,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
        Cshuf(:,2,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
        Cshuf(:,3,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
      
        tmpCshufstim       = cohshufstim.cohspctrm;
        Cshufstim(:,1,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
        Cshufstim(:,2,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
      end
      
      
      foi   = cohshuf(1).freq;
      savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf2%s',scenario,parcel_indx,suffix));
%       if exist([filename,'.mat'], 'file')
%         tmp = load(filename);
%         Cshuf = cat(3,tmp.Cshuf,Cshuf);
%         Rshuf = cat(4,tmp.Rshuf,Rshuf);
%         Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
%         trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
%       end
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim','trcshuf');
    
  end
end

if domscca_searchlight_stretch
  suffix='';    
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  shift = zeros(1,numel(subj));
  stretch = ones(1,numel(subj));
  if ~exist('shuftype', 'var')
    shuftype = 'none';
  end
  
  if ~exist('parcel_indx', 'var')
    error('a parcel index needs to be specified');
  end
  if ~exist('nrand', 'var')
    nrand = 1:10;
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
  
  tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj);
  [W, A, rho, C, comp, nfold] = mous_multisetcca(tmpdata, nfold, 4, [],false); % returns a deterministic folding for this parcel
  [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  [cohstim, coh]       = mous_multisetcca_coh(comp);
  
  % unfold the audio data to maintain word onsets across modalities,
  % but after 'stretching' of the audio time scale
  selaudio = find(strncmp(subj, 'sub-2', 5));
  selvis   = find(strncmp(subj, 'sub-1', 5));
  groupdatastretch = groupdata;
  
  stretch_vals = [0.9:0.025:1.3];%1 1.05 1.10 1.15 1.20 1.25];
  nstretch = numel(stretch_vals);
  for m = 1:nstretch
    stretch(selaudio) = stretch_vals(m);
    for k = selaudio(:)'
      groupdatastretch{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch_vals(m));
    
      cfg = [];
      cfg.method = 'acrosschannel';
      groupdatastretch{1,k} = ft_channelnormalise(cfg, groupdatastretch{1,k});
    end
  
    % perform the cca
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdatastretch, subj);
    [Wstretch, Astretch, rhostretch, ~, compstretch] = mous_multisetcca(tmpdata, nfold, 4, [], false);
    [compstretch, rhostretch] = mous_multisetcca_postprocess(compstretch, rhostretch, source_parc.label{parcel_indx});
    
    % compute coherence etc
    [cohstretchstim(m), cohstretch(m)] = mous_multisetcca_coh(compstretch);
    Rstretch(:,:,m)                  = rhostretch(:,:,1);
    
    tmpCstretch     = cohstretch(m).cohspctrm;
    Cstretch(:,1,m) = mean(mean(tmpCstretch(selvis,selvis,:,:)))-1./numel(selvis);
    Cstretch(:,2,m) = mean(mean(tmpCstretch(selaudio,selaudio,:,:)))-1./numel(selaudio);
    Cstretch(:,3,m) = mean(mean(tmpCstretch(selvis,selaudio,:,:)));
      
    tmpCstretchstim       = cohstretchstim.cohspctrm;
    Cstretchstim(:,1,m) = mean(abs(tmpCstretchstim(selvis,:,:)));
    Cstretchstim(:,2,m) = mean(abs(tmpCstretchstim(selaudio,:,:)));
    
    groupdatashuf = groupdatastretch;
    cnt = 0;
    savedir = '/project/3011020.09/jansch/mscca_group';
  
    if ~isempty(nrand)
      for mm = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(mm==nrand),numel(nrand));
        cnt = cnt + 1;
        load(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,mm,suffix))); % use precomputed ordering for consistency across parcels
        
        groupdatashuf(selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(selaudio), subjecttiming(selaudio), groupinfo, reorder, stimid, shift(selaudio), stretch(selaudio));
        
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
        
        tmpCshuf       = cohshuf.cohspctrm;
        Cshuf(:,1,m,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
        Cshuf(:,2,m,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
        Cshuf(:,3,m,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
        
        tmpCshufstim       = cohshufstim.cohspctrm;
        Cshufstim(:,1,m,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
        Cshufstim(:,2,m,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
      end
    else
      Cshuf = [];
      Cshufstim = [];
    end  
  end
  foi   = cohstretch(1).freq(1:81);
  label = source_parc.label{parcel_indx};
  savedir = '/project/3011020.09/jansch/mscca_group';
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dstretch',scenario,parcel_indx));
     
  save(filename, 'Cstretch', 'Cstretchstim', 'Rstretch', 'foi', 'label', 'stretch_vals', 'Cshuf', 'Cshufstim');
end

if makemodels
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  suffix = ''; % for now
  loaddir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'comp');
  
%   % this part gets the number of 'trials' that went into each fold. The
%   % rationale is to fit the beta-weights for each fold separately, and to
%   % combine the models to get an F statistic.
%   nfold = 5;
%   nobs  = numel(comp.trial);
%   ix    = round(linspace(0,nobs,nfold+1)); % indices of observations that go into the test sample
%   testfold = cell(nfold,1);
%   for k = 1:nfold
%     testfold{k,1} = (ix(k)+1):ix(k+1);
%   end
%   [tlck, X, V, ivar, statsall, words] = mous_multisetcca_regress(comp, stimuli, testfold);
%   
%   % identify the nouns, adjectives and verbs
%   sel = cell(1,5);
%   for k = 1:5
%     sel{k} =          double(strncmp([words{k}.POS], 'N',   1))*1;
%     sel{k} = sel{k} + double(strncmp([words{k}.POS], 'WW',  2))*2;
%     sel{k} = sel{k} + double(strncmp([words{k}.POS], 'ADJ', 3))*3;
%   end
%   
%   % select these from the data
%   for k = 1:5
%     words{k}.POS      = words{k}.POS(sel{k}>0);
%     words{k}.duration = words{k}.duration(sel{k}>0);
%     words{k}.word     = words{k}.word(sel{k}>0);
%     
%     cfg        = [];
%     cfg.trials = find(sel{k});
%     tlck{k}    = ft_selectdata(cfg, tlck{k});
%     
%     X{k} = X{k}(sel{k}>0,:);
%     V{k} = V{k}(sel{k}>0,:);
%   end
%   [~,~,~,~,stats] = mous_multisetcca_regress(tlck,V,X);

  [tlck, X, V, ivar, statsall, words] = mous_multisetcca_regress(comp, stimuli);
  
  % identify the nouns, adjectives and verbs
  sel =          double(strncmp([words.POS], 'N',   1))*1;
  sel = sel + double(strncmp([words.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([words.POS], 'ADJ', 3))*3;
  
  % select these from the data
  words.POS      = words.POS(sel>0);
  words.duration = words.duration(sel>0);
  words.word     = words.word(sel>0);
    
  cfg        = [];
  cfg.trials = find(sel);
  tlck       = ft_selectdata(cfg, tlck);
    
  X = X(sel>0,:);
  V = V(sel>0,:);
  design = struct('V',V,'X',X);
  [~,~,~,~,stats] = mous_multisetcca_regress(tlck,design);

  tlck_smooth = tlck;
  %for k = 1:numel(tlck)
  %  tmp = tlck{k};
  %  for m = 1:size(tmp.trial,1)
  %    tmp.trial(m,:,:) = ft_preproc_smooth(squeeze(tmp.trial(m,:,:)),6);
  %  end
  %  tlck_smooth{k} = tmp;
  %end
  for m = 1:size(tlck.trial,1)
    tlck_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),6);
  end
  
  folds = mous_makefolds(size(tlck_smooth.trial,1), 5);
  [~,~,~,~,stats_smooth] = mous_multisetcca_regress(tlck_smooth,design,folds,true);
  
  
  nrand = 500;
  
  tlck_smooth.trial = tlck_smooth.trial(:,1:3,:);
  tlck_smooth.label = tlck_smooth.label(1:3);
  for j = 1:nrand
    % mean subtracted duration is in column 3, this shuffles the words
    % maintaining the distribution in binned duration
    fprintf('performing randomization %d/%d\n',j,nrand);
    dur = X(:,3);
    edges1 = eqspace(dur,5);
    lf  = X(:,4);
    edges2 = eqspace(lf,5);
    [n1,bin1] = histc(dur,edges1);
    [n2,bin2] = histc(lf, edges2);
    
    r_idx = (1:numel(dur))';
    for m = 1:numel(n1)-1
      for mm = 1:numel(n2)-1
        tmp = r_idx(bin1==m&bin2==mm);
        r_idx(bin1==m&bin2==mm)=tmp(randperm(numel(tmp)));
      end
    end
    tmpdesign.X = X(r_idx,:);
    tmpdesign.V = V(r_idx,:);
    
    folds = mous_makefolds(size(tlck_smooth.trial,1), 5);
    [~,~,~,~,stats_rand(j)] = mous_multisetcca_regress(tlck_smooth,tmpdesign,folds,true);
    stats_rand(j).w2v.dR      = stats_rand(j).w2v.dR(1:3,:);
    stats_rand(j).w2v_orth.dR = stats_rand(j).w2v_orth.dR(1:3,:);
    stats_rand(j).x.dR        = stats_rand(j).x.dR(1:3,:,:);
    stats_rand(j).xorth.dR    = stats_rand(j).xorth.dR(1:3,:,:);
    
  end
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_models',scenario,parcel_indx,suffix));
  save(filename, 'ivar', 'X', 'V', 'words', 'stats_smooth', 'stats_rand');
end

if dotrc
  % do time resolved correlation
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  suffix = ''; % for now
  loaddir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'comp');
  
  [tlck, X, V, ivar, statsall, words] = mous_multisetcca_regress(comp, stimuli);
  
  % identify the nouns, adjectives and verbs
  sel =          double(strncmp([words.POS], 'N',   1))*1;
  sel = sel + double(strncmp([words.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([words.POS], 'ADJ', 3))*3;
  
  % select these from the data
  words.POS      = words.POS(sel>0);
  words.duration = words.duration(sel>0);
  words.word     = words.word(sel>0);
    
  cfg        = [];
  cfg.trials = find(sel);
  tlck        = ft_selectdata(cfg, tlck);
  tlck_smooth = tlck;
  for m = 1:size(tlck.trial,1)
    tlck_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
  end
  
  selaudio = find(contains(comp.label, 'sub-2'));
  selvis   = find(contains(comp.label, 'sub-1'));
  
  
  tmp = permute(tlck_smooth.trial(:,4:end,:),[2 1 3]);
  %tmp = tmp-nanmean(tmp(:,:,6:8),3);
  tmp = tmp-nanmean(tmp,2);
  
  for k = 1:109
    tmpx=tmp(:,:,k);
    %tmpx=tmpx-nanmean(tmp(:,:,1:(k-1)),3);
    tmpc=tmpx*tmpx';
    c(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
  end
  %C(:,1) = squeeze(mean(mean(c(selvis,selvis,:))))-1./numel(selvis);
  %C(:,2) = squeeze(mean(mean(c(selaudio,selaudio,:))))-1./numel(selaudio);
  C(:,1) = squeeze(mean(mean(c(selvis,selaudio,:))));
  
  rng('default'); % ensure same 'random' behaviour for each parcel.
  nrand = 5000;
  Cx = zeros(size(C,1),nrand);
  for m = 1:nrand
    if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
    tmp2 = tmp;
    tmp2(selvis,:,:) = tmp(selvis,randperm(size(tmp,2)),:);
    for k = 1:109
      tmpx=tmp2(:,:,k);
      %tmpx=tmpx-nanmean(tmp(:,:,1:(k-1)),3);
      tmpc=tmpx*tmpx';
      c(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
    end
    %Cx(:,1,m) = squeeze(mean(mean(c(selvis,selvis,:))))-1./numel(selvis);
    %Cx(:,2,m) = squeeze(mean(mean(c(selaudio,selaudio,:))))-1./numel(selaudio);
    Cx(:,m) = squeeze(mean(mean(c(selvis,selaudio,:))));
  end
  tim = tlck.time;
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_trc',scenario,parcel_indx,suffix));
  save(filename, 'C', 'Cx', 'tim');

end