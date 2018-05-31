% This pipeline estimates the hyperalignment between subjects, inspired by
% Jim Haxby's approach. Rather than his recommended algorithm that is based
% on Procrustes transformations, we will do a multiset CCA. Hence this
% script is based on the mous_multisetcca_pipeline, and in order for the
% pipeline to run, it is assumed that the necessary analysis steps from the
% multiset pipeline have been executed. The difference with the multisetcca
% pipeline is the fact that we start out with the visual-only subjects, and
% use time shifting, to increase the number of features per subject, which
% simultaneously allows for accommodating for differences in kernel
% morphology (whatever that means) across subjects.

if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/MEG/';  end
if ~exist('computedata',      'var'), computedata      = false;                       end
if ~exist('computedata_seq',  'var'), computedata_seq  = false;                       end
if ~exist('cleandata',        'var'), cleandata        = false;                       end
if ~exist('cleandata_seq',    'var'), cleandata_seq    = false;                       end
if ~exist('dolcmv',           'var'), dolcmv           = false;                       end
if ~exist('dolcmv_seq',       'var'), dolcmv_seq       = false;                       end
if ~exist('computealignment', 'var'), computealignment = false;                       end
if ~exist('computealignment_seq', 'var'), computealignment_seq = false;       end
if ~exist('dohyperalignment',     'var'), dohyperalignment     = false;       end
if ~exist('dohyperalignment_seq', 'var'), dohyperalignment_seq = false;       end
if ~exist('create_shuffle_indx', 'var'), create_shuffle_indx = false; end
if ~exist('create_shuffle_indx_seq', 'var'), create_shuffle_indx_seq = false; end
if ~exist('makemodels', 'var'), makemodels = false; end

if ~exist('subjectname', 'var') && ~exist('scenario', 'var') && ~exist('subj', 'var')
  error('at least a subjectname, a scenario number, or a list of subjects needs to be defined');
end

if exist('scenario', 'var')
  subj = mous_db_getfilename('allAV', 'subjectname');
  sce  = mous_db_getfilename(subj,    'scenario');
  sel  = strncmp(sce, num2str(scenario), 1);
  subj = subj(sel);
  sce  = sce(sel);
  
  selvis   = find(strncmp(subj, 'sub-1', 5));
  subj     = subj(selvis);
end

if ~exist('savedir', 'var')
  savedir = '/project/3011020.09/jansch/hyperalignment';
end

if computedata
  % this step has been performed in mous_multisetcca_pipeline, and resulted 
  % in a data object that can be obtained with:
  %
  % mous_db_getdata(subjectname, 'meg_multisetcca_data', 'data', rootdir);
end

if computedata_seq
  %data = mous_erf_sentences(subjectname, 2);
  %mous_db_putdata(subjectname, 'meg_multisetcca_data_seq', 'data', rootdir);
end

if cleandata
  % done in mous_multisetcca_pipeline
end

if cleandata_seq
%   for k = 1:numel(subj)
%     mous_db_getdata(subj{k}, 'meg_multisetcca_data_seq');
%     cfg = [];
%     cfg.method = 'summary';
%     cfg.keeptrial = 'nan';
%     cfg.channel = 'MEG';
%     data = ft_rejectvisual(cfg, data);
%     mous_db_putdata(subj{k}, 'meg_multisetcca_data_seq', 'data');
%   end
end
  
if dolcmv
  % this step has been performed in mous_multisetcca_pipeline, and resulted 
  % in a data object that can be obtained with:
  %
  % mous_db_getdata(subjectname, 'meg_multisetcca_lcmv_parc', 'source_parc', 'filterlabel', rootdir);
end

if dolcmv_seq
%   mous_db_getdata(subjectname, 'meg_multisetcca_data_seq');
%   [source_parc, filterlabel] = mous_multisetcca_lcmv(subjectname, data);
%   mous_db_putdata(subjectname, 'meg_multisetcca_lcmv_parc_seq', 'source_parc', 'filterlabel', rootdir);
end

if computealignment || computealignment_seq
  % this step has been performed in mous_multisetcca_pipeline, and resulted 
  % in data objects that can be obtained with:
  %
  % mous_db_getdata(subjectname, 'meg_multisetcca_groupinfo');
  % mous_db_getdata(subjectname, 'meg_multisetcca_timinginfo');
  %
  % at least, for the sentence stimuli
end

if create_shuffle_indx
%   mous_db_getdata(subj{1},'meg_multisetcca_groupinfo');
%   for m = 1:500
%     [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
%     savedir = '/project/3011020.09/jansch/mscca_group';
%     save(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
%     clear reorder stimid;
%   end
end

if create_shuffle_indx_seq
%   mous_db_getdata(subj{1},'meg_multisetcca_groupinfo_seq');
%   for m = 1:500
%     [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
%     savedir = '/project/3011020.09/jansch/mscca_group';
%     save(fullfile(savedir,'params',sprintf('shuff_sce%d_indx%04d_seq',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
%     clear reorder stimid;
%   end
end

if dohyperalignment || dohyperalignment_seq
  if dohyperalignment &&  dohyperalignment_seq
    error('not both can be true at the same time');
  elseif dohyperalignment
    suffix = ''; % the filenames don't have a suffix
  elseif dohyperalignment_seq
    suffix = '_seq';
  end
  
  load mous_stimuli; 
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  shift   = zeros(1,numel(subj));
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
    
    for kk = 1:numel(subjectdata{1,k}.trial)
      tmp = subjectdata{1,k}.trial{kk};
      tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
      subjectdata{1,k}.trial{kk} = tmp;
    end
    
    
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',suffix));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',suffix));
    subjecttiming{1,k} = timinginfo; % subject specific information about timing
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch(k));
  
    % shift, use only the first 2 components
    lags = -50:2:50;
    groupdata{k}.trial = cellshift(cellrowselect(groupdata{k}.trial, 1:2), lags, 2, [], 'overlap');
    groupdata{k}.time  = cellshift(groupdata{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    groupdata{k}.label = repmat(groupdata{k}.label(1:2),numel(lags),1);
    for kk = 1:numel(groupdata{k}.label)/2
      groupdata{k}.label{(kk-1)*2+1} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*2+1}, kk);
      groupdata{k}.label{(kk-1)*2+2} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*2+2}, kk);
    end

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
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 1, 1,false);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    [cohstim, coh]       = mous_multisetcca_coh(comp);
    comp                 = ft_struct2single(comp);
    
    filename = fullfile(savedir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
    save(filename, 'rho', 'W', 'A', 'comp', 'coh', 'cohstim');
  end
  
  switch shuftype
    case 'lenient'
      % FIXME, what would be a good permutation scheme here?
      
    case 'conservative'
      % FIXME, what would be a good permutation scheme here?
      
  end
end

%%%%%%%%%%%%%%%%%%%%%%
% TO BE CHECKED
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
