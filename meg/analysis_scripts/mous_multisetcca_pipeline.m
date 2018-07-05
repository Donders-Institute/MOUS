
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
if ~exist('domscca_searchlight_shift', 'var'), domscca_searchlight_shift = false;       end
if ~exist('domscca_searchlight_pairwise', 'var'),     domscca_searchlight_pairwise     = false;       end
if ~exist('create_shuffle_indx', 'var'), create_shuffle_indx = false; end
if ~exist('create_shuffle_indx_seq', 'var'), create_shuffle_indx_seq = false; end
if ~exist('makemodels', 'var'), makemodels = false; end
if ~exist('dotrc', 'var'), dotrc = false; end
if ~exist('dotrc_pairwise', 'var'), dotrc_pairwise = false; end
if ~exist('compare2simple', 'var'), compare2simple = false; end
if ~exist('do_clusterstats', 'var'), do_clusterstats = false; end
if ~exist('do_plotting', 'var'), do_plotting = false; end

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

%--------------------------------------------------------------------------
%The following chunk of code does a 'searchlight' based multisetcca, where
%the searchlight is defined as the 5-component timecourse, describing a
%parcel, indicated with parcel_indx. It uses the same initialization of the
%random number generator, thus allowing identical folding across parcels,
%that can therefore be meaningfully compared post-hoc. The shuffling
%schemes implemented are either 'lenient', and 'conservative', where it has
%been decided that 'conservative' is most meaningful, because it obeys the
%approximate timing information of the word onsets across stimulation
%modalities.
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
        Rshuf(1,1,cnt)         = single(mean(mean(rhoshuf(selvis,selvis,1))))-1./numel(selvis);
        Rshuf(1,2,cnt)         = single(mean(mean(rhoshuf(selvis,selaudio,1))));
        Rshuf(2,1,cnt)         = single(mean(mean(rhoshuf(selaudio,selvis,1))));
        Rshuf(2,2,cnt)         = single(mean(mean(rhoshuf(selaudio,selaudio,1))))-1./numel(selaudio);
        
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
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Cshuf = cat(3,tmp.Cshuf,Cshuf);
        Rshuf = cat(3,tmp.Rshuf,Rshuf);
        Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
        trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
      end
      trcshuf = ft_struct2single(trcshuf);
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim','trcshuf');
    
  end
end
%--------------------------------------------------------------------------

if domscca_searchlight_stretch
  load mous_stimuli;
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
  
  rng('default'); % reset the number generator, in order to be able to compare across parcels
  [W, A, rho, C, comp, nfold] = mous_multisetcca(tmpdata, nfold, 4, [],false); % returns a deterministic folding for this parcel
  [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
% trc                  = mous_multisetcca_trc(comp, stimuli);
  
  % unfold the audio data to maintain word onsets across modalities,
  % but after 'stretching' of the audio time scale
  selaudio = find(strncmp(subj, 'sub-2', 5));
  selvis   = find(strncmp(subj, 'sub-1', 5));
  groupdatastretch = groupdata;
  
  stretch_vals = 1./(1.1:-0.05:0.5);%[0.9:0.025:1.3];%1 1.05 1.10 1.15 1.20 1.25];
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
    
    trctmp                 = mous_multisetcca_trc(compstretch, stimuli);
    if m==1
      trcstretch = trctmp;
    else
      trcstretch.rho(:,:,m) = trctmp.rho;
    end
        
    % compute coherence etc
    [cohstretchstim(m), cohstretch(m)] = mous_multisetcca_coh(compstretch);
    Rstretch(:,:,m)                  = rhostretch(:,:,1);
    
    tmpCstretch     = cohstretch(m).cohspctrm;
    Cstretch(:,1,m) = mean(mean(tmpCstretch(selvis,selvis,:,:)))-1./numel(selvis);
    Cstretch(:,2,m) = mean(mean(tmpCstretch(selaudio,selaudio,:,:)))-1./numel(selaudio);
    Cstretch(:,3,m) = mean(mean(tmpCstretch(selvis,selaudio,:,:)));
      
    tmpCstretchstim       = cohstretchstim(m).cohspctrm;
    Cstretchstim(:,1,m) = mean(abs(tmpCstretchstim(selvis,:,:)));
    Cstretchstim(:,2,m) = mean(abs(tmpCstretchstim(selaudio,:,:)));
    
    groupdatashuf = groupdatastretch;
    
    savedir = '/project/3011020.09/jansch/mscca_group';
  
    if ~isempty(nrand)
      cnt = 0;
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
        trctmp                 = mous_multisetcca_trc(compshuf, stimuli);
        if m==1 && ~exist('trcstretchshuf', 'var')
          trcstretchshuf = trctmp;
        else
          trcstretchshuf.rho(:,:,m,cnt) = trctmp.rho;
        end
%         % compute coherence etc
%         [cohshufstim, cohshuf] = mous_multisetcca_coh(compshuf);
%         
%         tmpCshuf       = cohshuf.cohspctrm;
%         Cshuf(:,1,m,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
%         Cshuf(:,2,m,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
%         Cshuf(:,3,m,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
%         
%         tmpCshufstim       = cohshufstim.cohspctrm;
%         Cshufstim(:,1,m,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
%         Cshufstim(:,2,m,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
        Cshuf = [];
        Cshufstim = [];
      end
    else
      Cshuf = [];
      Cshufstim = [];
      trcstretchshuf = [];
    end  
  end
  %foi   = cohstretch(1).freq(1:81);
  label = source_parc.label{parcel_indx};
  savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dstretch',scenario,parcel_indx));
     
  save(filename, 'Rstretch', 'label', 'stretch_vals', 'trcstretch', 'trcstretchshuf');
end

if domscca_searchlight_shift
  load mous_stimuli;
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
  
    
  % unfold the audio data to maintain word onsets across modalities,
  % but after 'shifting' of the audio time scale
  selaudio = find(strncmp(subj, 'sub-2', 5));
  selvis   = find(strncmp(subj, 'sub-1', 5));
  groupdatashift = groupdata;
  
  if ~exist('shift_vals', 'var')
    shift_vals = 0:2:20;%[0.9:0.025:1.3];%1 1.05 1.10 1.15 1.20 1.25];
  end
  
  for k = selvis(:)'
    for kk = 1:numel(groupdatashift{1,k}.trial)
      sel = nearest(groupdatashift{1,k}.time{kk},-0.1);
      groupdatashift{1,k}.trial{kk} = groupdatashift{1,k}.trial{kk}(:,sel:end);
      groupdatashift{1,k}.time{kk}  = groupdatashift{1,k}.time{kk}(sel:end);
    end
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdatashift{1,k} = ft_channelnormalise(cfg, groupdatashift{1,k});
  end
  
  nshift = numel(shift_vals);
  for m = 1:nshift
    shift(selaudio) = shift_vals(m);
    for k = selaudio(:)'
      groupdatashift{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift_vals(m), stretch(k));
    
      for kk = 1:numel(groupdatashift{1,k}.trial)
        sel = nearest(groupdatashift{1,k}.time{kk},-0.1);
        groupdatashift{1,k}.trial{kk} = groupdatashift{1,k}.trial{kk}(:,sel:end);
        groupdatashift{1,k}.time{kk}  = groupdatashift{1,k}.time{kk}(sel:end);
      end
      cfg = [];
      cfg.method = 'acrosschannel';
      groupdatashift{1,k} = ft_channelnormalise(cfg, groupdatashift{1,k});
    end
  
    % perform the cca
    rng('default'); % reset the number generator, in order to be able to compare across parcels
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdatashift, subj);
    [Wshift, Ashift, rhoshift, ~, compshift] = mous_multisetcca(tmpdata, nfold, 4, [], false);
    [compshift, rhoshift] = mous_multisetcca_postprocess(compshift, rhoshift, source_parc.label{parcel_indx});
    tlcktmp               = mous_multisetcca_extractwords(compshift, stimuli);
    trctmp                = mous_multisetcca_trc(tlcktmp, stimuli, 'dosmooth',5);
    if m==1
      trcshift = trctmp;
    else
      trcshift.rho(:,:,m) = trctmp.rho;
    end
           
    groupdatashuf = groupdatashift;
    
    savedir = '/project/3011020.09/jansch/mscca_group';
  
    if ~isempty(nrand)
      cnt = 0;
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
        rng('default'); % reset the number generator, in order to be able to compare across parcels
        tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf, subj);
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(tmpdata, nfold, 4, [], false);
        [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        tlcktmp               = mous_multisetcca_extractwords(compshuf, stimuli);
        trctmp                = mous_multisetcca_trc(tlcktmp, stimuli, 'dosmooth',5);
        if m==1 && ~exist('trcshiftshuf', 'var')
          trcshiftshuf = trctmp;
        else
          trcshiftshuf.rho(:,:,m,cnt) = trctmp.rho;
        end
      end
    else
      trcshiftshuf = [];
    end  
  end
  label = source_parc.label{parcel_indx};
  savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshift',scenario,parcel_indx));
     
  save(filename, 'label', 'shift_vals', 'trcshift', 'trcshiftshuf');
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
  
  tlck = mous_multisetcca_extractwords(comp, stimuli);
  
  %compare model with word embeddings to model with only constant
  design    = tlck.trialinfo(:,'w2v');
  stats.w2v = mous_multisetcca_regress(tlck, design,'lambda',1,'constant',1);

  design    = tlck.trialinfo(:,{'nchar','duration','loglexfreq','w2v'});
  stats.w2v_ortho = mous_multisetcca_regress(tlck, design,'lambda',1,'ortho',1:4,'constant',1);
  
  V = table2array(tlck.trialinfo(:,'w2v'));
  [u,s,v] = svd(V);
  tlck.trialinfo.w2v =  num2cell(V*v(:,1:20),2);  
  clear V
  
% FIXME:Can this happen outside the _regress or is it dependent on the trial
% selection?
%   for m = 1:size(tlck.trial,1)
%     tlck.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck.trial(m,:,:)),5);
%   end
  
  design    = tlck.trialinfo(:,1:11);
  stats.w2v_content = mous_multisetcca_regress(tlck, design, 'folds',5, 'lambda',1,'contentwords_only',1,'constant',1);
  
  
  nrand = 500;
  
  rng('default');
  for j = 1:nrand
    % mean subtracted duration is in column 3, this shuffles the words
    % maintaining the distribution in binned duration
    fprintf('performing randomization %d/%d\n',j,nrand);
    
    tmpdesign = design;
    
    r_idx = randperm(size(design,1));
    tmpdesign(:,4:end) = design(r_idx,4:end);
    tmpdesign.w2v(:,2:end) = design.w2v(r_idx,2:end);
    
    stats_rand(j) = mous_multisetcca_regress(tlck,tmpdesign, 'folds', 5,'lambda',1);
  end
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_models',scenario,parcel_indx,suffix));
  save(filename, 'ivar', 'X', 'V', 'words', 'stats', 'stats_rand');
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
  
  tlck = mous_multisetcca_extractwords(comp, stimuli);
  
  if ~exist('contentwords_only', 'var')
    contentwords_only = false;
  end
  [trc, tlck] = mous_multisetcca_trc(tlck, stimuli, 'dosmooth', 5, 'contentwords_only', contentwords_only);
  
  nrand = 1000;
  Cx = zeros(size(trc.rho,1),nrand,1);
  
  if ~exist('stratify_ivar', 'var')
    stratify_ivar = false;
  end
  
  if stratify_ivar
    if ~exist('covariates', 'var')
      covariates = {'nchar' 'duration' 'loglexfreq'};
      nbins      = [4 5 5];
    end
    bin = mous_multisetcca_stratifyivar(table2array(tlck.trialinfo(:,1:11)),tlck.trialinfo.Properties.VariableNames(1:11),covariates,nbins);  
  else
    bin = ones(size(tlck.trial,1),1);
    covariates = {''};
  end
  
  selaudio = find(contains(tlck.label, 'sub-2'));
  selvis   = find(contains(tlck.label, 'sub-1'));
   
  rng('default'); % ensure same 'random' behaviour for each parcel.
  for m = 1:nrand
    if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
    
    r_idx = (1:numel(bin))';
    ubin  = unique(bin);
    for mm = 1:numel(ubin)
      tmpB = r_idx(bin==ubin(mm));
      r_idx(bin==ubin(mm)) = tmpB(randperm(numel(tmpB)));
    end
    tmptlck = tlck;
    tmptlck.trial(:,selvis,:) = tmptlck.trial(r_idx,selvis,:);
    trcshuf(m) = mous_multisetcca_trc(tmptlck, stimuli);
  end
 
  rng('default'); % ensure same 'random' behaviour for each parcel
  for m = 1:nrand
    if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
    tmptlck = tlck;
    for mmv = 1:numel(selvis)
      r_idx = (1:numel(bin))';
      ubin  = unique(bin);
      for mm = 1:numel(ubin)
        tmpB = r_idx(bin==ubin(mm));
        r_idx(bin==ubin(mm)) = tmpB(randperm(numel(tmpB)));
      end
      tmptlck.trial(:,selvis(mmv),:) = tmptlck.trial(r_idx,selvis(mmv),:);
    end
    for mma = 1:numel(selaudio)
      r_idx = (1:numel(bin))';
      ubin  = unique(bin);
      for mm = 1:numel(ubin)
        tmpB = r_idx(bin==ubin(mm));
        r_idx(bin==ubin(mm)) = tmpB(randperm(numel(tmpB)));
      end
      tmptlck.trial(:,selaudio(mma),:) = tmptlck.trial(r_idx,selaudio(mma),:);
    end
    trcshuf2(m) = mous_multisetcca_trc(tmptlck, stimuli);
  end
  
  trcshuf(1).rho = cat(3,trcshuf.rho);
  trcshuf = trcshuf(1);
  
  trcshuf2(1).rho = cat(3,trcshuf2.rho);
  trcshuf2 = trcshuf2(1);
  
    
  suffix2 = '';
  if contentwords_only
    suffix2 = [suffix2 '_contentwords'];
  end
  if stratify_ivar
    suffix2 = [suffix2 '_stratified' '_' cat(2,covariates{:})];
  end
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_trc%s',scenario,parcel_indx,suffix,suffix2));
  save(filename, 'trcshuf', 'trcshuf2', 'trc');

end

%--------------------------------------------------------------------------
%This chunk of code is based on a full copy of the domscca_searchlight
%chunk, trimmed to get rid of unused stuff (e.g. lenient shuffling, and seq
%support, and extended to allow for a parcel pairwise trc computation. This
%is intended to explore, whether stimulus-set based characteristics lead to
%correlated responses in modality specific sensory areas.
if domscca_searchlight_pairwise
  suffix = ''; % the filenames don't have a suffix
  
  load mous_stimuli; 
  if ~exist('nfold', 'var'),          nfold          = 5;      end
  if ~exist('shuftype', 'var'),       shuftype       = 'none'; end
  if ~exist('skip_noshuffle', 'var'), skip_noshuffle = false;  end
  if ~exist('parcel_indx', 'var'),    error('a parcel index needs to be specified'); end
  if numel(parcel_indx)<2,            error('at least 2 parcel indices should be specified'); end
  if ~exist('nrand', 'var'),          nrand           = 100;   end
  if numel(nrand)==1,                 nrand           = 1:nrand; end
  shift   = zeros(1,numel(subj));
  stretch = ones(1,numel(subj));
  
  % this step does a mscca on specified parcels, and requires the
  % parcellation to have been computed. Also, it is a bit inefficient,
  % because it processes the data up until the level of a parcellated
  % representation, but that is for memory reasons
  nparc       = numel(parcel_indx);
  groupdata   = cell(nparc,numel(subj));
  subjectdata = cell(nparc,numel(subj));
  subjecttiming = cell(nparc,numel(subj));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s',suffix));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc%s',suffix));
    source_parc.filterlabel = filterlabel; % for checking channel order
    for m = 1:nparc
      subjectdata{m,k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx(m));
      if strncmp(subj{k}, 'sub-2', 5)
        % align the trials' time axes to the onset of the first word, rather
        % than the onset of the audio file
        tmp = subjectdata{m,k}.time;
        stim_id = subjectdata{m,k}.trialinfo(:,end);
        for kk = 1:numel(tmp)
          tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
          tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
        end
        subjectdata{m,k}.time = tmp;
      end
      for kk = 1:numel(subjectdata{m,k}.trial)
        tmp = subjectdata{m,k}.trial{kk};
        tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
        subjectdata{m,k}.trial{kk} = tmp;
      end
      mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',suffix));
      mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',suffix));
      subjecttiming{m,k} = timinginfo; % subject specific information about timing
      groupdata{m,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{m,k}, subjecttiming{m,k}, groupinfo, shift(k), stretch(k));
      
      cfg = [];
      cfg.method = 'acrosschannel';
      groupdata{m,k} = ft_channelnormalise(cfg, groupdata{m,k});
      for kk = 1:numel(groupdata{m,k}.trial)
        sel = nearest(groupdata{m,k}.time{kk},-0.1);
        groupdata{m,k}.trial{kk} = groupdata{m,k}.trial{kk}(:,sel:end);
        groupdata{m,k}.time{kk}  = groupdata{m,k}.time{kk}(sel:end);
      end
    end %for nparc
  end %for nsubj
  
  
  if ~skip_noshuffle
    for m = 1:nparc
      tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata(m,:), subj);
      rng('default'); % reset the number generator, in order to be able to compare across parcels
      [W, A, rho, C, comp{m}] = mous_multisetcca(tmpdata, nfold, 4, [],false);
      [comp{m}, rho]       = mous_multisetcca_postprocess(comp{m}, rho, source_parc.label{parcel_indx(m)});
    end
    % rename the labels, so that trc will be properly computed
    for m = 1:nparc
      plabel = strrep(source_parc.label{parcel_indx(m)},'_','');
      tok    = tokenize(comp{m}.label{1},'_');
      comp{m}.label = strrep(comp{m}.label, tok{1}, plabel);
    end
    trc = mous_multisetcca_trc(comp, stimuli);
    
    savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d', scenario);
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcelpair_%s_%s%s',scenario,trc.parcellabel{1},trc.parcellabel{2},suffix));
    %filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dpcoh',scenario,parcel_indx));
    save(filename, 'trc');
  end
  
  switch shuftype
    
    case 'conservative'
      tic;
      % unfold the audio data to maintain word onsets across modalities,
      % but after swapping sentences
            
      selaudio = find(strncmp(subj, 'sub-2', 5));
      selvis   = find(strncmp(subj, 'sub-1', 5));
      groupdatashuf = groupdata;
      
      cnt = 0;
      for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        paramdir = '/project/3011020.09/jansch/mscca_group/';
        load(fullfile(paramdir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,m,suffix))); % use precomputed ordering for consistency across parcels
        
        for mm = 1:size(groupdatashuf,1)
          groupdatashuf(mm,selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(mm,selaudio), subjecttiming(mm,selaudio), groupinfo, reorder, stimid, shift, stretch);
        end
        
        for k = 1:numel(groupdatashuf)
          for kk = 1:numel(groupdatashuf{k}.trial)
            sel = nearest(groupdatashuf{k}.time{kk},-0.1);
            groupdatashuf{k}.trial{kk} = groupdatashuf{k}.trial{kk}(:,sel:end);
            groupdatashuf{k}.time{kk}  = groupdatashuf{k}.time{kk}(sel:end);
          end
        end
        
        % perform the cca
        for mm = 1:size(groupdatashuf,1)
          rng('default'); % reset the number generator, in order to be able to compare across parcels (w.r.t. the folding)
          tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf(mm,:), subj);
          [Wshuf, Ashuf, rhoshuf, ~, compshuf{mm}] = mous_multisetcca(tmpdata, nfold, 4, [], false);
          [compshuf{mm}, rhoshuf]         = mous_multisetcca_postprocess(compshuf{mm}, rhoshuf, source_parc.label{parcel_indx(mm)});
        
          plabel = strrep(source_parc.label{parcel_indx(mm)},'_','');
          tok    = tokenize(compshuf{mm}.label{1},'_');
          compshuf{mm}.label = strrep(compshuf{mm}.label, tok{1}, plabel);
        end
        
        % compute trc
        trctmp                 = mous_multisetcca_trc(compshuf, stimuli);
         
        if cnt==1
          trcshuf = trctmp;
        else
          trcshuf.rho(:,:,:,:,cnt) = trctmp.rho;
        end
      end
      % NOTE TO SELF: ACROSS PARCELS, POLARITY IS AMBIGUOUS, SO ONLY THE
      % ABS(TRC) CAN BE COMPARED, OR SOME SVD TRICK NEEDS TO BE APPLIED
      savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcelpair_%s_%s_shuf%s',scenario,trc.parcellabel{1},trc.parcellabel{2},suffix));
    
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
      end
      save(filename,'trcshuf');
      toc
  end
  
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
if dotrc_pairwise
  load atlas_conte69_8196reg_LR_brodmann_subparc
  label = atlas.parcellationlabel;
  label([1 2 194 195]) = [];
  label = label(parcel_indx);
  
  % do time resolved correlation
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  suffix = ''; % for now
  loaddir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename1 = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx(1),suffix));
  filename2 = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx(2),suffix));
  
  tmp=load(filename1, 'comp');
  comp1 = tmp.comp;
  tmp=load(filename2, 'comp');
  comp2 = tmp.comp;
  
  tlck1 = mous_multisetcca_extractwords(comp1, stimuli);
  tlck2 = mous_multisetcca_extractwords(comp2, stimuli);
  
%   % identify the nouns, adjectives and verbs
%   sel =          double(strncmp([words.POS], 'N',   1))*1;
%   sel = sel + double(strncmp([words.POS], 'WW',  2))*2;
%   sel = sel + double(strncmp([words.POS], 'ADJ', 3))*3;
%   
%   % select these from the data
%   words.POS      = words.POS(sel>0);
%   words.duration = words.duration(sel>0);
%   words.word     = words.word(sel>0);
%     
%   cfg        = [];
%   cfg.trials = find(sel);
%   tlck        = ft_selectdata(cfg, tlck);
  tlck1_smooth = tlck1;
  tlck2_smooth = tlck2;
  for m = 1:size(tlck1.trial,1)
    tlck1_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck1.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
    tlck2_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck2.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
  end
  
  selaudio = find(contains(comp1.label, 'sub-2'));
  selvis   = find(contains(comp1.label, 'sub-1'));
  
  
  tmp1 = permute(tlck1_smooth.trial(:,4:end,:),[2 1 3]);
  tmp1_orig = tmp1;
  tmp1 = tmp1-nanmean(tmp1,2); % remove the average across trials
  
  tmp2 = permute(tlck2_smooth.trial(:,4:end,:),[2 1 3]);
  tmp2_orig = tmp2;
  tmp2 = tmp2-nanmean(tmp2,2); % remove the average across trials
  
  for k = 1:109
    tmpx1 = tmp1(:,:,k);
    tmpx2 = tmp2(:,:,k);
    tmpc = tmpx1*tmpx2';
    tmpc1 = tmpx1*tmpx1';
    tmpc2 = tmpx2*tmpx2';
    c(:,:,k) = tmpc./sqrt(diag(tmpc1)*diag(tmpc2)');
    
  end
  C(:,1,1) = squeeze(mean(mean(c(selvis,selvis,:))));
  C(:,2,2) = squeeze(mean(mean(c(selaudio,selaudio,:))));
  C(:,1,2) = squeeze(mean(mean(c(selvis,selaudio,:))));
  C(:,2,1) = squeeze(mean(mean(c(selaudio,selvis,:))));
  
  nrand = 1000;
  Cx = zeros(size(C,1),nrand,2,2);
  
  %Y = X1(:,2:4);
  Y = X1(:,[2 3 5]);
  Y(:,1) = Y(:,1)-min(Y(:,1));
  Y(:,2) = Y(:,2)-min(Y(:,2));
  Y(:,3) = Y(:,3)-min(Y(:,3));
  
  edges1 = eqpop(Y(:,1),4); %otherwise the 'lengthy word bin' ends up almost empty
  edges2 = eqpop(Y(:,2),5);
  edges3 = eqpop(Y(:,3),5); edges3 = [0.5:1:9.5 11.5 14.5];
  [n1,bin1] = histc(Y(:,1),edges1);
  [n2,bin2] = histc(Y(:,2), edges2);
  [n3,bin3] = histc(Y(:,3), edges3);
  
  
  rng('default'); % ensure same 'random' behaviour for each parcel.
  for m = 1:nrand
    if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
    bin3(:)=1;n3=[size(Y,1);0];
    %bin2(:) = 1;n2=[size(Y,1);0];
    %bin1(:) = 1;n1=[size(Y,1);0];
    
    % reorder, but obey a binning for nchar and duration, as per the second
    % and third columns of the X-matrix, now called Y
    r_idx1 = (1:numel(Y(:,1)))';
    r_idx2 = (1:numel(Y(:,1)))';
    for mm = 1:numel(n1)-1
      for mmm = 1:numel(n2)-1
        for mmmm = 1:numel(n3)-1
          tmpB = r_idx1(bin1==mm&bin2==mmm&bin3==mmmm);
          r_idx1(bin1==mm&bin2==mmm&bin3==mmmm)=tmpB(randperm(numel(tmpB)));
          tmpB = r_idx2(bin1==mm&bin2==mmm&bin3==mmmm);
          r_idx2(bin1==mm&bin2==mmm&bin3==mmmm)=tmpB(randperm(numel(tmpB)));
        end
      end
    end
%     r_idx1 = randperm(numel(Y(:,1)));
%     r_idx2 = randperm(numel(Y(:,1)));
%     
    tmp1b = tmp1;
    tmp2b = tmp2;
    tmp1b(:,:,:) = tmp1(:,r_idx1,:);
    tmp2b(:,:,:) = tmp2(:,r_idx2,:);
    for k = 1:109
      tmpx1 = tmp1b(:,:,k);
      tmpx2 = tmp2b(:,:,k);
      tmpc = tmpx1*tmpx2';
      tmpc1 = tmpx1*tmpx1';
      tmpc2 = tmpx2*tmpx2';
      c(:,:,k) = tmpc./sqrt(diag(tmpc1)*diag(tmpc2)');
    end
    Cx(:,m,1,1) = squeeze(mean(mean(c(selvis,selvis,:))));
    Cx(:,m,1,2) = squeeze(mean(mean(c(selvis,selaudio,:))));
    Cx(:,m,2,1) = squeeze(mean(mean(c(selaudio,selvis,:))));
    Cx(:,m,2,2) = squeeze(mean(mean(c(selaudio,selaudio,:))));
  end
  
  tim = tlck1.time;
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcelpair%03d_03d_trc',scenario,parcel_indx(1),parcel_indx(2)));
  save(filename, 'C', 'Cx', 'tim');

end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
if compare2simple
  suffix = '';
  load mous_stimuli; 
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
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, 0, 1);
  
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
    for kk = 1:numel(groupdata{1,k}.trial)
      sel = nearest(groupdata{1,k}.time{kk},-0.1);
      groupdata{1,k}.trial{kk} = groupdata{1,k}.trial{kk}(:,sel:end);
      groupdata{1,k}.time{kk}  = groupdata{1,k}.time{kk}(sel:end);
    end
  end
  
  data       = mous_multisetcca_groupdata2singlestruct(groupdata, subj);
  data.trial = cellrowselect(data.trial,1:5:numel(data.label));
  data.label = data.label(1:5:end);
  data.label(contains(data.label,'sub-2')) = strrep(data.label(contains(data.label,'sub-2')),'chan','cha2');
  
  %clear subjectdata groupdata
  
  loaddir  = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'comp');
  
  [srt,ix1] = sort(comp.trialinfo(:,end));
  [srt,ix2] = sort(data.trialinfo(:,end));
  comp.trial = comp.trial(ix1);
  comp.time  = comp.time(ix1);
  comp.trialinfo = comp.trialinfo(ix1,:);
  data.trial = data.trial(ix2);
  data.time  = data.time(ix2);
  data.trialinfo = data.trialinfo(ix2,:);
  
  cfg = [];
  comp = ft_channelnormalise(cfg, comp);
  data = ft_channelnormalise(cfg, data);
  
  %---compute covariance, and polarity align data with corresponding comp
  C = nancov(cellcat(1,comp.trial,data.trial),1,2,1);
  tmp = sign(diag(C,numel(data.label)));
  for k = 1:numel(tmp)
    data.trial = cellrowassign(data.trial, cellrowselect(data.trial,k).*tmp(k), k);
  end
  
  tlck1 = mous_multisetcca_extractwords(comp, stimuli);
  tlck2 = mous_multisetcca_extractwords(data, stimuli);

  tlck1_smooth = tlck1;
  tlck2_smooth = tlck2;
  for m = 1:size(tlck1.trial,1)
    tlck1_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck1.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
    tlck2_smooth.trial(m,:,:) = ft_preproc_smooth(squeeze(tlck2.trial(m,:,:)),5); % use a smoothing kernel of odd number of samples
  end
  
  selaudio = find(contains(comp.label, 'sub-2'));
  selvis   = find(contains(comp.label, 'sub-1'));
  
  
  tmp1 = permute(tlck1_smooth.trial(:,4:end,:),[2 1 3]);
  tmp1 = tmp1-nanmean(tmp1,2); % remove the average across trials
  tmp2 = permute(tlck2_smooth.trial(:,4:end,:),[2 1 3]);
  tmp2 = tmp2-nanmean(tmp2,2); % remove the average across trials
  
  for k = 1:109
    tmpx = tmp1(:,:,k);
    tmpc = tmpx*tmpx';
    c1(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
    tmpx = tmp2(:,:,k);
    tmpc = tmpx*tmpx';
    c2(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
  end
  
  C1(:,1) = squeeze(mean(mean(c1(selvis,selvis,:))))-1./numel(selvis);
  C1(:,2) = squeeze(mean(mean(c1(selaudio,selaudio,:))))-1./numel(selaudio);
  C1(:,3)  = squeeze(mean(mean(c1(selvis,selaudio,:))));
  C2(:,1) = squeeze(mean(mean(c2(selvis,selvis,:))))-1./numel(selvis);
  C2(:,2) = squeeze(mean(mean(c2(selaudio,selaudio,:))))-1./numel(selaudio);
  C2(:,3)  = squeeze(mean(mean(c2(selvis,selaudio,:))));

  rng('default'); % ensure same 'random' behaviour for each parcel.
  for m = 1:nrand
    if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
    
    % reorder, but obey a binning for nchar and duration, as per the second
    % and third columns of the X-matrix, now called Y
    r_idx = randperm(size(X,1));
    
    tmp1b = tmp1;
    tmp2b = tmp2;
    tmp1b(selvis,:,:) = tmp1(selvis,r_idx,:);
    tmp2b(selvis,:,:) = tmp2(selvis,r_idx,:);
    
    for k = 1:109
      tmpx = tmp1b(:,:,k);
      tmpc = tmpx*tmpx';
      c1(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
      tmpx = tmp2b(:,:,k);
      tmpc = tmpx*tmpx';
      c2(:,:,k) = tmpc./sqrt(diag(tmpc)*diag(tmpc)');
    end
    
    Cx1(:,m,1) = squeeze(mean(mean(c1(selvis,selaudio,:))));
    Cx2(:,m,1) = squeeze(mean(mean(c2(selvis,selaudio,:))));
    if m==1
      Cx1(:,nrand) = 0;
      Cx2(:,nrand) = 0;
    end
  end
  tim = tlck1.time;
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d_parcel%03d%s_comparison',scenario,parcel_indx,suffix));
  save(filename, 'C1', 'Cx1', 'C2', 'Cx2', 'tim');
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
if do_clusterstats
    if ~exist('scenario', 'var')
      error('scenario number needs to be defined');
    end
    
    datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
    
    [s T Tshuf] = mous_multisetcca_stats(datadir,scenario,'modality','visual');
    save(fullfile(datadir, sprintf('scenario%d_results',scenario)),'s','T','Tshuf');
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
if do_plotting
    if ~exist('scenario', 'var')
      error('scenario number needs to be defined');
    end
cluster = 2;
%load atlas, sourcemodel and colormap
load atlas_conte69_8196reg_LR_brodmann_subparc.mat 
load ~/MOUS/meg/templates/cortex_midthickness_8196reg.mat
cmap = brewermap(63,'Reds');
%load data
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
outdir = sprintf('/project/3011020.09/jansch/mscca_group/figures')
load(fullfile(datadir, sprintf('scenario%d_results',scenario)))

%create source structure for plotting
source                = [];
source.brainordinate  = atlas;
source.label          = atlas.parcellationlabel;
source.time           = s.time;
source.dimord         = 'chan_time';
source.pow            = (T-mean(Tshuf,3));
source.mask           = double(s.posclusterslabelmat==cluster);

%plot both hemispheres simultaneously
pos = sourcemodel.pos;
%pos = pos(:,[2 1 3]);
n = 4098;
pos(1:n,2) = pos(1:n,2)+210;
pos(1:n,1:2) = -pos(1:n,1:2);
source.brainordinate.pos = pos;

cfgp                  = [];
cfgp.funparameter     = 'pow';
cfgp.maskparameter    = 'mask';
cfgp.funcolormap      = cmap;
%ft_sourcemovie(cfgp, source);

xs = source;
xs = ft_checkdata(xs,'datatype','source');


%find where first cluster begins and plot from there to end
[~, firstcol] = find(s.posclusterslabelmat==cluster,1);
[~, lastcol] = find(s.posclusterslabelmat==cluster,1,'last');

splot = xs;
figure('position',[1 1 900 900]);
for k = firstcol:4:lastcol
  splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
  splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
  ft_plot_mesh(splot,'edgecolor','none','vertexcolor',splot.pow,'facealpha', splot.mask, 'clim', [0 0.015], 'alphalim', [0 0.005], 'alphamap', 'rampup', 'colormap', cmap, 'maskstyle', 'colormix');lighting gouraud;material dull;view([90 0]);h=light('position',[10 0 0]);
  set(gcf,'color','w');
  title(sprintf('time = %d',round(1000.*s.time(k))),'position',[33 -104 100]);
  fname = strcat(outdir,sprintf('/crossmod_sce%d_timestamp%03d_trc_masked_cluster%d',scenario,k,cluster));
  export_fig(fname,'-png');
  clf;
end

%%get colorbar
% cd /home/language/sopara/Matlab/fieldtrip/plotting/private
% rgb=bg_rgba2rgb([199 194 169]/255,linspace(0,0.015,30),cmap,[0 0.015],[linspace(0,1,10) ones(1,20)],'rampup',[0 1]);;
% figure;image(rgb);
% set(gca,'tickdir','out');
% set(gca,'xticklabel',(1:6).*(0.015./6));
% cd /project/3011020.09/jansch/mscca_group/figures;
% export_fig('colorbar_crossmod','-eps');
end
