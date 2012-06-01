% This script runs the preprocessing TFR
% a similar version with different parameters for ERFs

subjectname = 'V1015';

% Pipeline to run all preprocessing stages for the TFR and ERFs
% Annika 1.6 2012

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

% go to TFR pipeline: "mous_pipeline_tfr" 


%% ERF %%%%%%%%%%%%%%%%%%%%

%% long time window

% define trial window (includes pre -500ms and post 3s)
trl = mous_defineTrial(filename{1}, 0.5, 3.0); 

% remove the artifacts that have been defined/detected
trl = mous_artifact_remove(trl, filename{1}, tmp);

% preprocess data 
% (filename = subject, trl = data, 300 = downsample target frequency,
% filters specific to analysis type)
data = mous_preprocessing(filename{1}, trl, 300, 'ERF');
% save preprocessed data
mous_db_putdata(subjectname, 'meg_processed_{rawTFR05-3ds}', data);


%% short time window


% define trial window (includes pre -500ms and post 3s)
trl = mous_defineTrial(filename{1}, 0.2, 1.0); 

% remove the artifacts that have been defined/detected
trl = mous_artifact_remove(trl, filename{1}, tmp);

% preprocess data 
% (filename = subject, trl = data, 300 = downsample target frequency,
% filters specific to analysis type)
data = mous_preprocessing(filename{1}, trl, 300, 'ERF');
% save preprocessed data
mous_db_putdata(subjectname, 'meg_processed_{rawTFR02-1ds}', data);
