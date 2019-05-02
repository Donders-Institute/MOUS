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
if ~exist('combinemodels', 'var'), combinemodels = false; end
if ~exist('dostats', 'var'), dostats = false; end

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
  subj     = setdiff(subj, {'V1017'});
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
  load mous_stimuli; 
  
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  if ~exist('lambda', 'var')
    lambda = 1;
  end
  if dohyperalignment &&  dohyperalignment_seq
    error('not both can be true at the same time');
  elseif dohyperalignment
    suffix = ''; % the filenames don't have a suffix
  elseif dohyperalignment_seq
    suffix = '_seq';
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
    
    % THIS IS A HARD CODED STEP THAT AIMS AT REMOVING A STRONG REMAINING
    % ARTIFACT
    if strcmp(subj{k},'V1077')
      sel = find(data.trialinfo(:,end)==393);
      data.trial{sel}(:) = nan;
    end
    
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
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 1, lambda,false);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    [tlck]               = mous_multisetcca_extractwords(comp, stimuli);
    [trc]                = mous_multisetcca_trc(tlck, stimuli, 'output2', 'single_all');
    
    % plain and simple mscca
    tmpdata1             = mous_multisetcca_groupdata2singlestruct(groupdata1, subj);
    [W1, A1, rho1, C1, comp1] = mous_multisetcca(tmpdata1, nfold, 1, lambda, false);
    [comp1, rho1]        = mous_multisetcca_postprocess(comp1, rho1, source_parc.label{parcel_indx});
    [tlck1]              = mous_multisetcca_extractwords(comp1, stimuli);
    [trc1]               = mous_multisetcca_trc(tlck1, stimuli, 'output2', 'single_all');
    
    % mscca on the time-shifted first component
    tmpdata2             = mous_multisetcca_groupdata2singlestruct(groupdata2, subj);
    [W2, A2, rho2, C2, comp2] = mous_multisetcca(tmpdata2, nfold, 1, lambda, false);
    [comp2, rho2]        = mous_multisetcca_postprocess(comp2, rho2, source_parc.label{parcel_indx});
    [tlck2]              = mous_multisetcca_extractwords(comp2, stimuli);
    [trc2]               = mous_multisetcca_trc(tlck2, stimuli, 'output2', 'single_all');
    
    % first principal component
    tmpcfg = [];
    tmpcfg.channel = tmpdata1.label(1:5:end);
    tmpdata1 = ft_selectdata(tmpcfg, tmpdata1);
    [tlck3, Trl_idx]     = mous_multisetcca_extractwords(tmpdata1, stimuli);
    [trc3]               = mous_multisetcca_trc(tlck3, stimuli, 'output2', 'single_all');
    
    if numel(nfold)==1 && nfold<=1
      suffix = [suffix '_nocv'];
    end
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
  % this section fits GLM's (cross-validated) to single regressors of
  % interest, and compares the model to a 'constant-only' model.
  addpath('/home/language/jansch/matlab/toolboxes/prevalence-permutation');

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
  
  if ~exist('test_ivars', 'var')
    % test a bunch at once: this does not allow for ivar specific lambdas
    test_ivars = {'nchar' 'loglexfreq' 'index' 'logperplexity' 'entropy' ...
                  'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'w2v'};
  end
  if ~iscell(test_ivars)
    test_ivars = {test_ivars};
  end
  
  suffix   = ''; % for now
  loaddir  = '/project/3011020.09/jansch/hyperalignment';
  filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario,parcel_indx,suffix));
  load(filename, 'tlck', 'tlck1', 'tlck2', 'tlck3');
  
  sel =       double(strncmp([tlck.trialinfo.POS], 'N',   1))*1;
  sel = sel + double(strncmp([tlck.trialinfo.POS], 'WW',  2))*2;
  sel = sel + double(strncmp([tlck.trialinfo.POS], 'ADJ', 3))*3;

  % select these from the data
  tmpcfg = [];
  tmpcfg.trials = find(sel>0);
  tmpcfg.channel = tlck.label(4:end);
  tmpcfg.latency = [0 0.6];  
  tlck  = ft_selectdata(tmpcfg, tlck );
  tlck1 = ft_selectdata(tmpcfg, tlck1);
  tlck2 = ft_selectdata(tmpcfg, tlck2);
  tmpcfg.channel = tlck3.label(4:end);
  tlck3 = ft_selectdata(tmpcfg, tlck3);
  
  % add a constant regressor to the design
  tlck.trialinfo  = cat(2, array2table(ones(size(tlck.trial,1),1), 'VariableNames', {'constant'}),  tlck.trialinfo);
  tlck1.trialinfo = cat(2, array2table(ones(size(tlck1.trial,1),1),'VariableNames', {'constant'}), tlck1.trialinfo);
  tlck2.trialinfo = cat(2, array2table(ones(size(tlck2.trial,1),1),'VariableNames', {'constant'}), tlck2.trialinfo);
  tlck3.trialinfo = cat(2, array2table(ones(size(tlck3.trial,1),1),'VariableNames', {'constant'}), tlck3.trialinfo);
    
  ivar       = tlck.trialinfo.Properties.VariableNames;
  
  categorical = ismember(ivar, {'nchar' 'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'index'});
    
  sel_ivars = match_str(ivar, test_ivars);
  cnt = 0;
  for m = sel_ivars(:)'
    fprintf('modelling the data with %s\n',ivar{m});
    cnt = cnt+1;
    sel = ismember(ivar, {'constant' ivar{m}});
    
    design = tlck.trialinfo(:,sel); 
    design.(ivar{m}) = design.(ivar{m}) - nanmean(design.(ivar{m}));
    
    stat   = mous_multisetcca_regress(tlck, design,'lambda',lambda, 'outerfolds', 5, 'balancefolds', categorical(m), 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
    stat1  = mous_multisetcca_regress(tlck1,design,'lambda',lambda, 'outerfolds', 5, 'balancefolds', categorical(m), 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
    stat2  = mous_multisetcca_regress(tlck2,design,'lambda',lambda, 'outerfolds', 5, 'balancefolds', categorical(m), 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
    stat3  = mous_multisetcca_regress(tlck3,design,'lambda',lambda, 'outerfolds', 5, 'balancefolds', categorical(m), 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
    
    rng('default');
    p = zeros(size(stat.Rsq));
    p1 = p;
    p2 = p;
    p3 = p;
    Frand  = zeros([size(stat.Rsq) nrand]);
    Frand1 = zeros([size(stat.Rsq) nrand]);
    Frand2 = zeros([size(stat.Rsq) nrand]);
    Frand3 = zeros([size(stat.Rsq) nrand]);
    for k = 1:nrand
      if mod(k,10)==0, fprintf('performing randomization %d/%d\n',k,nrand); end
      if ~isequal(ivar{m},'w2v')
        tmpdesign = design;
        tmpdesign.(ivar{m}) = tmpdesign.(ivar{m})(randperm(size(tlck.trial,1)));
      else
        tmpdesign = design;
        tmpX = table2array(tmpdesign);
        tmpX = tmpX(randperm(size(tmpX,1)),:);
        tmpdesign.(ivar{m}) = tmpX;
      end
            
      tmp   = mous_multisetcca_regress(tlck, tmpdesign,'constant',1,'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
      tmp1  = mous_multisetcca_regress(tlck1,tmpdesign,'constant',1,'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
      tmp2  = mous_multisetcca_regress(tlck2,tmpdesign,'constant',1,'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
      tmp3  = mous_multisetcca_regress(tlck3,tmpdesign,'constant',1,'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', {'constant'}, 'innerfolds', 5);
      
      p  = p  + double(tmp.Rsq  > stat.Rsq );
      p1 = p1 + double(tmp1.Rsq > stat1.Rsq);
      p2 = p2 + double(tmp2.Rsq > stat2.Rsq);
      p3 = p3 + double(tmp3.Rsq > stat3.Rsq);
      
      Frand(:,:,k)  = tmp.Rsq;
      Frand1(:,:,k) = tmp1.Rsq;
      Frand2(:,:,k) = tmp2.Rsq;
      Frand3(:,:,k) = tmp3.Rsq;
      
    end
    S.stat  = stat;
    S.p     = (p+1)./nrand; % uncorrected p-value of the permutations
    S.ivar  = ivar{m};
    S.ref   = nanmean(Frand,3);
    S.nrand = nrand;
    %S.ref   = nanmax(Frand,[],3);
    
    S1.stat  = stat1;
    S1.p     = (p1+1)./nrand;
    S1.ivar  = ivar{m};
    S1.ref   = nanmean(Frand1,3);
    S1.nrand = nrand;
    %S1.ref   = nanmax(Frand1,[],3);
    
    S2.stat  = stat2;
    S2.p     = (p2+1)./nrand;
    S2.ivar  = ivar{m};
    S2.ref   = nanmean(Frand2,3);
    S2.nrand = nrand;
    %S2.ref   = nanmax(Frand2,[],3);
    
    S3.stat  = stat3;
    S3.p     = (p3+1)./nrand;
    S3.ivar  = ivar{m};
    S3.ref   = nanmean(Frand3,3);
    S3.nrand = nrand;
    %S3.ref   = nanmax(Frand3,[],3);
    
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s_model_%s',scenario,parcel_indx,suffix,ivar{m}));
    save(filename, 'S', 'S1', 'S2', 'S3');
    close all;
    
  end
end

if ~exist('makemodels2', 'var')
  makemodels2 = false;
end
if makemodels2
  addpath('/home/language/jansch/matlab/toolboxes/prevalence-permutation');

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
                  'leftbranch' 'dleftbranch'};
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
  loaddir = '/project/3011020.09/jansch/hyperalignment';
  
  clear S;
  for mm = 1:numel(scenario)
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario(mm),parcel_indx,suffix));
    load(filename, 'tlck', 'tlck1', 'tlck2', 'tlck3');
    
    sel =       double(strncmp([tlck.trialinfo.POS], 'N',   1))*1;
    sel = sel + double(strncmp([tlck.trialinfo.POS], 'WW',  2))*2;
    sel = sel + double(strncmp([tlck.trialinfo.POS], 'ADJ', 3))*3;
    
    % select these from the data
    tmpcfg = [];
    tmpcfg.trials = find(sel>0);
    tmpcfg.channel = tlck.label(4:end);
    tmpcfg.latency = [0 0.6];
    tlck  = ft_selectdata(tmpcfg, tlck );
    tlck1 = ft_selectdata(tmpcfg, tlck1);
    tlck2 = ft_selectdata(tmpcfg, tlck2);
    tmpcfg.channel = tlck3.label(4:end);
    tlck3 = ft_selectdata(tmpcfg, tlck3);
    
    % add a constant regressor to the design
    tlck.trialinfo  = cat(2, array2table(ones(size(tlck.trial,1),1), 'VariableNames', {'constant'}),  tlck.trialinfo);
    tlck1.trialinfo = cat(2, array2table(ones(size(tlck1.trial,1),1),'VariableNames', {'constant'}), tlck1.trialinfo);
    tlck2.trialinfo = cat(2, array2table(ones(size(tlck2.trial,1),1),'VariableNames', {'constant'}), tlck2.trialinfo);
    tlck3.trialinfo = cat(2, array2table(ones(size(tlck3.trial,1),1),'VariableNames', {'constant'}), tlck3.trialinfo);
    
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
    categorical = ismember(ivar, {'nchar' 'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'index'});
    
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
          if strcmp(vars{j},ivar{indx}) % commenting this out causes the
          %whole design to be randomised, not commenting this out causes
          %only the ivar of interest to be randomized
            tmpX = tmpdesign.(vars{j});
            tmpX = tmpX(randvec,:);
            tmpdesign.(vars{j}) = tmpX;
          end
        end
        
        tmp = mous_multisetcca_regress(tlck, tmpdesign(:,[setdiff(1:size(design,2),indx) indx]),'lambda',lambda, 'outerfolds', 5, 'normalise', true, 'modelcomparison', ivar(setdiff(1:size(design,2),indx)), 'innerfolds', 5, 'nrepeat', 5);
        p   = p  + double(tmp.Rsq  > stat.Rsq );
        
        Frand(:,:,k)  = tmp.Rsq;
      end
      S(mm).stat  = stat;
      S(mm).p     = (p)./nrand; % uncorrected p-value of the permutations
      S(mm).ivar  = ivar{indx};
      S(mm).ref   = nanmean(Frand,3);
      %S(mm).perms = Frand;
    end
  end
%   for mm = 1:numel(S)
%     if mm==1
%       obs = S(mm).stat.Rsq;
%       perms = S(mm).perms;
%     else
%       obs = cat(1,obs,S(mm).stat.Rsq);
%       perms = cat(1,perms,S(mm).perms);
%     end
%   end
%   
%   a = cat(3,obs',permute(perms,[2 1 3]));
%   rng('default');
%   [results, params] = prevalenceCore(a);
  
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
  %S = rmfield(S(1), 'perms');
  
  
  %S.prevalence.results = results;
  %S.prevalence.params  = params;
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

if ~exist('makemodels3', 'var')
  makemodels3 = false;
end
if makemodels3
  % this section does a leave-one-subject-out model
  
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
                  'leftbranch' 'dleftbranch'};
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
  loaddir = '/project/3011020.09/jansch/hyperalignment';
  
  clear S;
  for mm = 1:numel(scenario)
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s',scenario(mm),parcel_indx,suffix));
    load(filename, 'tlck', 'tlck1', 'tlck2', 'tlck3');
    
    sel =       double(strncmp([tlck.trialinfo.POS], 'N',   1))*1;
    sel = sel + double(strncmp([tlck.trialinfo.POS], 'WW',  2))*2;
    sel = sel + double(strncmp([tlck.trialinfo.POS], 'ADJ', 3))*3;
    
    % select these from the data
    tmpcfg = [];
    tmpcfg.trials = find(sel>0);
    tmpcfg.channel = tlck.label(4:end);
    tmpcfg.latency = [0 0.6];
    tlck  = ft_selectdata(tmpcfg, tlck );
    tlck1 = ft_selectdata(tmpcfg, tlck1);
    tlck2 = ft_selectdata(tmpcfg, tlck2);
    tmpcfg.channel = tlck3.label(4:end);
    tlck3 = ft_selectdata(tmpcfg, tlck3);
    
    % add a constant regressor to the design
    tlck.trialinfo  = cat(2, array2table(ones(size(tlck.trial,1),1), 'VariableNames', {'constant'}),  tlck.trialinfo);
    tlck1.trialinfo = cat(2, array2table(ones(size(tlck1.trial,1),1),'VariableNames', {'constant'}), tlck1.trialinfo);
    tlck2.trialinfo = cat(2, array2table(ones(size(tlck2.trial,1),1),'VariableNames', {'constant'}), tlck2.trialinfo);
    tlck3.trialinfo = cat(2, array2table(ones(size(tlck3.trial,1),1),'VariableNames', {'constant'}), tlck3.trialinfo);
    
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
    
    % reorganise the data, concatenate across subjects, and repmat the
    % design, create folding indices
    nrpt  = size(tlck.trial,1);
    nsubj = size(tlck.trial,2);
    ntim  = size(tlck.trial,3);
    tlck.trial = reshape(tlck.trial,[nrpt*nsubj 1 ntim]);
    tlck.trialinfo = repmat(tlck.trialinfo, [nsubj 1]);
    tlck.label = {'concatenatedsubjects'};
    design = repmat(design, [nsubj 1]);
    for m = 1:nsubj
      outerfolds{m} = (m-1)*nrpt + (1:nrpt);
    end
    
    ivar        = ivar(sel_ivars);
    categorical = ismember(ivar, {'nchar' 'leftbranch' 'rightbranch' 'dleftbranch' 'drightbranch' 'index'});
    
    for m = 1:numel(test_ivars)
      indx = find(ismember(ivar, test_ivars{m}));
      
      fprintf('modelling the data with %s\n',ivar{indx});
      
      stat   = mous_multisetcca_regress(tlck, design(:,[setdiff(1:size(design,2),indx) indx]),'lambda',lambda, 'outerfolds', outerfolds, 'balancefolds', categorical(indx), 'normalise', true, 'modelcomparison', ivar(setdiff(1:size(design,2),indx)), 'innerfolds', 5, 'nrepeat', 1);
      
      rng('default');
      p = zeros(size(stat.Rsq));
      Frand  = zeros([size(stat.Rsq) nrand]);
      for k = 1:nrand
        if mod(k,10)==0, fprintf('performing randomization %d/%d\n',k,nrand); end
        tmpdesign = design;
        
        randvec = reshape(repmat(randperm(nrpt)',[1 nsubj]) + nrpt.*repmat((1:nsubj)-1, [nrpt 1]),[],1);
        
        
        vars    = design.Properties.VariableNames;
        for j = 1:numel(vars)
          if strcmp(vars{j},ivar{indx}) % commenting this out causes the
          %whole design to be randomised, not commenting this out causes
          %only the ivar of interest to be randomized
            tmpX = tmpdesign.(vars{j});
            tmpX = tmpX(randvec,:);
            tmpdesign.(vars{j}) = tmpX;
          end
        end
        
        tmp = mous_multisetcca_regress(tlck, tmpdesign(:,[setdiff(1:size(design,2),indx) indx]),'lambda',lambda, 'outerfolds', outerfolds, 'normalise', true, 'modelcomparison', ivar(setdiff(1:size(design,2),indx)), 'innerfolds', 5, 'nrepeat', 1);
        p   = p  + double(tmp.Rsq  > stat.Rsq );
        
        Frand(:,:,k)  = tmp.Rsq;
      end
      S(mm).stat  = stat;
      S(mm).p     = (p+1)./(nrand+1); % uncorrected p-value of the permutations
      S(mm).ivar  = ivar{indx};
      S(mm).ref   = permute(Frand,[3 2 1]);
      %S(mm).perms = Frand;
    end
  end

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
  
  if numel(scenario)==1
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%d_parcel%03d%s_model3_%s',scenario,parcel_indx,suffix,ivar{indx}));
  else
    str = '';
    for mm = 1:numel(scenario)
      str = [str num2str(scenario(mm))];
    end
    filename = fullfile(loaddir, sprintf('hyperalignment_sce%s_parcel%03d%s_model3_%s',str,parcel_indx,suffix,ivar{indx}));
  end
  save(filename, 'S');
end


if combinemodels
  if ~exist('modeltype', 'var')
    modeltype = 'model';
  end
  if ~exist('ivar', 'var')
    error('ivar needs to be defined');
  end
  
  % collapse the parcel specific data into a (hopefully smaller) variable,
  % so that the original '*models.mat' files can be discarded
  datadir = '/project/3011020.09/jansch/hyperalignment'; %HARDCODED
   
  d = dir(fullfile(datadir,sprintf('*sce%d*%s_%s.mat',scenario,modeltype,ivar)));
  %d = dir(fullfile(datadir,sprintf('*sce%d*models2.mat',scenario)));
  
  if numel(d)~=378
    % some parcels failed to compute because too few vertices per parcel
    warning('number of files is less than the expected number of 378 parcels');
    for k = 1:numel(d)
      nx(k)=str2num(d(k).name(27:29));
    end
    indx = 1:382;
    indx([190 191 381 382]) = [];
    skipvec = true(378,1);
    skipvec(find(ismember(indx,nx))) = false;
  else
    skipvec = false(378,1);
  end
  
  for k = 1:numel(d)
    if ~skipvec(k)
      fprintf('processing file %s\n', d(k).name);
      if exist('fn', 'var') && numel(fn)==1
        dat = load(fullfile(d(k).folder,d(k).name),fn{1});
      else
        dat = load(fullfile(d(k).folder,d(k).name));
        fn = fieldnames(dat);
        fn = fn(1); % keep RAM use within bounds, repeat for the other variables
        fprintf('using variable %s\n',fn{1});
      end
    else
      continue;
    end
    
    if k==1
      fprintf('using variable %s\n',fn{1});
    end
    
    for m = 1:numel(fn)
      tmp = dat.(fn{m});
      for p = 1:numel(tmp)
        tmp2 = tmp(p);
        tmp2.Rsq = tmp2.stat.Rsq;
        %tmp2.B   = nanmean(tmp2.stat.B,4);
        %tmp2.lambda = tmp2.stat.lambda;
        tmp2     = rmfield(tmp2, 'stat');
        
        if k==1   
          tmp2.Rsq(:,:,378) = 0;
          %tmp2.B(:,:,:,378) = 0;
          tmp2.ref(:,:,378) = 0;
          tmp2.p(:,:,378)   = 0;
          %tmp2.lambda(:,:,378) = 0;
        
          if isfield(tmp2, 'prevalence')
            fnprev = fieldnames(tmp2.prevalence.results);
            for kk = 1:numel(fnprev)
              if ~strcmp(fnprev{kk},'refDistr')
                tmp2.prevalence.results.(fnprev{kk})(:,378) = 0;
              end
            end
          end
          
          if isfield(tmp.stat, 'time')
            tmp2.time = tmp.stat.time;
          end
          
          data.(fn{m})(p) = tmp2;
        else
          data.(fn{m})(p).p(:,:,k)   = tmp2.p;
          data.(fn{m})(p).Rsq(:,:,k) = tmp2.Rsq;
          data.(fn{m})(p).ref(:,:,k) = tmp2.ref;
          %data.(fn{m})(p).B(:,:,:,k) = tmp2.B;
          %data.(fn{m})(p).lambda(:,:,k) = tmp2.lambda;
          if isfield(tmp2, 'prevalence')
            for kk = 1:numel(fnprev)
              if ~strcmp(fnprev{kk},'refDistr')
                data.(fn{m})(p).prevalence.results.(fnprev{kk})(:,k) = tmp2.prevalence.results.(fnprev{kk});
              else
                data.(fn{m})(p).prevalence.results.(fnprev{kk}) = max(data.(fn{m})(p).prevalence.results.(fnprev{kk}), tmp2.prevalence.results.(fnprev{kk}));
              end
            end
          end
        end
      end
    end
    clear dat;
  end
  
  
  data = ft_struct2single(data);
  filename = fullfile(datadir, sprintf('hyperalignment_sce%d_%s_%s_%s', scenario, modeltype, ivar, fn{1}));
  %filename = fullfile(datadir, sprintf('hyperalignment_models2_sce%d_%s', scenario, fn{1}));
  save(filename,'-struct', 'data');
  
end

if dostats
  if ~exist('modeltype', 'var')
    modeltype = 'model2';
  end
  if ~exist('ivar', 'var')
    error('ivar needs to be defined');
  end
  
  % collapse the parcel specific data into a (hopefully smaller) variable,
  % so that the original '*models.mat' files can be discarded
  datadir  = '/project/3011020.09/jansch/hyperalignment';%HARDCODED
  filename = fullfile(datadir, sprintf('hyperalignment_sce%d_%s_%s_S', scenario, modeltype, ivar));
  load(filename);
  
  n = size(S.Rsq,1);
  
  
  load atlas_conte69_8196reg_LR_brodmann_subparc.mat
  
  label = atlas.parcellationlabel;
  label([1 2 194 195 190 191 381 382]) = [];
  [a,b] = match_str(atlas.parcellationlabel, label);
  s.pow = zeros(n*2,386,size(S.Rsq,2)); % hard coded, can be different for different scenario pairs
  s.pow(1:n,a,:) = permute(double(S.Rsq),[1 3 2]);
  s.pow(n+(1:n),a,:) = permute(double(S.ref), [1 3 2]);
  s.dimord = 'rpt_chan_time';
  s.time   = S.time;
  s.label  = atlas.parcellationlabel;
  s.brainordinate = atlas;
  
  cfg                  = [];
  cfg.connectivity     = parcellation2connmat(atlas);
  cfg.tail             = 1;
  cfg.clustertail      = 1;
  cfg.clusterthreshold = 'nonparametric_individual';
  cfg.clusteralpha     = 0.01;
  cfg.feedback         = 'text';
  cfg.clusterstatistic = 'maxsum';
  cfg.statistic        = 'depsamplesT';%'ft_statfun_wilcoxon';
  cfg.numrandomization = 1000;
  cfg.method = 'montecarlo';
  cfg.ivar   = 1;
  cfg.uvar   = 2;
  cfg.design = [ones(1,n) ones(1,n)*2;1:n 1:n];
  cfg.parameter = 'pow';
  cfg.correctm = 'cluster';
  for k = 1:numel(s.label)
    cfg.neighbours(k).label = s.label{k}; % to get past ft_checkconfig
    cfg.neighbours(k).neighblabel = {};
  end
  
  stat = ft_timelockstatistics(cfg, s);
  filename = fullfile(datadir, sprintf('hyperalignment_sce%d_%s_%s_stat', scenario, modeltype, ivar));
  save(filename, 'stat');
  
end


      
      
 