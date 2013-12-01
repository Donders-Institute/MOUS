
if ~exist('subjectname', 'var')
  error('you should specify a subjectname when running mous_preprocessing_pipeline');
end

if ~exist('prestim',      'var'), prestim      = 0.2; end
if ~exist('poststim',     'var'), poststim     = 1.0; end
if ~exist('resamplefs',   'var'), resamplefs   = 300; end
if ~exist('analysisType', 'var'), analysisType = 'ERF'; end % can be 'TFR'
if ~exist('trialfun',     'var'), 
  if strcmp(subjectname(1),'V')
    trialfun = 'visual_word';
  else
    trialfun = 'auditory_word';
  end
end

%trialfun =  'auditory_word';   
%            'auditory_sentence' 
%            'auditory_word';     % onset of speech for first word and target word
%            'visual_word';       % onset of each word (but not fixation cross)
%            'visual_sentence';   % onset of fixation cross until offset of last word (marks target word type; can also retrieve first word info but not in default trl)


fprintf('Preprocessing subject %s  \n', subjectname);
mous_db_makesubjdir(subjectname)

% get the filename of the raw data
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

for k = 1:numel(filename)
  if numel(filename)==1
    % get the description of the artifacts
    tmp = mous_db_getdata(subjectname, 'meg_artifact_cfg');
  else
    tmp = mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);
  end
  
  [trl] = mous_defineTrial(filename{k}, prestim, poststim, 'all', trialfun);
  [trl] = mous_artifact_remove(trl, filename{k}, tmp);
  tmp   = mous_preprocessing(filename{k}, trl, resamplefs, analysisType, prestim);
  if k==1
    data = tmp;
  end
  
  if k>1
    data = ft_appenddata([], data, tmp);
  end
  clear tmp;
end
%dataStats = mous_samplestats(trl); %FIXME

length = [num2str(prestim*10,'%02d'),'-',num2str(poststim*10,'%02d')];

%mous_db_putdata(subjectname, ['meg_processed_{_preProcERF' trialfun '_' length 'ds}'], 'data');
mous_db_putdata(subjectname, ['meg_erf_allwords_',length], 'data',1);
