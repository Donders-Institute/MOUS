% This script fits a GLM to the source data of one subject and evaluates
% how accurate predictions are for a semantic feature vector corresponding to
% the stimulus material

if ~exist('subjectname', 'var')
    error('a subjectname needs to be provided');
end

if ~exist('rootdir', 'var')
    rootdir = '/project/3011020.09/sopara';
end

if ~exist('doword2vec',       'var'), doword2vec      = 0; end
if ~exist('dopos',       'var'), dopos      = 0; end
if ~exist('dochannel',       'var'), dochannel      = 0; end
if ~exist('dosource',       'var'), dosource      = 0; end
if ~exist('doregression',       'var'), doregression      = 0; end
if ~exist('dofitdata',       'var'), dofitdata     = 0; end
if ~exist('dofitvector',       'var'), dofitvector      = 0; end
if ~exist('dools',       'var'), dools      = 0; end
if ~exist('doridge',       'var'), doridge      = 0; end

%% Load in data
%load mne source reconstruction on averaged tlck data to get filter
mne         = mous_db_getdata(subjectname,'meg_mne_allwords_02-nextword_sent');
inside      = mne.inside;
filter      = mne.avg.filter;
clear mne
%load in single trial data
tlck        = mous_db_getdata(subjectname,'meg_erf_allwords_02-nextword');

%select only words at least 500ms long
nsmp        = cellfun('size', tlck.trial, 2);
tlck        = ft_selectdata(tlck, 'rpt', find(nsmp>=211));
%Select sentence condition only
trign       = [1 5 2 6];
sel         = ismember(tlck.trialinfo(:,2),trign);

cfg         = [];
cfg.trials  = sel;
cfg.channel = {'all' '-EEG057','-EEG058'};
%cfg.latency = [-0.1 0.5]; does not work use ft_redefinetrial instead
tlck_sent   = ft_selectdata(cfg,tlck);
cfg = [];
cfg.toilim    = [-0.1 0.5];
tlck_sent = ft_redefinetrial(cfg,tlck_sent);

nsmp        = cellfun('size', tlck_sent.trial, 2);
tlck_sent        = ft_selectdata(tlck_sent, 'rpt', find(nsmp>=181));

clear tlck
%F = cat(1,mne.avg.filter{:});
% source_singl = F*tlck_sent.trial{k};

%% Feature creation
if doword2vec
    %Only choose trials that correspond to stimuli with word2vec
    %information & extract label information per stimulus
    load /project/3011020.09/MEG/misc/mous_stimuli.mat
    indsel = [];
    vec = [];
    for i = 1:length(tlck_sent.trialinfo)
        wavid = tlck_sent.trialinfo(i,6);
        posword = tlck_sent.trialinfo(i,5);
        vec = stimuli(wavid).words(posword).word2vec;
        if ~isempty(vec)
            featv(i,:) = vec;
            indsel = [indsel i];
        end
    end
    featv = featv(indsel,:);
    
    tlck_sent = ft_selectdata(tlck_sent, 'rpt', indsel);
    clear stimuli
end

if dopos
    %Only choose trials that correspond to stimuli with word2vec
    %information & extract label information per stimulus
    load /project/3011020.09/MEG/misc/mous_stimuli.mat
    indmissing = ones(length(tlck_sent.trialinfo),1);
    pos = {};
    for i = 1:length(tlck_sent.trialinfo)
        wavid = tlck_sent.trialinfo(i,9);
        posword = tlck_sent.trialinfo(i,8);
        label = strtok(stimuli(wavid).words(posword).POS,'(');
        if ~isempty(label)
            pos{i} = cell2mat(label);
        else
            indmissing(i) = 0;
        end
    end
    pos = pos(indmissing);
    
    tlck_sent = ft_selectdata(tlck_sent, 'rpt', indmissing);
end

%% Preprocessing
timesteps = 1:31:181;
if dochannel
    [m,n] = size(tlck_sent.trial{1});
    data = zeros(length(tlck_sent.trial),m,n);
    for i = 1:length(tlck_sent.trial)
    data(i,:,:) = tlck_sent.trial{i};
    end
end

if dosource
   data = zeros(size(tlck_sent.trial,2),size(filter,1),size(tlck_sent.time{1},2));
for i=1:size(filter,1)% loop over nvertex
    for j = 1:size(tlck_sent.trial,2) %loop over ntrials
        data(j,i,:) = squeeze(sum(abs(filter{i} * tlck_sent.trial{j}).^2,1));
    end
end 
end


%% regression
%select time window of interest
[m,n,p]     = size(data);
timesteps   = [31:31:181, 181];
accuracy    = zeros(length(timesteps),1);

jobid = {};
count = 1;
for t = 1:length(timesteps)-1
    datasel = data(:,:,timesteps(t):(timesteps(t+1)-1));
    [m,n,p] = size(datasel);
    datasel = reshape(datasel,[m,(n*p)]);
    
    if dofitdata
        
        
        %need to do this per source location as full channel matrix is rank
        %deficient by definition
        %% Generate design matrix
        
        % use channels as regressors
        % ordinary least squares regression
        % compute zscore 
        s           = std(datasel,0,1); 
        mu          = mean(datasel,1); 
        x           = datasel - mu; 
        datasel_z   = x./s; 
        design = [ones(size(data,1),1) datasel_z];
        %zscore?
        
        %% Generate cross-validation set
        numobs = size(design,1);
        %inds = crossvalind('LeaveMOut',numobs,2); %generate new test example at each round, with possible repetitions
        if mod(numobs,2) %if uneven number of observations make even to enable even crossvalidation split
            numobs = numobs-1;
        end
        cross = crossvalind('Kfold',numobs,numobs/2);
        
        %% Find GLM & test accuracy of predictive power using cross-validation
       
        correct      = 0;
        incorrect    = 0;
        leftout      = zeros(max(cross),2);
        for f = 1:max(cross) % do in cross-validation manner for each fold
            %create cross-validation set split
            leftout(f,:)    = find(cross==f);
            traindata       = design(~(cross==f),:);
            trainfeat       = featv(~(cross==f),:);
            testdata        = design(cross==f,:);
            testfeat        = featv(cross==f,:);
            
            if dools
            %ordinary least squares multivariate regression %results in
            %overfitting
            [betas,se_b,mse]    = lscov(traindata,trainfeat); % X = lscov(A,B); ordinary least squares solution to A*X = B, (MxN)*(Nx1) = (Mxk);
            
            %predict feature vector for left out samples
            predicted_y         = testdata * betas;
         
            end
            
            if doridge
              traindata         = traindata(:,2:end);  
              testdata          = testdata(:,2:end);  
              
              predicted_y       = zeros(2,size(trainfeat,2));
              for i = 1:size(trainfeat,2)
              jobid{count} = qsubfeval('ridge',trainfeat(:,i),traindata,(10^-6),'memreq',(1024^3)*7,'timreq',1000,'matlabcmd','matlab2016b','batchid',strcat('feat_',num2str(i),'_fold_',num2str(f),'_time_',num2str(t)));
              pause(15)
              count = count+1;
              end
            end
        end
    end

    if dofitvector
        %% Generate design matrix
        
        %use feature vectors as regressors
        % ordinary least squares regression
        s           = std(featv,0,1); 
        mu          = mean(featv,1); 
        x           = featv - mu; 
        featv_z   = x./s; 
        design = [ones(size(data,1),1) featv_z];
        
        %zscore data
        s           = std(datasel,0,1); 
        mu          = mean(datasel,1); 
        x           = datasel - mu; 
        datasel_z   = x./s; 
        
        %% Generate cross-validation set
        numobs = size(design,1);
        %inds = crossvalind('LeaveMOut',numobs,2); %generate new test example at each round, with possible repetitions
        if mod(numobs,2) %if uneven number of observations make even to enable even crossvalidation split
            numobs = numobs-1;
        end
        cross = crossvalind('Kfold',numobs,numobs/2);
        %% Find GLM & test accuracy of predictive power using cross-validation
        
        correct         = 0;
        incorrect       = 0;
        leftout         = zeros(max(cross),2);
        for f = 1:max(cross) % do in cross-validation manner for each fold
            %create cross-validation set split
            leftout(f,:)    = find(cross==f);
            traindata       = datasel_z(~(cross==f),:);
            trainfeat       = design(~(cross==f),:);
            testdata        = datasel_z(cross==f,:);
            testfeat        = design(cross==f,:);
            
            if dools
                %ordinary least squares multivariate regression
                [betas,se_b,mse]    = lscov(trainfeat,traindata); % X = lscov(A,B); least squares solution to A*X = B, (MxN)*(Nx1) = (Mxk);
                %predict feature vector for left out samples
                predicted_y         = testfeat * betas;
            end
            
            if doridge
              trainfeat         = trainfeat(:,2:end);  
              testfeat          = testfeat(:,2:end);  
              
              predicted_y       = zeros(2,size(traindata,2));
              for i = 1:size(traindata,2)
              betas             = ridge(traindata(:,i),trainfeat,10^(-6));
              predicted_y(:,i)  = testfeat * betas;
              end
            end
            %% evaluate prediction
            %euclidean distance between vectors belonging together should be smaller
            %than distance between vectors not belonging together.
            same        = norm(predicted_y-testdata);
            different   = norm(predicted_y-testdata([2 1],:));
            success     = same < different;
            fprintf('timewindow: %d til %d -- fold %d of %d : ',timesteps(t),timesteps(t+1)-1,f,max(cross));
            if success
                fprintf('predicted label matches');
                correct = correct+1;
            else
                fprintf('predicted label does NOT match');
                incorrect = incorrect + 1;
            end
            fprintf('\n');
        end
        
    end%FIXME! does not send off jobs to cluster
end
%% prediction
count = 1;
for t = 1:length(timesteps)-1
      for f = 1:max(cross)
          for i = 1:size(trainfeat,2)
            load(strcat(jobid{count},'_output')); %[mv_corr,mv2_corr,ma_corr,ma2_corr,ms_corr,ms2_corr,ms3_corr] 
            betas = argout{1};
            predicted_y(:,i)  = testdata * betas;
            count = count+1;
          end 
            %evaluate prediction
            %euclidean distance between vectors belonging together should be smaller
            %than distance between vectors not belonging together.
            same        = norm(predicted_y-testfeat);
            different   = norm(predicted_y-testfeat([2 1],:));
            success     = same < different;
            fprintf('timewindow: %d til %d -- fold %d of %d : ',timesteps(t),timesteps(t+1)-1,f,max(cross));
            if success
                fprintf('predicted label matches');
                correct = correct+1;
            else
                fprintf('predicted label does NOT match');
                incorrect = incorrect + 1;
            end
            fprintf('\n');
      end
      accuracy(t,:) = correct/max(cross);
end
%%
%%
