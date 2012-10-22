function mous_preprocessing_pipeline(subjectname)% Pipeline to run all preprocessing stages for the TFR and ERFs
% Annika 1.6 2012 | edited 2.7.2012 NL

% addpath('/home/common/matlab/fieldtrip/qsub');
% clear all

    % subjectname = subjlist{n};    %  comment out when running qsub
    fprintf('Preprocessing subject %s  \n', subjectname);
    mous_db_makesubjdir(subjectname)

    % get the filename of the raw data
    filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

    % get the description of the artifacts
    tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');
    
    wordType = 'all';   % all words in a  sentence / sequence
        % other options:
        % 'target'; 'tarplusOne'; 'tarplusTwo';
        % to be implemented: 'nouns'; 'verbs' ; firstWord etc
               
    % the trial funs need to be renamed
    trialfun =  'visual_word';       % does not include fixation
    %           'visual_sentence';  %includes onset of fixation cross
         
   % FIXME
   % defining the pre and post stimulus windows here (instead of at multple
   % places below
    
    % define trial window (includes pre -500ms and post 3s)
    [trl] = mous_defineTrial(filename{1}, 0.5, 3.0, wordType, trialfun); 

    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);
   
              
    %% TFR %%%%%%%%%%%%%%%%%%%%%     
       
    % PREPROCESS data 
    % filename = subject, trl = data, 300 = downsample target frequency,

    data = mous_preprocessing(filename{1}, trl, 300, 'TFR');
  
    %save preprocessed data 
    mous_db_putdata(subjectname, ['meg_processed_{preProcTFR' trialfun '_' wordType '05-3ds}'], data);
    
    % go to TFR pipeline: "mous_tfr_pipline" 

    %% ERF %%%%%%%%%%%%%%%%%%%%

    %% long time window
    % for qsub: max 15 minutes, 2.5GB 

    % preprocess data 
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)
    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.5);
    
    % save preprocessed data
        mous_db_putdata(subjectname, ['meg_processed_{preProcERF' trialfun wordType '05-3ds}'], data);

    %% short time window

    % redefine the trial window and remove the artefacts for the short
    % window
    % define trial window (includes pre -500ms and post 3s)
    [trl] = mous_defineTrial(filename{1}, 0.2, 1.0, wordType, trialfun); 
    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);

    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.2);
    
    % save preprocessed data  
    mous_db_putdata(subjectname, ['meg_processed_{preProcERF' trialfun wordType '02-1ds}'], data);

