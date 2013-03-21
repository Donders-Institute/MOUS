%function mous_preprocessing_pipeline(subjectname)% Pipeline to run all preprocessing stages for the TFR and ERFs
% Annika 1.6 2012 | edited 2.7.2012 NL | edited 9.11. 2012 AH

% Filenaming convention
%  Filename consists of  [subjectnum] [preProc] [ERF/TFR] [trial fun] [word type: all/target/nouns etc] [time window]
%   ALWAYS put an underscore '_' between subjectnum and the rest
%  e.g. preProcERFvisual_word_all_02-1ds
% (previous(old) versions are called rawERF or rawTFR respectively)
% check the filename at the end of the script before running it.

doTFR       = false;
doERFlong   = false;
doERFshort  = true;


% subjectname = subjlist{n};    %  comment out when running qsub
fprintf('Preprocessing subject %s  \n', subjectname);
mous_db_makesubjdir(subjectname)

% get the filename of the raw data
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

% get the description of the artifacts
tmp = mous_db_getdata(subjectname, 'meg_artifact_cfg');

wordType = 'all';   % all words in a  sentence / sequence
% other options:
% ;'all' 'target'; 'tarplusOne'; 'tarplusTwo';
% to be implemented: 'nouns'; 'verbs' ; firstWord etc

trialfun =   'visual_word';
%            'auditory_word';     % onset of speech for first word and target word
%            'visual_word';       % onset of each word (but not fixation cross)
%           'visual_sentence';   % onset of fixation cross until offset of last word (marks target word type; can also retrieve first word info but not in default trl)


% if you do the long time windows you can remove the artefacts commonly
% ofr both, the artefacts for the short are removed later in the
% doERfshort section

if doTFR || doERFlong
    
    % define long time window
    prestim = 0.5;  % default for auditory trialfuns is 0.5;
    poststim = 3.0;
    
    % define trial window
    [trl] = mous_defineTrial(filename{1}, prestim, poststim, wordType, trialfun);
    
    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);
    dataStats = mous_samplestats(trl); % compare the amount of data in the two conditions
    
end


%% TFR %%%%%%%%%%%%%%%%%%%%%
if doTFR
    
    % PREPROCESS data
    % filename = subject, trl = data, 300 = downsample target frequency,
    
    data = mous_preprocessing(filename{1}, trl, 300, 'TFR');
    
    %save preprocessed data
    mous_db_putdata(subjectname, ['meg_processed_{_preProcTFR' trialfun '_' wordType '05-3ds}'], 'data','dataStats');
    
    % go to TFR pipeline: "mous_tfr_pipline"
    
end

%% ERF %%%%%%%%%%%%%%%%%%%%

%% long time window
if doERFlong
    % for qsub: max 15 minutes, 2.5GB
    
    % preprocess data
    % (filename = subject, trl = data, 300 = downsample target frequency,
    % filters specific to analysis type)
    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.5);
    dataStats = mous_samplestats(trl); % compare the amount of data in the two conditions
    % save preprocessed data
    mous_db_putdata(subjectname, ['meg_processed_{_preProcERF' trialfun wordType '05-3ds}'], 'data','dataStats');
end

%% short time window

if doERFshort
    % redefine the trial window and remove the artefacts for the short window
    % no point running this analyses for 'First3sLast3s'   
    prestim = 0.2;
    poststim = 1.0;
    
    % define trial window (includes pre -500ms and post 3s)
    [trl] = mous_defineTrial(filename{1}, prestim, poststim, wordType, trialfun);
    % remove the artifacts that have been defined/detected
    [trl] = mous_artifact_remove(trl, filename{1}, tmp);
    dataStats = mous_samplestats(trl); % compare the amount of data in the two conditions, before down sampling
    
    data = mous_preprocessing(filename{1}, trl, 300, 'ERF', -0.2);
        
    mous_db_putdata(subjectname, ['meg_processed_{_preProcERF' trialfun '_' wordType '02-1ds}'], 'data','dataStats');
end

