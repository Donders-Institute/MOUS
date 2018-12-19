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

if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/';  end
if ~exist('computedata',      'var'), computedata      = false;                       end
if ~exist('computedata_seq',  'var'), computedata_seq  = false;                       end
if ~exist('cleandata',        'var'), cleandata        = false;                       end
if ~exist('cleandata_seq',    'var'), cleandata_seq    = false;                       end
if ~exist('dolcmv',           'var'), dolcmv           = false;                       end
if ~exist('dolcmv_seq',       'var'), dolcmv_seq       = false;                       end
if ~exist('dotrc',           'var'), dotrc             = false;                       end
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
  
  selvis   = find(contains(subj,'V'));
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
    groupdata{1,k}  = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch(k));
    groupdata1{1,k} = groupdata{k};
    groupdata2{1,k} = groupdata{k};
    
    lags = -6:6;
    groupdata{k}.trial = cellshift(groupdata{k}.trial, lags, 2, [], 'overlap');
    groupdata{k}.time  = cellshift(groupdata{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    groupdata{k}.label = repmat(groupdata{k}.label(1:5),numel(lags),1);
    
    groupdata2{k}.trial = cellshift(cellrowselect(groupdata2{k}.trial,1), lags, 2, [], 'overlap');
    groupdata2{k}.time  = cellshift(groupdata2{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    groupdata2{k}.label = repmat(groupdata2{k}.label(1),numel(lags),1);
    
    for kk = 1:numel(groupdata{k}.label)/5
      groupdata{k}.label{(kk-1)*5+1} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*5+1}, kk);
      groupdata{k}.label{(kk-1)*5+2} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*5+2}, kk);
      groupdata{k}.label{(kk-1)*5+3} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*5+3}, kk);
      groupdata{k}.label{(kk-1)*5+4} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*5+4}, kk);
      groupdata{k}.label{(kk-1)*5+5} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*5+5}, kk);
    end
    for kk = 1:numel(groupdata2{k}.label)
      groupdata2{k}.label{kk} = sprintf('%s_shift%03d',groupdata2{k}.label{kk}, kk);
    end
    
    % groupdata contains the lag-shifted data for 5 components per parcel
    % groupdata1 contains the 5 components per parcel
    % groupdata2 contains the lag-shifted data for the first component per
    % parcel
    
    cfg = [];
    cfg.method = 'acrosschannel';
    groupdata{1,k}  = ft_channelnormalise(cfg, groupdata{1,k});
    groupdata1{1,k} = ft_channelnormalise(cfg, groupdata1{1,k});
    groupdata2{1,k} = ft_channelnormalise(cfg, groupdata2{1,k});
    for kk = 1:numel(groupdata{1,k}.trial)
      sel = nearest(groupdata{1,k}.time{kk},-0.1);
      groupdata{1,k}.trial{kk} = groupdata{1,k}.trial{kk}(:,sel:end);
      groupdata{1,k}.time{kk}  = groupdata{1,k}.time{kk}(sel:end);
      
      sel = nearest(groupdata1{1,k}.time{kk},-0.1);
      groupdata1{1,k}.trial{kk} = groupdata1{1,k}.trial{kk}(:,sel:end);
      groupdata1{1,k}.time{kk}  = groupdata1{1,k}.time{kk}(sel:end);
      
      sel = nearest(groupdata2{1,k}.time{kk},-0.1);
      groupdata2{1,k}.trial{kk} = groupdata2{1,k}.trial{kk}(:,sel:end);
      groupdata2{1,k}.time{kk}  = groupdata2{1,k}.time{kk}(sel:end);
    end
  end
  
   if ~skip_noshuffle
     rng('default'); 
    
    % hyperalignment, i.e. with lags 
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj);
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 1, 1,false);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    [tlck]               = mous_multisetcca_extractwords(comp, stimuli);
    [trc]                = mous_multisetcca_trc(tlck, stimuli, 'output2', 'single_all');
    
    % plain and simple mscca
    tmpdata1             = mous_multisetcca_groupdata2singlestruct(groupdata1, subj);
    [W1, A1, rho1, C1, comp1] = mous_multisetcca(tmpdata1, nfold, 1, 1,false);
    [comp1, rho1]        = mous_multisetcca_postprocess(comp1, rho1, source_parc.label{parcel_indx});
    [tlck1]              = mous_multisetcca_extractwords(comp1, stimuli);
    [trc1]               = mous_multisetcca_trc(tlck1, stimuli, 'output2', 'single_all');
    
    % mscca on the time-shifted first component
    tmpdata2             = mous_multisetcca_groupdata2singlestruct(groupdata2, subj);
    [W2, A2, rho2, C2, comp2] = mous_multisetcca(tmpdata2, nfold, 1, 1,false);
    [comp2, rho2]        = mous_multisetcca_postprocess(comp2, rho2, source_parc.label{parcel_indx});
    [tlck2]              = mous_multisetcca_extractwords(comp2, stimuli);
    [trc2]               = mous_multisetcca_trc(tlck2, stimuli, 'output2', 'single_all');
    
    % first principal component
    tmpcfg = [];
    tmpcfg.channel = tmpdata1.label(1:5:end);
    tmpdata1 = ft_selectdata(tmpcfg, tmpdata1);
    [tlck3, Trl_idx]     = mous_multisetcca_extractwords(tmpdata1, stimuli);
    [trc3]               = mous_multisetcca_trc(tlck3, stimuli, 'output2', 'single_all');
    
    
    filename = fullfile(savedir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
    save(filename, 'rho', 'W', 'A', 'rho1', 'W1', 'A1', 'rho2', 'W2', 'A2', 'tlck', 'tlck1', 'tlck2', 'tlck3', 'trc', 'trc1', 'trc2', 'trc3');
  end
  
  switch shuftype
    case 'lenient'
      % FIXME, what would be a good permutation scheme here?
      
    case 'conservative'
      % FIXME, what would be a good permutation scheme here?
      
  end
end

if makemodels
  nrand = 500;
  
  addpath('/home/language/jansch/matlab/toolboxes/prevalence-permutation');
  
  if ~exist('parcel_indx', 'var')
    error('please supply parcel_indx');
  end
  if ~exist('stimuli', 'var')
    load mous_stimuli;
  end
  suffix = ''; % for now
  loaddir = '/project/3011020.09/jansch/hyperalignment';
  filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'tlck', 'tlck1', 'tlck2', 'tlck3');
  
  sel =       double(strncmp([tlck.trialinfo.POS], 'N',   1))*1;
  sel = sel + double(strncmp([tlck.trialinfo.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([tlck.trialinfo.POS], 'ADJ', 3))*3;

  % select these from the data
  tmpcfg = [];
  tmpcfg.trials = find(sel>0);
  tlck  = ft_selectdata(tmpcfg, tlck );
  tlck1 = ft_selectdata(tmpcfg, tlck1);
  tlck2 = ft_selectdata(tmpcfg, tlck2);
  tlck3 = ft_selectdata(tmpcfg, tlck3);
  
  ivar = tlck.trialinfo.Properties.VariableNames;
  test_ivars = {'w2v'};%{'loglexfreq' 'index' 'logperplexity' 'entropy' ...
    %'leftbranch' 'rightbranch' ...
    %'dleftbranch' 'drightbranch' 'w2v'};
  
  sel_ivars = match_str(ivar, test_ivars);
  cnt = 0;
  for m = sel_ivars(:)'
    fprintf('modelling the data with %s\n',ivar{m});
    cnt = cnt+1;
    design = tlck.trialinfo(:,m); 
    design.(ivar{m}) = design.(ivar{m}) - nanmean(design.(ivar{m}));
    
    stat   = mous_multisetcca_regress(tlck, design,'constant',1,'lambda',1, 'folds', 5); % with folding, the 'F' is actually a measure of R^2, i.e. the extent to which the predictor predicts... (in analogy to the metric used in scikit learn, which happens indeed to adopt negative values occasionally). 
    stat1  = mous_multisetcca_regress(tlck1,design,'constant',1,'lambda',1, 'folds', 5);
    stat2  = mous_multisetcca_regress(tlck2,design,'constant',1,'lambda',1, 'folds', 5);
    stat3  = mous_multisetcca_regress(tlck3,design,'constant',1,'lambda',1, 'folds', 5);
    
    rng('default');
    p = zeros(size(stat.F));
    p1 = p;
    p2 = p;
    p3 = p;
    Frand  = zeros([size(stat.F) nrand]);
    Frand1 = zeros([size(stat.F) nrand]);
    Frand2 = zeros([size(stat.F) nrand]);
    Frand3 = zeros([size(stat.F) nrand]);
    for k = 1:nrand
      if mod(k,100)==0, fprintf('performing randomization %d/%d\n',k,nrand); end
      if ~isequal(ivar{m},'w2v')
        tmpdesign = design;
        tmpdesign.(ivar{m}) = tmpdesign.(ivar{m})(randperm(size(tlck.trial,1)));
      else
        tmpdesign = design;
        tmpX = table2array(tmpdesign);
        tmpX = tmpX(randperm(size(tmpX,1)),:);
        tmpdesign.(ivar{m}) = tmpX;
      end
            
      tmp   = mous_multisetcca_regress(tlck, tmpdesign,'constant',1,'lambda',1, 'folds', 5);
      tmp1  = mous_multisetcca_regress(tlck1,tmpdesign,'constant',1,'lambda',1, 'folds', 5);
      tmp2  = mous_multisetcca_regress(tlck2,tmpdesign,'constant',1,'lambda',1, 'folds', 5);
      tmp3  = mous_multisetcca_regress(tlck3,tmpdesign,'constant',1,'lambda',1, 'folds', 5);
      
      p  = p  + double(tmp.F  > stat.F );
      p1 = p1 + double(tmp1.F > stat1.F);
      p2 = p2 + double(tmp2.F > stat2.F);
      p3 = p3 + double(tmp3.F > stat3.F);
      
      Frand(:,:,k)  = tmp.F;
      Frand1(:,:,k) = tmp1.F;
      Frand2(:,:,k) = tmp2.F;
      Frand3(:,:,k) = tmp3.F;
      
    end
    S(cnt).stat  = stat;
    S(cnt).p     = (p+1)./nrand; % uncorrected p-value of the permutations
    %S(cnt).Frand = Frand;
    S(cnt).ivar  = ivar{m};
    S(cnt).ref   = nanmean(Frand,3);
    
    S1(cnt).stat  = stat1;
    S1(cnt).p     = (p1+1)./nrand;
    %S1(cnt).Frand = Frand1;
    S1(cnt).ivar  = ivar{m};
    S1(cnt).ref   = nanmean(Frand1,3);
    
    S2(cnt).stat  = stat2;
    S2(cnt).p     = (p2+1)./nrand;
    %S2(cnt).Frand = Frand2;
    S2(cnt).ivar  = ivar{m};
    S2(cnt).ref   = nanmean(Frand2,3);
    
    S3(cnt).stat  = stat3;
    S3(cnt).p     = (p3+1)./nrand;
    %S3(cnt).Frand = Frand3;
    S3(cnt).ivar  = ivar{m};
    S3(cnt).ref   = nanmean(Frand3,3);
    
%     tmpdat = permute(Frand(4:end,:,:),[2 1 3]);
%     %tmpdat = cat(3,1-stat.R(4:end,:)'./stat.R0(4:end,:)',tmpdat);
%     tmpdat = cat(3,stat.F(4:20,:)',tmpdat);
%     [S(cnt).prev.results, S(cnt).prev.params] = prevalenceCore(tmpdat,250000);
%     
%     tmpdat = permute(Frand1(4:end,:,:),[2 1 3]);
%     %tmpdat = cat(3,1-stat1.R(4:end,:)'./stat1.R0(4:end,:)',tmpdat);
%     tmpdat = cat(3,stat1.F(4:20,:)',tmpdat);
%     [S1(cnt).prev.results, S1(cnt).prev.params] = prevalenceCore(tmpdat,250000);
%     
%     tmpdat = permute(Frand2(4:end,:,:),[2 1 3]);
%     %tmpdat = cat(3,1-stat2.R(4:end,:)'./stat2.R0(4:end,:)',tmpdat);
%     tmpdat = cat(3,stat2.F(4:20,:)',tmpdat);
%     [S2(cnt).prev.results, S2(cnt).prev.params] = prevalenceCore(tmpdat,250000);
%     
%     tmpdat = permute(Frand3(4:end,:,:),[2 1 3]);
%     %tmpdat = cat(3,1-stat3.R(4:end,:)'./stat3.R0(4:end,:)',tmpdat);
%     tmpdat = cat(3,stat3.F(4:20,:)',tmpdat);
%     [S3(cnt).prev.results, S3(cnt).prev.params] = prevalenceCore(tmpdat,250000);
    close all;
  end
  
  %filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s_models',scenario,parcel_indx,suffix));
  filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s_models_w2v',scenario,parcel_indx,suffix));
  
  save(filename, 'S', 'S1', 'S2', 'S3');
end
