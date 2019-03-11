% the first version of this script has been copied over from mous_multisetcca_pipeline, with most of the
% original contents stripped. All necessary preprocessing steps are assumed
% to have been run using mous_multisetcca_pipeline

if ~exist('rootdir',                      'var'), rootdir                   = '/project/3011020.09';       end
if ~exist('domscca_searchlight_cross',    'var'), domscca_searchlight_cross = false;      end
if ~exist('makemodels',                   'var'), makemodels                = false;      end

if ~exist('subjectname', 'var') && ~exist('scenario', 'var')
  error('at least a subjectname or a scenario number needs to be defined');
end

if exist('scenario', 'var')
  subj = mous_db_getfilename('allAV', 'subjectname');
  sce  = mous_db_getfilename(subj,    'scenario');
  sel  = false(numel(subj,1));
  for m = 1:numel(scenario)
    sel = strncmp(sce, num2str(scenario(m)), 1) | sel;
  end
  subj = subj(sel);
  sce  = sce(sel);
end

%--------------------------------------------------------------------------
%The following chunk of code does a 'searchlight' based multisetcca, where
%the searchlight is defined as the 5-component timecourse, describing a
%parcel, indicated with parcel_indx. It uses the same initialization of the
%random number generator, thus allowing identical folding across parcels,
%that can therefore be meaningfully compared post-hoc. It combines across
%paired scenarios the visual subjects, and reorders word lists such that
%the exact words match between sce 1-4/2-5/3-6. It uses hyperalignment,
%i.e. time shifting of the data prior to fitting the components
if domscca_searchlight_cross
  if ~(all(isequal(scenario,[1 4]))||all(isequal(scenario,[2 5]))||all(isequal(scenario,[3 6])))
    error('wrong combination of scenarii');
  end
  sce  = sce(contains(subj,'V'));
  subj = subj(contains(subj,'V'));
  
  load mous_stimuli;
  
  if ~exist('nfold', 'var'),          nfold          = 5;       end
  if ~exist('shuftype', 'var'),       shuftype       = 'none';  end
  if ~exist('skip_noshuffle', 'var'), skip_noshuffle = false;   end
  if ~exist('parcel_indx', 'var'),    error('a parcel index needs to be specified');  end
  if ~exist('nrand', 'var'),          nrand          = 100;     end
  if numel(nrand)==1,                 nrand          = 1:nrand; end % nrand is expected to be a vector of indices that point to a indexed file that contains the precomputed shuffle (to ensure same shuffling across parcels)
  
  groupdata     = cell(1,numel(subj));
  subjectdata   = cell(1,numel(subj));
  subjecttiming = cell(1,numel(subj));
  for k = 1:numel(subj)
    
    % load in the data
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc_combined'));
    source_parc.filterlabel = filterlabel; % for checking channel order
  
    sent   = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data'));
    sent_T = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo'));
    info   = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo'));
    seq   = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data_seq'));
    seq_T = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo_seq'));
    info_seq = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo_seq'));
    
    nsent = numel(sent.trial); % needed later on 
    if ~isequal(seq.label,sent.label)
      [a,b]  = match_str(seq.label, sent.label);
      tmpcfg1 = [];
      tmpcfg  = [];
      tmpcfg1.channel = sent.label(b);
      tmpcfg.channel  = seq.label(a);
      data = ft_appenddata([], ft_selectdata(tmpcfg1,sent), ft_selectdata(tmpcfg,seq)); clear sent seq;
    else
      data = ft_appenddata([],sent,seq); clear sent seq;
    end
    
    % combine the groupinfo structures, this requires info to be pruned
    % (for some subjects the info_seq will not contain the audio subjects)
    info.subj     = strrep(info.subj,'sub-1','V1');
    info.subj     = strrep(info.subj,'sub-2','A2');
    info_seq.subj = strrep(info_seq.subj,'sub-1','V1');
    info_seq.subj = strrep(info_seq.subj,'sub-2','A2');
    
    [sel1,sel2] = match_str(info_seq.subj,info.subj);
    sel1 = sel1(contains(info_seq.subj(sel1),'V'));
    sel2 = sel2(contains(info.subj(sel2),'V'));
    
    info.sel = info.sel(:,sel2);
    info.nsmp = info.nsmp(:,sel2);
    info.begtim = info.begtim(:,sel2);
    info.endtim = info.endtim(:,sel2);
    info.subj   = info.subj(sel2);
    info_seq.sel = info_seq.sel(:,sel1);
    info_seq.nsmp = info_seq.nsmp(:,sel1);
    info_seq.begtim = info_seq.begtim(:,sel1);
    info_seq.endtim = info_seq.endtim(:,sel1);
    info_seq.subj   = info_seq.subj(sel1);
    
    groupinfo{k} = info;
    groupinfo{k}.trialid  = cat(1,groupinfo{k}.trialid, info_seq.trialid);
    groupinfo{k}.ntrl     = size(groupinfo{k}.trialid,1);
    groupinfo{k}.sel      = cat(1,groupinfo{k}.sel, info_seq.sel);
    groupinfo{k}.nsmp     = cat(1,groupinfo{k}.nsmp, info_seq.nsmp);
    groupinfo{k}.begtim   = cat(1,groupinfo{k}.begtim, info_seq.begtim);
    groupinfo{k}.endtim   = cat(1,groupinfo{k}.endtim, info_seq.endtim);
    groupinfo{k}.maxnsmp  = cat(1,groupinfo{k}.maxnsmp, info_seq.maxnsmp);
    groupinfo{k}.mintim   = cat(1,groupinfo{k}.mintim, info_seq.mintim);
    groupinfo{k}.maxtim   = cat(1,groupinfo{k}.maxtim, info_seq.maxtim);
    groupinfo{k}.stiminfo = cat(2,groupinfo{k}.stiminfo, info_seq.stiminfo);
    
    % also append the timinginfo
    timinginfo = sent_T;
    timinginfo.trials  = cat(1,timinginfo.trials,seq_T.trials+nsent);
    timinginfo.smpin   = cat(1,timinginfo.smpin, seq_T.smpin);
    timinginfo.smpout  = cat(1,timinginfo.smpout, seq_T.smpout);
    timinginfo.time    = cat(2,timinginfo.time, seq_T.time);
    timinginfo.trialinfo = cat(1,timinginfo.trialinfo, seq_T.trialinfo);
    
    % update the trialinfo
    data.trialinfo(data.trialinfo(:,end)>500,end) = data.trialinfo(data.trialinfo(:,end)>500,end)-500;
    
    % convert the sensor-level data into  parcel-level data, for the
    % requested
    subjectdata{k}   = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    subjecttiming{k} = timinginfo; % subject specific information about timing
    
    for kk = 1:numel(subjectdata{k}.trial)
      tmp = subjectdata{k}.trial{kk};
      tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
      subjectdata{k}.trial{kk} = tmp;
    end  
  end
  
  % at this point the goupinfo contains scenario specific timing
  % indications, which (at least w.r.t. to the trial length) may cause
  % problems later on. Also, the remapping of individual words needs to be
  % done, and requires the information about the other scenario
  subjecttiming_orig = subjecttiming;
  groupinfo_orig     = groupinfo;
  [subjecttiming, groupinfo] = mous_multisetcca_timinginfo_seq2sent(subjecttiming, groupinfo, stimuli, sce)
  
  for k = 1:numel(subj)
    % align the subject-specific parcel data to match all others subjects
    % in terms of timing and trial-order
    groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo{k});%,true);
    
    lags = -6:6;
    groupdata{k}.trial = cellshift(groupdata{k}.trial, lags, 2, [], 'overlap');
    groupdata{k}.time  = cellshift(groupdata{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    norig = numel(groupdata{k}.label);
    groupdata{k}.label = repmat(groupdata{k}.label,numel(lags),1);
    
    for kk = 1:numel(lags)
      for m = 1:norig
        groupdata{k}.label{(kk-1)*norig+m} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*norig+m}, kk);
      end
    end
  end
  
  for k = 1:numel(subj)
    
    
    
    
%     %FIXME: THERE'S A STRANGE MISMATCH IN THE LENGTH OF THE TIME AXES AND
%     %THE LENGTH OF THE TRIALS, WHICH I DON'T UNDERSTAND, YET. FOR NOW,
%     %ADJUST MANUALLY, BECAUSE I HAVE NO REASON TO SUSPECT THE TIME AXIS TO
%     %BE WRONG, ONLY THE AMOUNT OF DATA POINTS TO BE OFF AS A CONSEQUENCE OF
%     %THE REMAPPING PROCEDURE
%     for m = 1:numel(groupdata{k}.trial)
%       groupdata{k}.trial{m} = groupdata{k}.trial{m}(:,1:numel(groupdata{k}.time{m}));
%     end
%   =================== THIS SEEMS FIXED NOW ======================

    cfg            = [];
    cfg.method     = 'acrosschannel';
    groupdata{1,k} = ft_channelnormalise(cfg, groupdata{k});
    for kk = 1:numel(groupdata{1,k}.trial)
      sel = nearest(groupdata{1,k}.time{kk},-0.1);
      groupdata{1,k}.trial{kk} = groupdata{1,k}.trial{kk}(:,sel:end);
      groupdata{1,k}.time{kk}  = groupdata{1,k}.time{kk}(sel:end);
    end
  end % for k of subj
  
  % at this point the groupdata is aligned for subjects with the same
  % scenario, but the number of trials may mismatch across scenarii, and
  % the order of the trials will be blockwise (condition) swapped. The
  % following section adjusts this order, but also artificially updates the
  % trialid of the second block of trials of the first scenario to reflect
  % a 'word list'. This is needed to later on exploit the stratification
  % option in the mscca step, which can stratify for the number of sent/list
  % trials in the test data.
  cnt1 = 0;
  cnt2 = 0;
  list1 = [];
  list2 = [];
  for k = 1:numel(subj)
    
    switch str2num(sce{k})
      case scenario(1)
        cnt1 = cnt1+1;
        list1(:,cnt1) = groupdata{k}.trialinfo(:,end);
      case scenario(2)
        cnt2 = cnt2+1;
        list2(:,cnt2) = groupdata{k}.trialinfo(:,end);
    end
  end
  assert(isequal(list1(:,ones(1,size(list1,2))),list1));
  assert(isequal(list2(:,ones(1,size(list2,2))),list2));
  [ix,i1,i2] = intersect(list1(:,1),list2(:,1));
  
  for k = 1:numel(subj)
    switch str2num(sce{k})
      case scenario(1)
        ix  = i1;
        tmp = groupdata{k}.trialinfo(:,end);
        sel = (find(diff(tmp)<0)+1):size(tmp,1);
      case scenario(2)
        ix  = i2;
        tmp = groupdata{k}.trialinfo(:,end);
        sel = 1:find(diff(tmp)<0);
    end
    groupdata{k}.trialinfo(sel,end) = groupdata{k}.trialinfo(sel,end)+500;
    
    groupdata{k}.trial = groupdata{k}.trial(ix);
    groupdata{k}.time  = groupdata{k}.time(ix);
    groupdata{k}.trialinfo = groupdata{k}.trialinfo(ix,:);
  end
   
  
  rng('default'); % reset the number generator, in order to be able to compare across parcels
  if ~skip_noshuffle
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj); % first row only
    [W, A, rho, C, comp, testfold] = mous_multisetcca(tmpdata, nfold, 4, 0.1,false, true);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    
    % rename the labels to create a pseudo-auditory condition, otherwise
    % the trc-function fails.
    subs1 = find(contains(sce, num2str(scenario(1))));
    subs2 = find(contains(sce, num2str(scenario(2))));
    
    comp.label(subs2) = strrep(comp.label(subs2),'V1','A2');
    comp.trialinfo(comp.trialinfo(:,end)>500,end) = comp.trialinfo(comp.trialinfo(:,end)>500,end)-500;
    
    set1 = groupinfo_orig{subs1(1)}.trialid;
    set2 = groupinfo_orig{subs2(1)}.trialid;
    
    set1 = set1(set1<500);
    set2 = set2(set2<500);
    
    tmpcfg = [];
    tmpcfg.trials = find(ismember(comp.trialinfo(:,end), set1));
    tlck1 = mous_multisetcca_extractwords(ft_selectdata(tmpcfg, comp), stimuli);
    trc1  = mous_multisetcca_trc(tlck1, stimuli, 'output', 'Z', 'output2', 'single_all');
    tmpcfg.trials = find(ismember(comp.trialinfo(:,end), set2)); 
    tlck2 = mous_multisetcca_extractwords(ft_selectdata(tmpcfg, comp), stimuli);
    trc2  = mous_multisetcca_trc(tlck2, stimuli, 'output', 'Z', 'output2', 'single_all');
    
    comp  = ft_struct2single(comp);
    tlck1 = ft_struct2single(tlck1); % contains the set of words corresponding to 'sentences' in the first scenario
    tlck2 = ft_struct2single(tlck2); % contains the set of words corresponding to 'sentences' in the second sceanario
    
    savedir = sprintf('/project/3011020.09/jansch/mscca_2sce/scenario%d_%d', scenario(1), scenario(2));
    system(sprintf('mkdir -p %s', savedir));
    
    filename = fullfile(savedir, sprintf('mscca_sce%d-%d_parcel%03d',scenario(1),scenario(2),parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'tlck1', 'tlck2', 'trc1', 'trc2');
  end
  
  switch shuftype
    case 'lenient'
      % lenient shuffling, that maintins the timing within sensory
      % modality, but does not obey individual word onsets across
      % modalities
      %FIXME: not updated vor joint mscca over conditions yet
      if strcmp(suffix2,'_combined')
        warning('lenient shuffling is not working yet for combined mscca')
      end
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
      
      selaudio = find(strncmp(subj, 'A', 1) | contains(subj, 'sub-2'));
      selvis   = find(strncmp(subj, 'V', 1) | contains(subj, 'sub-1'));
      groupdatashuf = groupdata;
      
      cnt = 0;
      Cshufstim = zeros(81,2,numel(nrand));
      Cshuf     = zeros(81,3,numel(nrand));
      for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        paramdir = '/project/3011020.09/jansch/mscca_group/';
        
        for i = 1:numel(suffix)
          load(fullfile(paramdir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,m,suffix{i}))); % use precomputed ordering for consistency across parcels
          
          groupdatashuf(i,selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(i,selaudio), subjecttiming(i,selaudio), groupinfo{i}, reorder, stimid, shift, stretch);
        end
        %recombine the separately shuffled matrices
        if size(groupdatashuf,1)>1
          cfg = [];
          fsample = groupdatashuf{1}.fsample;
          for k = selaudio'
            groupdatashuf{1,k} = ft_appenddata(cfg,groupdatashuf{1,k},groupdatashuf{2,k});
            groupdatashuf{1,k}.fsample = fsample;
            groupdatashuf{2,k} = [];
          end
          groupdatashuf = groupdatashuf(~cellfun('isempty',groupdatashuf))';
        end
        
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
        for i = 1:length(suffix)
          if strcmp(suffix{i},'')
            cfg = [];
            cfg.trials = compshuf.trialinfo(:,end)<=500;
            compshufsel = ft_selectdata(cfg,compshuf);
          elseif strcmp(suffix{i},'_seq')
            cfg = [];
            cfg.trials = compshuf.trialinfo(:,end)>500;
            compshufsel = ft_selectdata(cfg,compshuf);
          end
          trctmp = mous_multisetcca_trc(compshufsel, stimuli);
          if cnt==1
            trcshuf(i) = trctmp;
          else
            trcshuf(i).rho(:,:,cnt) = trctmp.rho;
          end
        end
        Rshuf(1,1,cnt)         = single(mean(mean(rhoshuf(selvis,selvis,1))))-1./numel(selvis);
        Rshuf(1,2,cnt)         = single(mean(mean(rhoshuf(selvis,selaudio,1))));
        Rshuf(2,1,cnt)         = single(mean(mean(rhoshuf(selaudio,selvis,1))));
        Rshuf(2,2,cnt)         = single(mean(mean(rhoshuf(selaudio,selaudio,1))))-1./numel(selaudio);
        
        tmpCshuf       = cohshuf.cohspctrm;
        Cshuf(:,1,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
        Cshuf(:,2,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
        Cshuf(:,3,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
        
        tmpCshufstim       = cohshufstim.cohspctrm;
        Cshufstim(:,1,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
        Cshufstim(:,2,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
      end
      
      
      foi   = cohshuf(1).freq;
      savedir = sprintf('/project/3011020.09/jansch/mscca_2sce/scenario%d',scenario);
      for i = 1:length(suffix)
        trcshuf = trcshuf(i);
        filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf2%s%s',scenario,parcel_indx,suffix2,suffix{i}));
        if exist([filename,'.mat'], 'file')
          tmp = load(filename);
          Cshuf = cat(3,tmp.Cshuf,Cshuf);
          Rshuf = cat(3,tmp.Rshuf,Rshuf);
          Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
          trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
          if isfield(tmp, 'nrand')
            nrand = cat(1,tmp.nrand(:),nrand(:));
          else
            nrand = cat(1,nan*ones(size(tmp.Cshuf,3),1),nrand(:));
          end
        end
        trcshuf = ft_struct2single(trcshuf);
        save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim','trcshuf', 'nrand');
      end
  end
end
%--------------------------------------------------------------------------

if makemodels2
  
  if ~exist('nrand', 'var')
    nrand = 500;
  end
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  if ~exist('lambda', 'var')
    lambda=1;
  end
  
  use_ivars = {'constant' 'nchar' 'loglexfreq' 'index' 'logperplexity' 'entropy' ...
                  'leftbranch' 'dleftbranch' 'main'};
  if ~exist('test_ivars', 'var')
    % test a bunch at once: this does not allow for ivar specific lambdas
    %test_ivars = {'nchar' 'loglexfreq' 'index' 'logperplexity' 'entropy' ...
    %              'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'w2v'};
    test_ivars = {'constant' 'nchar' 'loglexfreq' 'index' 'logperplexity' 'entropy' ...
                  'leftbranch' 'dleftbranch'};
  end
  if ~iscell(test_ivars)
    test_ivars = {test_ivars};
  end
  
  suffix = ''; % for now
  loaddir = sprintf('/project/3011020.09/jansch/mscca_2sce/scenario%d_%d',scenario(1),scenario(2));
  
  filename = fullfile(loaddir, sprintf('mscca_sce%d-%d_parcel%03d%s',scenario(1),scenario(2),parcel_indx,suffix));
  load(filename, 'tlck1', 'tlck2');
  
  % select only content words
  sel =       double(strncmp([tlck1.trialinfo.POS], 'N',   1))*1;
  sel = sel + double(strncmp([tlck1.trialinfo.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([tlck1.trialinfo.POS], 'ADJ', 3))*3;
  
  % select these from the data
  tmpcfg = [];
  tmpcfg.trials = find(sel>0);
  tmpcfg.channel = tlck1.label(4:end);
  tmpcfg.latency = [-inf 0.6];
  tlck1  = ft_selectdata(tmpcfg, tlck1);
  
  sel =       double(strncmp([tlck2.trialinfo.POS], 'N',   1))*1;
  sel = sel + double(strncmp([tlck2.trialinfo.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([tlck2.trialinfo.POS], 'ADJ', 3))*3;
  
  % select these from the data
  tmpcfg = [];
  tmpcfg.trials = find(sel>0);
  tmpcfg.channel = tlck2.label(4:end);
  tmpcfg.latency = [-0 0.6];
  tlck2  = ft_selectdata(tmpcfg, tlck2);
  n1 = size(tlck1.trial,1);
  n2 = size(tlck2.trial,1);
  
  % add constant regressor to the design, and 'main effect of sent/list'
  tlck1.trialinfo = cat(2, array2table(ones(n1,1),'VariableNames', {'constant'}), tlck1.trialinfo, array2table( ones(n1,1), 'VariableNames', {'main'}));
  tlck2.trialinfo = cat(2, array2table(ones(n2,1),'VariableNames', {'constant'}), tlck2.trialinfo, array2table(-ones(n2,1), 'VariableNames', {'main'}));
  
  % before appending, ensure that the discrete regressors are discrete
  % (i.e. remove the mean removal)
  
  adjust_ivars = {'nchar' 'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'index'};
  for k = 1:numel(adjust_ivars)
    try
      tmp = tlck1.trialinfo.(adjust_ivars{k});
      tmp = round(tmp-min(tmp));
      tlck1.trialinfo.(adjust_ivars{k}) = tmp;
    end
    try
      tmp = tlck2.trialinfo.(adjust_ivars{k});
      tmp = round(tmp-min(tmp));
      tlck2.trialinfo.(adjust_ivars{k}) = tmp;
    end  
  end
  
      
  cfg = [];
  cfg.appenddim = 'rpt';
  cfg.parameter = 'trial';
  tlck = ft_appendtimelock(cfg, tlck1, tlck2);
  clear tlck1 tlck2;
  
  ivar = tlck.trialinfo.Properties.VariableNames;
  sel_ivars = match_str(ivar, use_ivars);
  
  % here the design contains all independent variables of interest,
  % demean apart from the constant
  design = tlck.trialinfo(:,sel_ivars);
  for m = sel_ivars(:)'
    if ~strcmp(ivar{m},'constant')
      design.(ivar{m}) = design.(ivar{m}) - nanmean(design.(ivar{m}));
    end
  end
  
  ivar        = ivar(sel_ivars);
  categorical = ismember(ivar, {'nchar' 'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'index' 'main'});
    
    for m = 1:numel(test_ivars)
      indx = find(ismember(ivar, test_ivars{m}));
      
      fprintf('modelling the data with %s\n',ivar{indx});
      
      stat   = mous_multisetcca_regress(tlck, design(:,[setdiff(1:size(design,2),indx) indx]),'lambda',lambda, 'outerfolds', 5, 'balancefolds', categorical(indx), 'normalise', true, 'modelcomparison', ivar(setdiff(1:size(design,2),indx)), 'innerfolds', 5, 'nrepeat', 5);
      
      rng('default');
      p = zeros(size(stat.Rsq));
      Frand  = zeros([size(stat.Rsq) nrand]);
      for k = 1:nrand
        if mod(k,10)==0, fprintf('performing randomization %d/%d\n',k,nrand); end
        tmpdesign = design;
        
        randvec = randperm(size(design,1));
        vars    = design.Properties.VariableNames;
        for j = 1:numel(vars)
          %if strcmp(vars{j},ivar{indx}) % commenting this out causes the
          %whole design to be randomised, not commenting this out causes
          %only the ivar of interest to be randomized
            tmpX = tmpdesign.(vars{j});
            tmpX = tmpX(randvec,:);
            tmpdesign.(vars{j}) = tmpX;
          %end
        end
        
        tmp = mous_multisetcca_regress(tlck, tmpdesign(:,[setdiff(1:size(design,2),indx) indx]),'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', ivar(setdiff(1:size(design,2),indx)), 'innerfolds', 5, 'nrepeat', 5);
        p   = p  + double(tmp.Rsq  > stat.Rsq );
        
        Frand(:,:,k)  = tmp.Rsq;
      end
      S(mm).stat  = stat;
      S(mm).p     = (p)./nrand; % uncorrected p-value of the permutations
      S(mm).ivar  = ivar{indx};
      S(mm).ref   = nanmean(Frand,3);
      S(mm).perms = Frand;
    end
  
  for mm = 1:numel(S)
    if mm==1
      obs = S(mm).stat.Rsq;
      perms = S(mm).perms;
    else
      obs = cat(1,obs,S(mm).stat.Rsq);
      perms = cat(1,perms,S(mm).perms);
    end
  end
  
  a = cat(3,obs',permute(perms,[2 1 3]));
  rng('default');
  [results, params] = prevalenceCore(a);
  
  if numel(S)>1
    for mm = 2:numel(S)
      S(1).p = cat(1,S(1).p,S(mm).p);
      S(1).ref = cat(1,S(1).ref,S(mm).ref);
      S(1).stat.Rsq = cat(1,S(1).stat.Rsq,S(mm).stat.Rsq);
      %S(1).stat.B   = cat(2,S(1).stat.B,S(mm).stat.B);
      %S(1).stat.B0  = cat(2,S(1).stat.B0,S(mm).stat.B0);
      S(1).stat.lambda = cat(1,S(1).stat.lambda,S(mm).stat.lambda);
    end
  end
  S = rmfield(S(1), 'perms');
  
  
  S.prevalence.results = results;
  S.prevalence.params  = params;
  if numel(scenario)==1
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s_model2_%s',scenario,parcel_indx,suffix,ivar{indx}));
  else
    str = '';
    for mm = 1:numel(scenario)
      str = [str num2str(scenario(mm))];
    end
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%s_parcel%03d%s_model2_%s',str,parcel_indx,suffix,ivar{indx}));
  end
  save(filename, 'S');
  
end



