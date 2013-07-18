function mous_preprocessing_pipeline(subjectname)
% Revamped from the old version by AH 12.7 2013 to be prettier
% functionality remains unchanged.

prestim = 0.2;  % default is 0.5;
poststim = 1.0;
downsample2 = 300; 
analysisType = 'ERF'; 
% other options 'TFR':


trialfun =  'auditory_word';   
%            'auditory_sentence' 
%            'auditory_word';     % onset of speech for first word and target word
%            'visual_word';       % onset of each word (but not fixation cross)
%            'visual_sentence';   % onset of fixation cross until offset of last word (marks target word type; can also retrieve first word info but not in default trl)


fprintf('Preprocessing subject %s  \n', subjectname);
mous_db_makesubjdir(subjectname)

% get the filename of the raw data
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

% get the description of the artifacts
tmp = mous_db_getdata(subjectname, 'meg_artifact_cfg');

[trl] = mous_defineTrial(filename{1}, prestim, poststim, 'all', trialfun);

[trl] = mous_artifact_remove(trl, filename{1}, tmp);
%dataStats = mous_samplestats(trl); %FIXME

data = mous_preprocessing(filename{1}, trl, downsample2, analysisType, prestim);

length = ['0' num2str(prestim*10) '-' num2str(poststim)];

mous_db_putdata(subjectname, ['meg_processed_{_preProcERF' trialfun '_' length 'ds}'], 'data');
