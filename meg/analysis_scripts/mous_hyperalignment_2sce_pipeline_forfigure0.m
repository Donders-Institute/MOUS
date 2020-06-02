% this script is branched off from mous_hyperalignment_2sce_pipeline, and
% its purpose is to be able to compute time-resolved correlations of
% the hyperaligned signals (for a subset of parcels), which is possible in
% the original pipeline as well, but also trc for unaligned signals, etc.
% (as per the code in the original mous_hyperalignment_pipeline). This is
% in order to be able to make a comparative figure to showcase the SNR
% boost thanks to the hyperalignment, as per the figure I created for the
% OHBM 2019 poster (and the methods market at the DI)

if ~exist('rootdir',                      'var'), rootdir                   = '/project/3011020.09';       end

if ~exist('savdir', 'var')
  error('define savdir');
end

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

if ~exist('normmethod', 'var')
  normmethod = 'acrosschannel';
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
if ~(all(isequal(scenario,[1 4]))||all(isequal(scenario,[2 5]))||all(isequal(scenario,[3 6])))
  error('wrong combination of scenarii');
end

[a, b] = match_str('V1006',subj);
if a
  subj{b}='';
end
[a, b] = match_str('V1090',subj);
if a
  subj{b}='';
end
[a, b] = match_str('V1017',subj);
if a
  subj{b}='';
end

sce  = sce(contains(subj,'V'));
subj = subj(contains(subj,'V'));

load '/project/3011020.09/misc/stimuli/mous_stimuli.mat';

if ~exist('nfold', 'var'),          nfold          = 5;       end
if ~exist('shuftype', 'var'),       shuftype       = 'none';  end
if ~exist('skip_noshuffle', 'var'), skip_noshuffle = false;   end
if ~exist('parcel_indx', 'var'),    error('a parcel index needs to be specified');  end

% the time shifting occurred so far (up until 20190813) after the
% alignment across subjects. This is strictly suboptimal, because with
% the 2 scenarios involved, the word order is updated in the alignment
% process, leading to temporal discontinuities at the word boundaries,
% therefore as of now (20190813) the timeshifting can be specified to be
% done either before (non-default, but probably preferred) or after the
% alginment. It needs to be evaluated how much 'before' and 'after' are
% going to differ.
if ~exist('timeshift', 'var'),      timeshift      = 'after'; end
assert(strcmp(timeshift, 'before')||strcmp(timeshift, 'after')||strcmp(timeshift, 'none'));

if ~exist('nmax', 'var'), nmax = 5; end
% the nmax variable allows for evaluating different dimensionality of
% original parcels, nmax=1 reflects the first pca component

if ~exist('lags', 'var'), lags = (-6:6); end
% make lags configureable

if strcmp(timeshift, 'none')
  fprintf('no timeshifting required, lags are set to 0\n');
  lags = 0;
end

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
  subjectdata{k}   = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx, nmax);
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
[subjecttiming, groupinfo] = mous_multisetcca_timinginfo_seq2sent(subjecttiming, groupinfo, stimuli, sce);

for k = 1:numel(subj)
  % align the subject-specific parcel data to match all others subjects
  % in terms of timing and trial-order
  if strcmp(timeshift, 'after')
    groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo{k});
    
    groupdata{k}.trial = cellshift(groupdata{k}.trial, lags, 2, [], 'overlap');
    groupdata{k}.time  = cellshift(groupdata{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    norig = numel(groupdata{k}.label);
    groupdata{k}.label = repmat(groupdata{k}.label,numel(lags),1);
    
    for kk = 1:numel(lags)
      for m = 1:norig
        groupdata{k}.label{(kk-1)*norig+m} = sprintf('%s_shift%03d',groupdata{k}.label{(kk-1)*norig+m}, kk);
      end
    end
  elseif strcmp(timeshift, 'before')
    tmp = subjectdata{k}; % create a temporary copy
    
    % perform the time shifting before the reordering of the words
    tmp.trial = cellshift(tmp.trial, lags, 2, [], 'overlap');
    tmp.time  = cellshift(tmp.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    norig = numel(tmp.label);
    tmp.label = repmat(tmp.label,numel(lags),1);
    
    for kk = 1:numel(lags)
      for m = 1:norig
        tmp.label{(kk-1)*norig+m} = sprintf('%s_shift%03d',tmp.label{(kk-1)*norig+m}, kk);
      end
    end
    
    groupdata{k} = mous_multisetcca_getparceldata(subj{k}, tmp, subjecttiming{k}, groupinfo{k});
    
  elseif strcmp(timeshift, 'none')
    groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo{k});
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
  cfg.method     = normmethod;
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

if ~exist('lambda', 'var'), lambda = 0.1; end

rng('default'); % reset the number generator, in order to be able to compare across parcels
if ~skip_noshuffle
  tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata, subj); % first row only
  if isequal(lags,0) && isequal(nmax,1)
    % mcca is not possible
    comp = tmpdata;
    testfold = [];
    rho = [];
    W = [];
    A = [];
    C = [];
  else  
    [W, A, rho, C, comp, testfold] = mous_multisetcca(tmpdata, nfold, 4, lambda,false, true);
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  end
  
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
  
  
  filename = fullfile(savdir, sprintf('mscca_sce%d-%d_parcel%03d',scenario(1),scenario(2),parcel_indx));
  save(filename, 'rho', 'W', 'A', 'comp', 'tlck1', 'tlck2', 'trc1', 'trc2');
end

%--------------------------------------------------------------------------
