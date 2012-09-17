% Pipeline to run all preprocessing stages for the TFR and ERFs
% Annika 1.6 2012 | edited 2.7.2012 NL

% addpath('/home/common/matlab/fieldtrip/qsub');
% clear all

function mous_preprocessing_pipeline(subjectname)

  
    % subjectname = subjlist{n};    %  comment out when running qsub
    fprintf('Preprocessing subject %s  \n', subjectname);
    mous_db_makesubjdir(subjectname)

    % get the filename of the raw data
    filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

    % get the description of the artifacts
    tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');
    
    wordType = 'target'; % 'tarplusOne'; 'tarplusTwo';
    
    %% TFR %%%%%%%%%%%%%%%%%%%%%
     
    % define trial window (includes pre -500ms and post 3s)
    
    [trl] = mous_defineTrial(filename{1}, 0.5, 3.0, wordType); 

    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);
       
    % PREPROCESS data 
    % (filename = subject, trl = data, 300 = downsample target frequency,

    data = mous_preprocessing(filename{1}, trl, 300, 'TFR');
  
    %save preprocessed data
    mous_db_putdata(subjectname, 'meg_processed_{rawTFR05-3ds}', data);
    if (strcmp(wordType,'target') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawTFR_targetword_05-3ds}', data);
    elseif (strcmp(wordType,'tarplusOne') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawTFR_tarplusOne_05-3ds}', data);  
    elseif (strcmp(wordType,'tarplusTwo') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawTFR_tarplusTwo_05-3ds}', data);
    end
       
    % go to TFR pipeline: "mous_tfr_pipline" 

    %% ERF %%%%%%%%%%%%%%%%%%%%

    %% long time window
    % for qsub: max 15 minutes, 2.5GB 

    % preprocess data 
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)
    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.5);
    
    % save preprocessed data
    if (strcmp(wordType,'target') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_targetword_05-3ds}', data);
    elseif (strcmp(wordType,'tarplusOne') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_tarplusOne_05-3ds}', data);  
    elseif (strcmp(wordType,'tarplusTwo') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_tarplusTwo_05-3ds}', data);
    end

    %% short time window

    % define trial window (includes pre -500ms and post 3s)
    [trl] = mous_defineTrial(filename{1}, 0.2, 1.0, wordType); 

    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);

    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.2);
    
    % save preprocessed data  
    if (strcmp(wordType,'target') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_targetword_02-1ds}', data);
    elseif (strcmp(wordType,'tarplusOne') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_tarplusOne_02-1ds}', data);  
    elseif (strcmp(wordType,'tarplusTwo') > 0) 
        mous_db_putdata(subjectname, 'meg_processed_{rawERF_tarplusTwo_02-1ds}', data);
    end

% end % comment out when running qsub
