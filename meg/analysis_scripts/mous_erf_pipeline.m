% mous_erf_pipeline
%  NL - major changes on 17 March 2014
% For this script, specify the following:
% 1. rootdir
% 2. doerf_main = 0 (or 1)
% 3. doerf_parametric = 0 (or 1)
% 4. wordtype = 'tar', 'first', 'all'
% 5. condition = 'mix','rc'; OR don't specify anything (that's also okay)


% NOTE
% VISUAL SUBJECTS: preprocessed data is in /project/3011020.09/MEG/'
%                  ERF data is in /project/3011020.09/annhul/'
% AUDITORY SUBJS:  both are both in /project/3011020.09/annhul/'
<<<<<<< HEAD

if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/MEG/';  end
if ~exist('inrootdir',        'var'), inrootdir        = rootdir;                     end
if ~exist('outrootdir',       'var'), outrootdir       = rootdir;                     end
if ~exist('doerf_main',       'var'), doerf_main       = 0;                           end
if ~exist('doerf_parametric', 'var'), doerf_parametric = 0;                           end
if ~exist('doerf_rc',         'var'), doerf_rc         = 0;                           end
if ~exist('doerf_mix',        'var'), doerf_mix        = 0;                           end
if ~exist('doerf_rc_onoff',   'var'), doerf_rc_onoff   = 0;                           end
if ~exist('doerf_auditory_chop', 'var'), doerf_auditory_chop = 0;                     end
if ~exist('doerf_auditory_chop_parametric', 'var'), doerf_auditory_chop_parametric = 0; end
if ~exist('doerf_auditory_chop_freq', 'var'), doerf_auditory_chop_freq = 0;           end
if ~exist('doerf_dependency', 'var'),     doerf_dependency     = 0;                   end
if ~exist('doerf_branchingdepth', 'var'), doerf_branchingdepth = 0;                   end
if ~exist('doerf_dependency_shortlong', 'var'), doerf_dependency_shortlong = 0;       end
if ~exist('doerf_speech_tlck', 'var'), doerf_speech_tlck = 0;                         end
if ~exist('doerf_speech_itc',  'var'), doerf_speech_itc  = 0;                         end
if ~exist('condition',        'var'), condition        = '';                          end
if ~exist('wordtype',         'var'), wordtype         = 'all';                       end
if ~exist('contrast',         'var'), contrast         = 'wordsent_parametric_blc';   end

if strcmp(subjectname(1), 'V') && ~exist('length', 'var'), length = '02-nextword';    end
if strcmp(subjectname(1), 'A') && ~exist('length', 'var'), length = '02-10'; end

% this is the old default, added 20141111, to allow for a flexible
% (shorter) baseline for the auditory data: NOTE: consider recomputing the
% visual with the same baseline length
if ~exist('baseln', 'var'), baseln = -0.2; end;

% define parameters used for both doerf_main and doerf_parametric
% N.B.Neither wordtype / trialfunreflected in inputname therefore removed

inputdata  = ['meg_erf_allwords_' length];
axial      = '-ag';
planar     = '-pg';

if doerf_main
  mous_db_getdata(subjectname,inputdata,inrootdir);
    
  if ~isempty(condition)
    cfg = [];
    switch condition
      case 'mix'
        sel = find(ismember(data.trialinfo(:,2),[5 6 7 8])); % prior to july 1 2014 this was wrong
        cfg.trials = sel;
      case 'rc'
        sel = find(ismember(data.trialinfo(:,2),[1 2 3 4]));
        cfg.trials = sel;
    end
    data = ft_selectdata(cfg,data);
  end
  
  cfg2 = [];
  switch wordtype
    case 'first'
      sel = find(mod(data.trialinfo(:,2),2)==1);        % 1st words=odd numbered (For auditory mainly)
      cfg2.trials  = sel;
      outname1 = strcat(inputdata,'-firstword',axial);
      outname2 = strcat(inputdata,'-firstword',planar);
    case 'tar'
      sel = find(mod(data.trialinfo(:,2),2)==0);        % Target word = even numbered (for auditory mainly)
      cfg2.trials  = sel;
      outname1 = strcat(inputdata,'-target',axial);
      outname2 = strcat(inputdata,'-target',planar);
    case 'all'
      outname1 = strcat(inputdata,'-allwords',axial);  % erf_allwords_02-10-allwords-pg
      outname2 = strcat(inputdata,'-allwords',planar); % 1st allwords = word for preprocessing, 2nd = word for tlck.
    otherwise
      error('unknown wordtype specified');
  end
  data = ft_preprocessing(cfg2, data);
  
  [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data, baseln);
  
  % update outputdata filename
  if ~isempty(condition)
    outname1 = strcat(outname1(1:end-2),condition,axial);
    outname2 = strcat(outname2(1:end-2),condition,planar);
  end
  
  mous_db_putdata(subjectname, outname1, 'senWord_AG', 'seqWord_AG', outrootdir, 0);
  mous_db_putdata(subjectname, outname2, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG', 'stdev',outrootdir, 0);
end  % end doerf_main

=======

if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/MEG/';  end
if ~exist('inrootdir',        'var'), inrootdir        = rootdir;                     end
if ~exist('outrootdir',       'var'), outrootdir       = rootdir;                     end
if ~exist('doerf_main',       'var'), doerf_main       = 0;                           end
if ~exist('doerf_parametric', 'var'), doerf_parametric = 0;                           end
if ~exist('doerf_rc',         'var'), doerf_rc         = 0;                           end
if ~exist('doerf_mix',        'var'), doerf_mix        = 0;                           end
if ~exist('doerf_rc_onoff',   'var'), doerf_rc_onoff   = 0;                           end
if ~exist('doerf_auditory_chop', 'var'), doerf_auditory_chop = 0;                     end
if ~exist('doerf_auditory_chop_parametric', 'var'), doerf_auditory_chop_parametric = 0; end
if ~exist('doerf_auditory_chop_freq', 'var'), doerf_auditory_chop_freq = 0;           end
if ~exist('doerf_dependency', 'var'),     doerf_dependency     = 0;                   end
if ~exist('doerf_branchingdepth', 'var'), doerf_branchingdepth = 0;                   end
if ~exist('doerf_dependency_shortlong', 'var'), doerf_dependency_shortlong = 0;       end
if ~exist('doerf_speech_tlck', 'var'), doerf_speech_tlck = 0;                         end
if ~exist('doerf_speech_tlck_surrogate', 'var'), doerf_speech_tlck_surrogate = 0;                         end
if ~exist('doerf_speech_itc',  'var'), doerf_speech_itc  = 0;                         end
if ~exist('condition',        'var'), condition        = '';                          end
if ~exist('wordtype',         'var'), wordtype         = 'all';                       end
if ~exist('contrast',         'var'), contrast         = 'wordsent_parametric_blc';   end
if ~exist('doerf_earlylate',  'var'), doerf_earlylate  = 0; end

if strcmp(subjectname(1), 'V') && ~exist('length', 'var'), length = '02-nextword';    end
if strcmp(subjectname(1), 'A') && ~exist('length', 'var'), length = '02-10'; end

% this is the old default, added 20141111, to allow for a flexible
% (shorter) baseline for the auditory data: NOTE: consider recomputing the
% visual with the same baseline length
if ~exist('baseln', 'var'), baseln = -0.2; end;

% define parameters used for both doerf_main and doerf_parametric
% N.B.Neither wordtype / trialfunreflected in inputname therefore removed

inputdata  = ['meg_erf_allwords_' length];
axial      = '-ag';
planar     = '-pg';

if doerf_main
  mous_db_getdata(subjectname,inputdata,inrootdir);
    
  if ~isempty(condition)
    cfg = [];
    switch condition
      case 'mix'
        sel = find(ismember(data.trialinfo(:,2),[5 6 7 8])); % prior to july 1 2014 this was wrong
        cfg.trials = sel;
      case 'rc'
        sel = find(ismember(data.trialinfo(:,2),[1 2 3 4]));
        cfg.trials = sel;
    end
    data = ft_selectdata(cfg,data);
  end
  
  cfg2 = [];
  switch wordtype
    case 'first'
      sel = find(mod(data.trialinfo(:,2),2)==1);        % 1st words=odd numbered (For auditory mainly)
      cfg2.trials  = sel;
      outname1 = strcat(inputdata,'-firstword',axial);
      outname2 = strcat(inputdata,'-firstword',planar);
    case 'tar'
      sel = find(mod(data.trialinfo(:,2),2)==0);        % Target word = even numbered (for auditory mainly)
      cfg2.trials  = sel;
      outname1 = strcat(inputdata,'-target',axial);
      outname2 = strcat(inputdata,'-target',planar);
    case 'all'
      outname1 = strcat(inputdata,'-allwords',axial);  % erf_allwords_02-10-allwords-pg
      outname2 = strcat(inputdata,'-allwords',planar); % 1st allwords = word for preprocessing, 2nd = word for tlck.
    otherwise
      error('unknown wordtype specified');
  end
  data = ft_preprocessing(cfg2, data);
  
  [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data, baseln);
  
  % update outputdata filename
  if ~isempty(condition)
    outname1 = strcat(outname1(1:end-2),condition,axial);
    outname2 = strcat(outname2(1:end-2),condition,planar);
  end
  
  mous_db_putdata(subjectname, outname1, 'senWord_AG', 'seqWord_AG', outrootdir, 0);
  mous_db_putdata(subjectname, outname2, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG', 'stdev',outrootdir, 0);
end  % end doerf_main

>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
if doerf_parametric
  % FIXME: currently, parametric is done for all words (e.g., not only for
  % target words)
  mous_db_getdata(subjectname, inputdata, inrootdir);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
 
  % parametric with basline
  [tlck_sent, stat_sent, stat2_sent] = mous_makecontrast(data, contrast);  
  tlck = tlck_sent;
  stat = stat_sent;
  mous_db_putdata(subjectname, [inputdata,'_' contrast], 'tlck', 'stat', outrootdir);
  
  contrast = strrep(contrast, 'sent', 'seq');
  [tlck_seq,  stat_seq,  stat2_seq]  = mous_makecontrast(data, contrast);
  tlck = tlck_seq;
  stat = stat_seq;
  mous_db_putdata(subjectname, [inputdata,'_' contrast], 'tlck', 'stat', outrootdir);
  
  % parametric without basline 
  contrast = strrep(contrast, '_blc', '');
  [tlck_seq,  stat_seq,  stat2_seq]  = mous_makecontrast(data, contrast);
  tlck = tlck_seq;
  stat = stat_seq;
  mous_db_putdata(subjectname, [inputdata,'_' contrast], 'tlck', 'stat', outrootdir);

  contrast = strrep(contrast, 'seq', 'sent');
  [tlck_sent, stat_sent, stat2_sent] = mous_makecontrast(data, contrast); 
  tlck = tlck_sent;
  stat = stat_sent;
  mous_db_putdata(subjectname, [inputdata,'_' contrast], 'tlck', 'stat', outrootdir);
  
  
%   % convert to planar
%   cfg        = [];
%   cfg.method = 'distance';
%   neighbours = ft_prepare_neighbours(cfg, data);
%   
%   cfg              = [];
%   cfg.planarmethod = 'sincos';
%   cfg.neighbours   = neighbours;
%   data             = ft_megplanar(cfg, data);
%   [tlckp_sent, statp_sent, statp2_sent] = mous_makecontrast(data, 'wordsent_parametric_blc');
%   [tlckp_seq,  statp_seq,  statp2_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc');
%   
%   tlck = tlckp_sent;
%   stat = statp_sent;
%   mous_db_putdata(subjectname, [inputdata,'_wordsent_parametric_blc_planar'], 'tlck', 'stat', outrootdir, 1);
%   tlck = tlckp_seq;
%   stat = statp_seq;
%   mous_db_putdata(subjectname, [inputdata,'_wordseq_parametric_blc_planar'], 'tlck', 'stat', outrootdir, 1);
%   
%   % parametric without basline
%   [tlck_sent, stat_sent, stat2_sent] = mous_makecontrast(data, 'wordsent_parametric');
%   [tlck_seq,  stat_seq,  stat2_seq]  = mous_makecontrast(data, 'wordseq_parametric');
%   
%   tlck = tlck_sent;
%   stat = stat_sent;
%   mous_db_putdata(subjectname, [inputdata,'_wordsent_parametric_planar'], 'tlck', 'stat', outrootdir);
%   tlck = tlck_seq;
%   stat = stat_seq;
%   mous_db_putdata(subjectname, [inputdata,'_wordseq_parametric_planar'], 'tlck', 'stat', outrootdir);
end

if doerf_rc
  % FIXME: currently this only works for visual subjects
  mous_db_getdata(subjectname, inputdata, inrootdir);
  
  % select only sentences from RC condition
  sel        = find(ismember(data.trialinfo(:,2),[1 2]));
  cfg.trials = sel;
  data       = ft_selectdata(cfg, data);
  
  % determine the number per sentence from the original trial definition
  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  if ~strcmp(subjectname(1), 'V'),
    error('doerf_rc only works with visual subjects');
  end
  for k = 1:numel(filename)
    tmptrl = mous_defineTrial(filename{k}, 0.2, 'nextword', 'trialfun_visual_word');
    if k==1
      trl = tmptrl;
    else
      trl = cat(1,trl,tmptrl);
    end
  end
  trialinfo = trl(:,4:end);
  
  % column 1 contains the sentence indicator, the last column the ordinal
  % word
  sentid = unique(trialinfo(:,1));
  for k = 1:numel(sentid)
    nwords(k,1) = max(trialinfo(trialinfo(:,1)==sentid(k),5));
  end
  
  % add an extra column to the trialinfo that indicates the total number of
  % words
  ncol = size(data.trialinfo,2);
  for k = 1:numel(data.trial)
    data.trialinfo(k,ncol+1) = nwords(sentid==data.trialinfo(k,1));
  end
  
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 7 3 4]); % sentence, word, condition, total number of words
  [tlck_early, tlck_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlck_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_early'], 'tlck', outrootdir);
  tlck = tlck_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_late'], 'tlck', outrootdir);
  
  % convert to planar
  cfg        = [];
  cfg.method = 'distance';
  neighbours = ft_prepare_neighbours(cfg, data);
  
  cfg              = [];
  cfg.planarmethod = 'sincos';
  cfg.neighbours   = neighbours;
  data             = ft_megplanar(cfg, data);
  [tlckp_early, tlckp_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlckp_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_early_planar'], 'tlck', outrootdir);
  tlck = tlckp_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_late_planar'], 'tlck', outrootdir);
end

if doerf_mix
  % FIXME: currently this only works for visual subjects
  mous_db_getdata(subjectname, inputdata, inrootdir);
  
  % select only sentences from 'MIX' condition
  sel        = find(ismember(data.trialinfo(:,2),[5 6]));
  cfg.trials = sel;
  data       = ft_selectdata(cfg, data);
  
  % determine the number per sentence from the original trial definition
  % get the filename of the raw data
  filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

  if ~strcmp(subjectname(1), 'V'),
    error('doerf_rc only works with visual subjects');
  end
  for k = 1:numel(filename)
    tmptrl = mous_defineTrial(filename{k}, 0.2, 'nextword', 'trialfun_visual_word');
    if k==1
      trl = tmptrl;
    else
      trl = cat(1,trl,tmptrl);
    end
  end
  trialinfo = trl(:,4:end);
  
  % column 1 contains the sentence indicator, the last column the ordinal
  % word
  sentid = unique(trialinfo(:,1));
  for k = 1:numel(sentid)
    nwords(k,1) = max(trialinfo(trialinfo(:,1)==sentid(k),5));
  end
  
  % add an extra column to the trialinfo that indicates the total number of
  % words
  ncol = size(data.trialinfo,2);
  for k = 1:numel(data.trial)
    data.trialinfo(k,ncol+1) = nwords(sentid==data.trialinfo(k,1));
  end
  
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 7 3 4]); % sentence, word, condition, total number of words
  [tlck_early, tlck_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlck_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentMIX_early'], 'tlck', outrootdir);
  tlck = tlck_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentMIX_late'], 'tlck', outrootdir);
  
  % convert to planar
  cfg        = [];
  cfg.method = 'distance';
  neighbours = ft_prepare_neighbours(cfg, data);
  
  cfg              = [];
  cfg.planarmethod = 'sincos';
  cfg.neighbours   = neighbours;
  data             = ft_megplanar(cfg, data);
  [tlckp_early, tlckp_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlckp_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentMIX_early_planar'], 'tlck', outrootdir);
  tlck = tlckp_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentMIX_late_planar'], 'tlck', outrootdir);
end

if doerf_rc_onoff
  % FIXME: currently this only works for visual subjects
  mous_db_getdata(subjectname, inputdata, inrootdir);
  
  % select only sentences from RC condition
  sel        = find(ismember(data.trialinfo(:,2),[1 2]));
  cfg.trials = sel;
  data       = ft_selectdata(cfg, data);
  
  % match the stimuli so that the RC onset/offset can be recovered
  trialinfo = data.trialinfo; % make a local copy
  sentid    = unique(trialinfo(:,6));
  
  load mous_stimuli;
  rc_onset = [stimuli(sentid).RConsetword];
  mc_cont  = [stimuli(sentid).MCcontinuationword];
  nwords   = mc_cont-rc_onset;
  
  for k = 1:numel(sentid)
    trialinfo(trialinfo(:,6)==sentid(k),7) = nwords(k); % add a column to keep track of the length of the relative clause
    trialinfo(trialinfo(:,6)==sentid(k),8) = rc_onset(k);
    trialinfo(trialinfo(:,6)==sentid(k),9) = mc_cont(k);
  end
  
  sel = false(size(trialinfo,1),1);
  for k = 1:numel(sentid)
    tmp = find(trialinfo(:,6)==sentid(k)&(trialinfo(:,5)==rc_onset(k)|trialinfo(:,5)==mc_cont(k)));
    if ~isempty(tmp)
      sel(tmp)=true;
    end
  end
  data.trialinfo = trialinfo;
  
  cfg = [];
  cfg.trials = find(sel);
  data       = ft_selectdata(cfg, data);
  
  
  
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 7 3 4]); % sentence, word, condition, total number of words
  [tlck_early, tlck_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlck_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_early'], 'tlck', outrootdir);
  tlck = tlck_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_late'], 'tlck', outrootdir);
  
  % convert to planar
  cfg        = [];
  cfg.method = 'distance';
  neighbours = ft_prepare_neighbours(cfg, data);
  
  cfg              = [];
  cfg.planarmethod = 'sincos';
  cfg.neighbours   = neighbours;
  data             = ft_megplanar(cfg, data);
  [tlckp_early, tlckp_late] = mous_makecontrast(data, 'early-late');
  
  tlck = tlckp_early;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_early_planar'], 'tlck', outrootdir);
  tlck = tlckp_late;
  mous_db_putdata(subjectname, [inputdata,'_wordsentRC_late_planar'], 'tlck', outrootdir);
end

if doerf_dependency
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [trialinfo,b,n,uT,ix] = extract_dependency(data.trialinfo);
  nsmp = cellfun(@numel, data.time);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % stratify the trials according to matching numbers in the ordinal word
  % position histograms for the sentences versus the equivalent sequences
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % HARDCODED ASSUMPTION: trialinfo(:,5) is ordinal word position,
  % trialinfo(:,7) is dependency indicator
  sel    = cell(numel(uT),size(n,2));
  numsmp = sel;
  for k = 1:numel(uT)
    for m = 1:size(n,2)
      sel{k,m}    = find(trialinfo(:,5)==m & trialinfo(:,7)==uT(k));
      numsmp{k,m} = nsmp(sel{k,m});
    end
  end
  N = numel(uT)/2;
  for k = 1:N
    for m = 1:size(n,2)
      n_tmp = min(numel(sel{k,m}), numel(sel{k+N,m}));
      [numsmp{k,  m},jx1] = sort(numsmp{k,  m},'descend');
      [numsmp{k+N,m},jx2] = sort(numsmp{k+N,m},'descend');
      sel{k,  m} = sel{k,  m}(jx1);
      sel{k+N,m} = sel{k+N,m}(jx2);
      u1 = unique(numsmp{k,m});
      u2 = unique(numsmp{k+N,m});
      for m1 = 1:numel(u1)
        tmp  = find(numsmp{k,m}==u1(m1));
        tmp2 = tmp(randperm(numel(tmp)));
        sel{k,  m}(tmp) = sel{k,  m}(tmp2);
      end
      for m2 = 1:numel(u2)
        tmp  = find(numsmp{k+N,m}==u2(m2));
        tmp2 = tmp(randperm(numel(tmp)));
        sel{k+N,m}(tmp) = sel{k+N,m}(tmp2);
      end
      sel1  = sel{k,  m};%(randperm(numel(sel{k,  m})));
      sel2  = sel{k+N,m};%(randperm(numel(sel{k+N,m})));
      [sel{k,  m},ix1] = sort(sel1(1:n_tmp));
      [sel{k+N,m},ix2] = sort(sel2(1:n_tmp));
      numsmp{k,  m} = numsmp{k,  m}(ix1);
      numsmp{k+N,m} = numsmp{k+N,m}(ix2);
    end
  end
  sel   = sel(:);
  n_sel = cellfun(@numel, sel);
  sel   = sel(n_sel>0);
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sort(cat(1,sel{:})));
  [trialinfo,b,n,uT,ix] = extract_dependency(data.trialinfo);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfg                = [];
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.vartrllength   = 2;
  cfg.channel        = 'MEG';
  
  cfg.trials = find(ismember(trialinfo(:,end),[1 5]));
  tlck(1)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[2 6]));
  tlck(2)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[4 5 6]));
  tlck(3)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[8 40]));
  tlck(4)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[16 48]));
  tlck(5)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[32 40 48]));
  tlck(6)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:6
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_dependency_sent'], 'tlck', 'tlck_p', outrootdir);
  clear tlck tlck_p;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % do a further stratification, to be able to compare [1 5] vs [2 6]
  % directly
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  sel    = cell(4,size(n,2));
  numsmp = sel;
  nsmp   = cellfun(@numel, data.time);
  for m = 1:size(n,2)
    sel{1,m}    = find(trialinfo(:,5)==m & ismember(trialinfo(:,7),[1 5]));
    numsmp{1,m} = nsmp(sel{1,m});
    sel{2,m}    = find(trialinfo(:,5)==m & ismember(trialinfo(:,7),[2 6]));
    numsmp{1,m} = nsmp(sel{2,m});
    sel{3,m}    = find(trialinfo(:,5)==m & ismember(trialinfo(:,7),[8 40]));
    numsmp{1,m} = nsmp(sel{3,m});
    sel{4,m}    = find(trialinfo(:,5)==m & ismember(trialinfo(:,7),[16 48]));
    numsmp{1,m} = nsmp(sel{4,m});
  end
  for m = 1:size(n,2)
    n_tmp = min([numel(sel{1,m}), numel(sel{2,m}), numel(sel{3,m}), numel(sel{4,m})]);
    sel{1,m} = sel{1,m}(randperm(numel(sel{1,m})));
    sel{2,m} = sel{2,m}(randperm(numel(sel{2,m})));
    sel{3,m} = sel{3,m}(randperm(numel(sel{3,m})));
    sel{4,m} = sel{4,m}(randperm(numel(sel{4,m})));
    
    sel{1,m} = sort(sel{1,m}(1:n_tmp));
    sel{2,m} = sort(sel{2,m}(1:n_tmp));
    sel{3,m} = sort(sel{3,m}(1:n_tmp));
    sel{4,m} = sort(sel{4,m}(1:n_tmp));
    
  end
  sel   = sel(:);
  n_sel = cellfun(@numel, sel);
  sel   = sel(n_sel>0);
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sort(cat(1,sel{:})));
  [trialinfo,b,n,uT,ix] = extract_dependency(data.trialinfo);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfg                = [];
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.vartrllength   = 2;
  cfg.channel        = 'MEG';
  
  cfg.trials = find(ismember(trialinfo(:,end),[1 5]));
  tlck(1)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[2 6]));
  tlck(2)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[8 40]));
  tlck(3)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = find(ismember(trialinfo(:,end),[16 48]));
  tlck(4)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:4
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_dependency_sent_doublestratified'], 'tlck', 'tlck_p', outrootdir);
end
<<<<<<< HEAD

if doerf_dependency_shortlong
  % split the sentence words according to the length of the dependency
  % jump, for the 'backward' pointing words, i.e. those words that resolve
  % a syntactic relationship
  
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [trialinfo,b,n,uT,ix,depjump] = extract_dependency(data.trialinfo);
  nsmp = cellfun(@numel, data.time);
  
  % the negative value depjump are pointing back.
  sel = find(depjump==-1 | depjump==-2 | depjump<=-3);
  
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sel);
  [trialinfo,b,n,uT,ix,depjump,lexfreq] = extract_dependency(data.trialinfo);
  
  % treat words that have been chopped up by an artifact as a single
  % occurrence, not to loose too much data
  [U, i1, i2] = unique(trialinfo(:,[5 6]), 'rows');
  U_depjump   = depjump(i1);
  U_lexfreq   = lexfreq(i1);
  
  sel1 = find(U_depjump==-1|U_depjump==-2); 
  sel2 = find(U_depjump<=-3); 
  
  % the ordinal word position is coded in the 5th column of trialinfo,
  % stratify:
  X = [U(:,1) log(U_lexfreq)];
  
  cfg = [];
  cfg.equalbinavg = 'no';
  cfg.binedges{1} = 0.5:1:15.5;
  cfg.binedges{2} = linspace(-4,11,6);
  out = ft_stratify(cfg, X(sel1,:)', X(sel2,:)');
  
  cfg.binedges = 0.5:1:15.5;
  out2 = ft_stratify(cfg, X(sel1,1)', X(sel2,1)'); % stratification based on word position alone
  
  sel1a = sel1(isfinite(out{1}(1,:)));
  sel2a = sel2(isfinite(out{2}(1,:)));
  sel1b = sel1(isfinite(out2{1}(1,:)));
  sel2b = sel2(isfinite(out2{2}(1,:)));
  
  sel1a = find(ismember(trialinfo(:,[5 6]),U(sel1a,:),'rows'));
  sel2a = find(ismember(trialinfo(:,[5 6]),U(sel2a,:),'rows'));
  sel1b = find(ismember(trialinfo(:,[5 6]),U(sel1b,:),'rows'));
  sel2b = find(ismember(trialinfo(:,[5 6]),U(sel2b,:),'rows'));
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  cfg                = [];
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.vartrllength   = 2;
  cfg.channel        = 'MEG';
 
  cfg.trials = sel1a;
  tlck(1)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel2a;
  tlck(2)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel1b;
  tlck(3)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel2b;
  tlck(4)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  neighbours1 = ft_prepare_neighbours(cfg_neighb, tlck(1));
  
  load('ctf275_neighb');
  cfgplanar.neighbours   = neighbours;
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:numel(tlck)
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_dependency_shortlong_sent'], 'tlck', 'tlck_p', 'out', 'out2', outrootdir);
  clear tlck tlck_p;
end

if doerf_branchingdepth
  % split the sentence words according to the branching depth
  
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [trialinfo,b,n,uT,ix,depjump] = extract_dependency(data.trialinfo);
   
  % the negative value depjump are pointing back.
  sel = find(ismember(trialinfo(:,2), [1 2 5 6]) & trialinfo(:,6)<500);
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sel);
  [trialinfo,b,n,uT,ix,depjump,lexfreq] = extract_dependency(data.trialinfo);
   
  % treat words that have been chopped up by an artifact as a single
  % occurrence, not to loose too much data
  [U, i1, i2] = unique(trialinfo(:,[5 6]), 'rows');
  U_left      = trialinfo(i1,9);
  U_right     = trialinfo(i1,8);
  U_lexfreq   = lexfreq(i1);
   
  sel1 = find(U_right<-1);
  sel2 = find(U_right==-1);
  sel3 = find(U_right==0);
  sel4 = find(U_left>1);
  sel5 = find(U_left==1);
  sel6 = find(U_left==0);

  % the ordinal word position is coded in the 5th column of trialinfo,
  % which is the first column in U
  % stratify:
  X = [U(:,1) log(U_lexfreq)];
   
  cfg = [];
  cfg.equalbinavg = 'no';
  cfg.binedges{1} = 0.5:2:15.5;
  cfg.binedges{2} = linspace(-4,11,6);
  out_right = ft_stratify(cfg, X(sel1,:)', X(sel2,:)', X(sel3,:)');
  out_left  = ft_stratify(cfg, X(sel4,:)', X(sel5,:)', X(sel6,:)');
=======

if doerf_dependency_shortlong
  % split the sentence words according to the length of the dependency
  % jump, for the 'backward' pointing words, i.e. those words that resolve
  % a syntactic relationship
  
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [trialinfo,b,n,uT,ix,depjump] = extract_dependency(data.trialinfo);
  nsmp = cellfun(@numel, data.time);
  
  % the negative value depjump are pointing back.
  sel = find(depjump==-1 | depjump==-2 | depjump<=-3);
  
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sel);
  [trialinfo,b,n,uT,ix,depjump,lexfreq] = extract_dependency(data.trialinfo);
  
  % treat words that have been chopped up by an artifact as a single
  % occurrence, not to loose too much data
  [U, i1, i2] = unique(trialinfo(:,[5 6]), 'rows');
  U_depjump   = depjump(i1);
  U_lexfreq   = lexfreq(i1);
  
  sel1 = find(U_depjump==-1|U_depjump==-2); 
  sel2 = find(U_depjump<=-3); 
  
  % the ordinal word position is coded in the 5th column of trialinfo,
  % stratify:
  X = [U(:,1) log(U_lexfreq)];
  
  cfg = [];
  cfg.equalbinavg = 'no';
  cfg.binedges{1} = 0.5:1:15.5;
  cfg.binedges{2} = linspace(-4,11,6);
  out = ft_stratify(cfg, X(sel1,:)', X(sel2,:)');
  
  cfg.binedges = 0.5:1:15.5;
  out2 = ft_stratify(cfg, X(sel1,1)', X(sel2,1)'); % stratification based on word position alone
  
  sel1a = sel1(isfinite(out{1}(1,:)));
  sel2a = sel2(isfinite(out{2}(1,:)));
  sel1b = sel1(isfinite(out2{1}(1,:)));
  sel2b = sel2(isfinite(out2{2}(1,:)));
  
  sel1a = find(ismember(trialinfo(:,[5 6]),U(sel1a,:),'rows'));
  sel2a = find(ismember(trialinfo(:,[5 6]),U(sel2a,:),'rows'));
  sel1b = find(ismember(trialinfo(:,[5 6]),U(sel1b,:),'rows'));
  sel2b = find(ismember(trialinfo(:,[5 6]),U(sel2b,:),'rows'));
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  cfg                = [];
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.vartrllength   = 2;
  cfg.channel        = 'MEG';
 
  cfg.trials = sel1a;
  tlck(1)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel2a;
  tlck(2)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel1b;
  tlck(3)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel2b;
  tlck(4)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  neighbours1 = ft_prepare_neighbours(cfg_neighb, tlck(1));
  
  load('ctf275_neighb');
  cfgplanar.neighbours   = neighbours;
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:numel(tlck)
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_dependency_shortlong_sent'], 'tlck', 'tlck_p', 'out', 'out2', outrootdir);
  clear tlck tlck_p;
end

if doerf_branchingdepth
  % split the sentence words according to the branching depth
  
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [trialinfo,b,n,uT,ix,depjump] = extract_dependency(data.trialinfo);
   
  % the negative value depjump are pointing back.
  sel = find(ismember(trialinfo(:,2), [1 2 5 6]) & trialinfo(:,6)<500);
  dataorig = data;
  data     = ft_selectdata(dataorig, 'rpt', sel);
  [trialinfo,b,n,uT,ix,depjump,lexfreq] = extract_dependency(data.trialinfo);
   
  % treat words that have been chopped up by an artifact as a single
  % occurrence, not to loose too much data
  [U, i1, i2] = unique(trialinfo(:,[5 6]), 'rows');
  U_left      = trialinfo(i1,9);
  U_right     = trialinfo(i1,8);
  U_lexfreq   = lexfreq(i1);
   
  sel1 = find(U_right<-1);
  sel2 = find(U_right==-1);
  sel3 = find(U_right==0);
  sel4 = find(U_left>1);
  sel5 = find(U_left==1);
  sel6 = find(U_left==0);

  % the ordinal word position is coded in the 5th column of trialinfo,
  % which is the first column in U
  % stratify:
  X = [U(:,1) log(U_lexfreq)];
   
  cfg = [];
  cfg.equalbinavg = 'no';
  cfg.binedges{1} = 0.5:2:15.5;
  cfg.binedges{2} = linspace(-4,11,6);
  out_right = ft_stratify(cfg, X(sel1,:)', X(sel2,:)', X(sel3,:)');
  out_left  = ft_stratify(cfg, X(sel4,:)', X(sel5,:)', X(sel6,:)');

  sel1a = sel1(isfinite(out_right{1}(1,:)));
  sel2a = sel2(isfinite(out_right{2}(1,:)));
  sel3a = sel3(isfinite(out_right{3}(1,:)));
  sel4a = sel4(isfinite(out_left{1}(1,:)));
  sel5a = sel5(isfinite(out_left{2}(1,:)));
  sel6a = sel6(isfinite(out_left{3}(1,:)));

  sel1a = find(ismember(trialinfo(:,[5 6]),U(sel1a,:),'rows'));
  sel2a = find(ismember(trialinfo(:,[5 6]),U(sel2a,:),'rows'));
  sel3a = find(ismember(trialinfo(:,[5 6]),U(sel3a,:),'rows'));
  sel4a = find(ismember(trialinfo(:,[5 6]),U(sel4a,:),'rows'));
  sel5a = find(ismember(trialinfo(:,[5 6]),U(sel5a,:),'rows'));
  sel6a = find(ismember(trialinfo(:,[5 6]),U(sel6a,:),'rows'));
>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78

  sel1a = sel1(isfinite(out_right{1}(1,:)));
  sel2a = sel2(isfinite(out_right{2}(1,:)));
  sel3a = sel3(isfinite(out_right{3}(1,:)));
  sel4a = sel4(isfinite(out_left{1}(1,:)));
  sel5a = sel5(isfinite(out_left{2}(1,:)));
  sel6a = sel6(isfinite(out_left{3}(1,:)));

<<<<<<< HEAD
  sel1a = find(ismember(trialinfo(:,[5 6]),U(sel1a,:),'rows'));
  sel2a = find(ismember(trialinfo(:,[5 6]),U(sel2a,:),'rows'));
  sel3a = find(ismember(trialinfo(:,[5 6]),U(sel3a,:),'rows'));
  sel4a = find(ismember(trialinfo(:,[5 6]),U(sel4a,:),'rows'));
  sel5a = find(ismember(trialinfo(:,[5 6]),U(sel5a,:),'rows'));
  sel6a = find(ismember(trialinfo(:,[5 6]),U(sel6a,:),'rows'));


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=======
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the axial gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
  cfg                = [];
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.vartrllength   = 2;
  cfg.channel        = 'MEG';
 
  cfg.trials = sel1a; %right branching depth <-1
  tlck(1)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel2a;
  tlck(2)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel3a;
  tlck(3)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  cfg.trials = sel4a; %left branching depth == >1
  tlck(4)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
<<<<<<< HEAD

  cfg.trials = sel5a; %left branching depth
  tlck(5)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);

  cfg.trials = sel6a; %left branching depth
  tlck(6)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  neighbours1 = ft_prepare_neighbours(cfg_neighb, tlck(1));
  
  load('ctf275_neighb');
  cfgplanar.neighbours   = neighbours;
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:numel(tlck)
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_branchingdepth_sent'], 'tlck', 'tlck_p', 'out_left', 'out_right', outrootdir);
  clear tlck tlck_p;
end


if doerf_auditory_chop
  % this section performs a chopping up of the auditory sentences into the
  % individual words: EXPERIMENTAL CODE BY JM
  %if strcmp(subjectname(1), 'V')
  %  error('this only works with audio subjects');
  %end
  
  tlck = mous_auditory_chop(subjectname);
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'template';'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, tlck);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  tlck_p = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck)));
  
  mous_db_putdata(subjectname, 'meg_erf_chopped', 'tlck', 'tlck_p', outrootdir);
end

if doerf_auditory_chop_parametric
  % this section performs a chopping up of the auditory sentences into the
  % individual words: EXPERIMENTAL CODE BY JM, and does a parametric fit
  %if strcmp(subjectname(1), 'V')
  %  error('this only works with audio subjects');
  %end
  
  tlck = mous_auditory_chop_parametric(subjectname);
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'template';%'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, tlck);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  tlck_p = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck)));
  
  [~, stat] = mous_makecontrast(tlck_p, 'wordsent_parametric');
  
  mous_db_putdata(subjectname, 'meg_erf_chopped_parametric', 'tlck', 'tlck_p', 'stat', outrootdir);
end

=======

  cfg.trials = sel5a; %left branching depth
  tlck(5)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);

  cfg.trials = sel6a; %left branching depth
  tlck(6)    = ft_selectdata(ft_timelockanalysis(cfg, data), 'toilim', [-0.1 0.6]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % compute the planar gradient ERFs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'distance';
  cfg_neighb.neighbourdist = 3;
  neighbours1 = ft_prepare_neighbours(cfg_neighb, tlck(1));
  
  load('ctf275_neighb');
  cfgplanar.neighbours   = neighbours;
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  
  for k = 1:numel(tlck)
    tlck_p(k) = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck(k))));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % save the results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  mous_db_putdata(subjectname, [inputdata,'_branchingdepth_sent'], 'tlck', 'tlck_p', 'out_left', 'out_right', outrootdir);
  clear tlck tlck_p;
end


if doerf_auditory_chop
  % this section performs a chopping up of the auditory sentences into the
  % individual words: EXPERIMENTAL CODE BY JM
  %if strcmp(subjectname(1), 'V')
  %  error('this only works with audio subjects');
  %end
  
  tlck = mous_auditory_chop(subjectname,condition);
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'template';'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, tlck);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  tlck_p = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck)));
  
  mous_db_putdata(subjectname, 'meg_erf_chopped', 'tlck', 'tlck_p', outrootdir);
end

if doerf_auditory_chop_parametric
  % this section performs a chopping up of the auditory sentences into the
  % individual words: EXPERIMENTAL CODE BY JM, and does a parametric fit
  %if strcmp(subjectname(1), 'V')
  %  error('this only works with audio subjects');
  %end
  
  tlck = mous_auditory_chop_parametric(subjectname);
  
  cfgplanar              = [];
  cfgplanar.planarmethod = 'sincos';
  cfg_neighb.method      = 'template';%'distance';
  cfg_neighb.neighbourdist = 3;
  cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, tlck);
  
  cfgbaseline          = [];
  cfgbaseline.baseline = [-0.1 0];
  cfgbaseline.channel  = 'MEG';
  tlck_p = ft_combineplanar([], ft_timelockbaseline(cfgbaseline, ft_megplanar(cfgplanar, tlck)));
  
  [~, stat] = mous_makecontrast(tlck_p, 'wordsent_parametric');
  
  mous_db_putdata(subjectname, 'meg_erf_chopped_parametric', 'tlck', 'tlck_p', 'stat', outrootdir);
end

>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
if doerf_auditory_chop_freq
  % this section performs a chopping up of the auditory sentences into the
  % individual words: EXPERIMENTAL CODE BY JM, and does a parametric fit
  %if strcmp(subjectname(1), 'V')
  %  error('this only works with audio subjects');
  %end
  if isempty(condition)
    condition = 'sent';
  end
  
  freq = mous_auditory_chop_freq(subjectname, condition);
  mous_db_putdata(subjectname, ['meg_erf_chopped_freq_',condition], 'freq', outrootdir);
end
<<<<<<< HEAD

if doerf_speech_tlck
  [tlck, tlck_sent, tlck_seq] = mous_neuralspeechtimelocked_sensor(subjectname, 'up');
  mous_db_putdata(subjectname, 'meg_erf_speech_tlck' ,'tlck', 'tlck_sent', 'tlck_seq', outrootdir);
end

if doerf_speech_itc
  [freq, freq_sent, freq_seq] = mous_neuralspeechtimelockeditc_sensor(subjectname, 'up');
  mous_db_putdata(subjectname, 'meg_erf_speech_itc' ,'freq', 'freq_sent', 'freq_seq', outrootdir);
end
=======

if doerf_speech_tlck
  [tlck, tlck_sent, tlck_seq, tlck_seq2, freq] = mous_neuralspeechtimelocked_sensor(subjectname, 'up');
  mous_db_putdata(subjectname, 'meg_erf_speech_tlck' ,'tlck', 'tlck_sent', 'tlck_seq', 'tlck_seq2', 'freq', outrootdir,1);
end

if doerf_speech_tlck_surrogate
  [coh, pow] = mous_neuralspeechtimelocked_sensor_surrogate(subjectname, [], 0.1);
  mous_db_putdata(subjectname, 'meg_erf_speech_tlck_surrogate' ,'coh', 'pow', outrootdir,0);
end

if doerf_speech_itc
  [freq, freq_sent, freq_seq] = mous_neuralspeechtimelockeditc_sensor(subjectname, 'up');
  mous_db_putdata(subjectname, 'meg_erf_speech_itc' ,'freq', 'freq_sent', 'freq_seq', outrootdir);
end

if doerf_earlylate
  mous_db_getdata(subjectname, inputdata, inrootdir);
  [early, late] = extract_earlylate(data.trialinfo);
  
  tmpcfg = [];
  tmpcfg.trials  = early;
  data1 = ft_selectdata(tmpcfg, data);
  
  tmpcfg.trials = late;
  data2 = ft_selectdata(tmpcfg, data);
  clear data;
  
  tmpcfg = [];
  tmpcfg.latency = [-0.2 0.6];
  
  sent1 = find(ismember(data1.trialinfo(:,2),[1 2 5 6]));
  seq1  = find(ismember(data1.trialinfo(:,2),[3 4 7 8]));
  sent2 = find(ismember(data2.trialinfo(:,2),[1 2 5 6]));
  seq2  = find(ismember(data2.trialinfo(:,2),[3 4 7 8]));
  
  
  cfg = [];
  cfg.vartrllength = 2;
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-inf 0];
  cfg.channel = 'MEG';
  cfg.trials = sent1;
  tlck = ft_selectdata(tmpcfg, ft_timelockanalysis(cfg, data1));
  mous_db_putdata(subjectname, [inputdata,'_sentearly'], 'tlck', outrootdir);
  cfg.trials = sent2;
  tlck = ft_selectdata(tmpcfg, ft_timelockanalysis(cfg, data2));
  mous_db_putdata(subjectname, [inputdata,'_sentlate'], 'tlck', outrootdir);
  
  cfg.trials = seq1;
  tlck = ft_selectdata(tmpcfg, ft_timelockanalysis(cfg, data1));
  mous_db_putdata(subjectname, [inputdata,'_seqearly'], 'tlck', outrootdir);
  cfg.trials = seq2;
  tlck = ft_selectdata(tmpcfg, ft_timelockanalysis(cfg, data2));
  mous_db_putdata(subjectname, [inputdata,'_seqlate'], 'tlck', outrootdir);
  
  
  
end

>>>>>>> dd6db585ccc06de5c71b1792da002f9a28c51a78
