% Pipeline to run all preprocessing stages for the TFR and ERFs
% Annika 1.6 2012

subjlist = { 'V1001' 'V1002' 'V1003' 'V1010' 'V1011' 'V1012' 'V1013' 'V1014' ...
'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024' 'V1025' ...
'V1026' 'V1027' 
% This list of subjects were preprocessed in weekend 2-3.6 2012


for n = 1:length(subjlist)
  
  
    subjectname = subjlist{n};
    fprintf('Preprocessing subject %s  \n', subjectname);
    mous_db_makesubjdir(subjectname)

    % get the filename of the raw data
    filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

    % get the description of the artifacts
    tmp = mous_db_getdata(subjectname, 'meg_artifactcfg');

    %% TFR %%%%%%%%%%%%%%%%%%%%%

    % define trial window (includes pre -500ms and post 3s)
    trl = mous_defineTrial(filename{1}, 0.5, 3.0); 

    % remove the artifacts that have been defined/detected
    trl = mous_artifact_remove(trl, filename{1}, tmp);

    % preprocess data 
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)
    data = mous_preprocessing(filename{1}, trl, 300, 'TFR');
    % save preprocessed data
    mous_db_putdata(subjectname, 'meg_processed_{rawTFR05-3ds}', data);

    % go to TFR pipeline: "mous_tfr_pipline" 


    %% ERF %%%%%%%%%%%%%%%%%%%%

    %% long time window

    % define trial window (includes pre -500ms and post 3s)
    %trl = mous_defineTrial(filename{1}, 0.5, 3.0); NO NEED TO REPEAT THIS

    % remove the artifacts that have been defined/detected
    %trl = mous_artifact_remove(trl, filename{1}, tmp); NO NEED TO REPEAT THIS

    % preprocess data 
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)

    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', 0.5);
    % save preprocessed data
    mous_db_putdata(subjectname, 'meg_processed_{rawERF05-3ds}', data);


    %% short time window


    % define trial window (includes pre -500ms and post 3s)
    trl = mous_defineTrial(filename{1}, 0.2, 1.0); 

    % remove the artifacts that have been defined/detected
    trl = mous_artifact_remove(trl, filename{1}, tmp);

    % preprocess data 
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)
    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', 0.2);
    % save preprocessed data
    mous_db_putdata(subjectname, 'meg_processed_{rawERF02-1ds}', data);

end
