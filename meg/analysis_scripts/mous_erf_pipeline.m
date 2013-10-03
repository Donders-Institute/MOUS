% Use Annika's list if subjectname is not defined in the workspace, else
% use the defined subjectname: this allows for use with qsub

if ~exist('subjectname', 'var')
  load MOUS/meg/subjects_OK_20130613.mat
elseif ~iscell(subjectname)
  subj = {subjectname};
else
  subj = subjectname;
end

if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/MEG';
end

if ~exist('doerf_main', 'var')
  doerf_main = 0;
end

if ~exist('doerf_parametric', 'var')
  doerf_parametric = 0;
end

if doerf_main
  % FIXME this is still a hybrid Annika/JM style
  if ~exist('inputdata', 'var')
    length   = '02-1'; %means -0.2 to 1 sec
    wordType = 'all'; 
    trialfun = 'visual_word';
    inputdata  = ['meg_processed_{_preProcERF' trialfun '_' wordType '_' length 'ds}'];
    outputdata = ['meg_processed_{_erf_' trialfun '_' wordType '_' length 'ds'];
    outname1   = strcat(outputdata, '-ag}');
    outname2   = strcat(outputdata, '-pg}');
  end

  if  ~exist('outputdata', 'var')
    error('you need to specify the name of the file that will contain the output data');
  end
  
  if ~exist('outname1', 'var')
    outname1 = strcat(outputdata, '-ag');
    outname2 = strcat(outputdata, '-pg');
  end

  for k = 1:numel(subj)
    subjectname = subj{k};
    
    % get the preprocessed data from the database
    %   tmp  = mous_db_getdata(subjectname, inputdata);
    %   if iscell(tmp)
    %     data = tmp{1};
    %   else
    %     data = tmp;
    %   end
    %   clear tmp;
    load(fullfile(rootdir,subjectname,'erf',[subjectname,inputdata(4:end)]));
    
    
    % auditory data is apparently used, select whether to use the first
    % words, or the targets: first words are odd numbered, targets are even
    % numbered
    if ~isempty(strfind(inputdata, 'auditory'))
      % use the first words here
      %sel = find(mod(data.trialinfo(:,2),2)==1);
      sel = find(mod(data.trialinfo(:,2),2)==0);
      cfg.trials = sel;
      data = ft_preprocessing(cfg, data);
    end
    [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data);
    
    mous_db_putdata(subjectname, outname1, 'senWord_AG', 'seqWord_AG',rootdir);
    mous_db_putdata(subjectname, outname2, 'senWord_PG', 'seqWord_PG', 'senWord_CPG', 'seqWord_CPG', 'stdev',rootdir);
  end

end

if doerf_parametric
  if ~exist('suffix', 'var')
    error('you need to specify the file suffix for the preprocessed data');
  end
  mous_db_getdata(subjectname, suffix, rootdir);
  
  % move around the columns in the trialinfo field so that the condition
  % trigger ends up in the third column and the word ordinal indicator in
  % the second
  % FIXME this is hard coded expected based on XXX_erf_allwords_01-10
  data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
  [tlck_sent, stat_sent, stat2_sent] = mous_makecontrast(data, 'wordsent_parametric_blc');
  [tlck_seq,  stat_seq,  stat2_seq]  = mous_makecontrast(data, 'wordseq_parametric_blc');
  
  tlck = tlck_sent;
  stat = stat_sent;
  mous_db_putdata(subjectname, [suffix,'_wordsent_parametric_blc'], 'tlck', 'stat', rootdir);
  tlck = tlck_seq;
  stat = stat_seq;
  mous_db_putdata(subjectname, [suffix,'_wordseq_parametric_blc'], 'tlck', 'stat', rootdir);
 
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
  mous_db_putdata(subjectname, [suffix,'_wordsent_parametric_blc_planar'], 'tlck', 'stat', rootdir);
  tlck = tlckp_seq;
  stat = statp_seq;
  mous_db_putdata(subjectname, [suffix,'_wordseq_parametric_blc_planar'], 'tlck', 'stat', rootdir);

end
