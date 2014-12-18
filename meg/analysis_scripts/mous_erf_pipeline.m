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

if ~exist('rootdir',          'var'), rootdir          = '/project/3011020.09/MEG/';  end
if ~exist('inrootdir',        'var'), inrootdir        = rootdir;  end
if ~exist('outrootdir',       'var'), outrootdir       = rootdir;  end
if ~exist('doerf_main',       'var'), doerf_main       = 0;                           end
if ~exist('doerf_parametric', 'var'), doerf_parametric = 0;                           end
if ~exist('doerf_rc',         'var'), doerf_rc         = 0;                           end
if ~exist('doerf_mix',        'var'), doerf_mix        = 0;                           end
if ~exist('doerf_rc_onoff',   'var'), doerf_rc_onoff   = 0;                           end
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