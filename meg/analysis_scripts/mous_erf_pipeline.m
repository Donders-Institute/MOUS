% mous_erf_pipeline
%  NL - major changes on 17 March 2014
% For this script, specify the following:
% 1. rootdir
% 2. doerf_main = 1?
% 3. doerf_parametric = 1?
% 4. wordtype = 'tar', 'first', 'all
% 5. condition = 'mix','rc'; OR don't specify anything (that's also okay)


% NOTE 
% VISUAL SUBJECTS: preprocessed data is in /project/3011020.09/MEG/'
%                  ERF data is in /project/3011020.09/annhul/'
% AUDITORY SUBJS:  both are both in /project/3011020.09/annhul/'

if ~exist('rootdir', 'var')           rootdir = '/project/3011020.09/MEG/';  end
if ~exist('doerf_main', 'var')        doerf_main = 0;                       end
if ~exist('doerf_parametric', 'var')  doerf_parametric = 0;                 end
if ~exist('length','var')             length = '02-10';                     end

% define parameters used for both doerf_main and doerf_parametric
% N.B.Neither wordtype / trialfunreflected in inputname therefore removed
  
inputdata  = ['meg_erf_allwords_' length];
axial = '-ag';
planar = '-pg';
  
if doerf_main
  % files for input/output are divided between MEG and annhul
  if strcmp(subjectname(1),'V')
    mous_db_getdata(subjectname,inputdata,'/project/3011020.09/MEG/'); 
  elseif strcmp(subjectname(1),'A')
    mous_db_getdata(subjectname,inputdata,rootdir);
  end
  
  if exist('condition','var')
    cfg = [];
    switch condition
      case 'mix'
        sel = find(ismember(data.trialinfo(:,2),[1 2 3 4]));
        cfg.trials = sel;
      case 'rc'
        sel = find(ismember(data.trialinfo(:,2),[5 6 7 8]));
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
    otherwise 'all'
      outname1 = strcat(inputdata,'-allwords',axial);  % erf_allwords_02-10-allwords-pg
      outname1 = strcat(inputdata,'-allwords',planar); % 1st allwords = word for preprocessing, 2nd = word for tlck.
  end
  data = ft_preprocessing(cfg2, data);

  [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data);
  
  if exist('condition','var') % update outputdata filename
    outname1 = strcat(outname1(1:end-2),condition,axial);
    outname2 = strcat(outname2(1:end-2),condition,planar);
  end 
    
  mous_db_putdata(subjectname, outname1, 'senWord_AG', 'seqWord_AG',rootdir);
  mous_db_putdata(subjectname, outname2, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG', 'stdev',rootdir);
end  % end doerf_main

if doerf_parametric
  % FIXME: currently, parametric is done for all words (e.g., not only for
  % target words)
  mous_db_getdata(subjectname, inputdata, rootdir);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
  [tlck_sent, stat_sent, stat2_sent] = mous_makecontrast(data, 'wordsent_parametric_blc');
  [tlck_seq,  stat_seq,  stat2_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc');
  
  tlck = tlck_sent;
  stat = stat_sent;
  mous_db_putdata(subjectname, [inputdata,'_wordsent_parametric_blc'], 'tlck', 'stat', rootdir);
  tlck = tlck_seq;
  stat = stat_seq;
  mous_db_putdata(subjectname, [inputdata,'_wordseq_parametric_blc'], 'tlck', 'stat', rootdir);
 
  % convert to planar
  cfg = [];
  cfg.method = 'distance';
  neighbours = ft_prepare_neighbours(cfg, data);
  cfg = [];
  cfg.planarmethod = 'sincos';
  cfg.neighbours   = neighbours;
  data             = ft_megplanar(cfg, data);
  [tlckp_sent, statp_sent, statp2_sent] = mous_makecontrast(data, 'wordsent_parametric_blc');
  [tlckp_seq,  statp_seq,  statp2_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc');
  
  tlck = tlckp_sent;
  stat = statp_sent;
  mous_db_putdata(subjectname, [inputdata,'_wordsent_parametric_blc_planar'], 'tlck', 'stat', rootdir);
  tlck = tlckp_seq;
  stat = statp_seq;
  mous_db_putdata(subjectname, [inputdata,'_wordseq_parametric_blc_planar'], 'tlck', 'stat', rootdir);
end
