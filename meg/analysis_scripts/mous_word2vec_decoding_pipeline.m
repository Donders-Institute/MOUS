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

%%
% observations should be even number
data             = data(4:end,:,:); %% temporary fix
featv            = featv(4:end,:);
%select time window of interest
[numobs,n,p]     = size(data);
[numobs,numfeat] = size(featv);
steps            = 31;
timesteps        = 1:steps:p;
%lambdas          = [0.0001,0.001,0.01,0.1,1,5];
k                = 5; % number of folds for Lambda
%% Generate cross-validation set
%find divisor without remainder
%leave out several vectors at a time for higher sensibility
range            = 1:numobs;
div              = range(rem(numobs,range) == 0);
leaveout         = div(nearest(div,10));
cross            = sort(crossvalind('Kfold',numobs,numobs/leaveout));
%FIX: only leave out entire exemplar (if a word repeats all trials should be either in test or training set;
all_betas        = NaN(n*steps,numfeat,length(timesteps)-1,max(cross),'single');
%% Regression
for t = 1:length(timesteps)-1
    %select timeslice & append timepoints
    datasel = data(:,:,timesteps(t):(timesteps(t+1)-1));
    [numobs,n,p] = size(datasel);
    datasel = reshape(datasel,[numobs,(n*p)]);
    for fold = 1:max(cross)
        fprintf('processing fold %d; timeslice %d\n', fold, t);
        %assign data according to fold indices and coding direction
        %(encoding/decoding)
        x_train = [];
        y_train = [];
        if dofitdata
            x_train       = datasel(cross~=fold,:);
            y_train       = featv(cross~=fold,:);
            x_test        = datasel(cross==fold,:);
            y_test        = featv(cross==fold,:);
        elseif dofitvector
            y_train       = datasel(cross~=fold,:);
            x_train       = featv(cross~=fold,:);
            y_test        = datasel(cross==fold,:);
            x_test        = featv(cross==fold,:);
        end
        
        if doridge
            %zscore
            [x_train, Mu, Sigma] = zscore(x_train);
            all_Mu(:,t,fold) = Mu;
            all_Sigma(:,t,fold) = Sigma;
            %Q:zscore testset with mean and stdv from trainingset??
            %pre-compute data variance
            varx                 = x_train * x_train';
            %% Compute optimal Lambda
            %% train ridge regression with several labda values using cross-validation
            [m,n]       = size(y_train);
            indx        = sort(crossvalind('Kfold', m, k));
            y_hat       = NaN(m, n, length(lambdas), 'single');
            
            for Lfold = 1 : k
                
                trainl   = Lfold ~= indx;
                S       = sum(trainl);
                betasl  = NaN(S, n,length(lambdas), 'single');
                I       = eye(S, 'single');
                testl    = Lfold == indx;
                
                foo     = varx(trainl, trainl);
                bar     = y_train(trainl, :);
                
                parfor lambda = 1 : length(lambdas)
                    
                    betasl(:, :, lambda) = (foo + lambdas(lambda) * I) \ bar;
                    
                end
                
                y_hat(testl, :, :) = reshape(varx(testl, trainl) * reshape(betasl, S, n * length(lambdas)), sum(testl), n, length(lambdas));
                %multiply the standardized slope (beta weight) by the correlation for each independent variable and add to calculate R2.
                %What this does is to include both the correlation, (which will overestimate the total R2 because of shared Y)
                %and the beta weight (which underestimates R2 because it only includes the unique Y and discounts the shared Y).
                %Appropriately combined, they yield the correct R2.
                
            end
            
            %% compute residuals
            R = NaN(n, length(lambdas), 'single');
            for lambda = 1 : length(lambdas)
                
                c_1 = bsxfun(@minus, y_train, mean(y_train));
                c_2 = bsxfun(@minus, y_hat(:, :, lambda), mean(y_hat(:, :, lambda)));
                
                R(:, lambda) = sum(c_1 .* c_2) ./ (sqrt(sum(c_1 .^ 2)) .* sqrt(sum(c_2 .^ 2)));
                
            end
            %% select optimal lambda values
            r_hat      = NaN(n, 1, 'single');
            lambda_hat = NaN(n, 1, 'single');
            for feat = 1 : n
                
                [r_hat(feat), I] = max(R(feat, :));
                lambda_hat(feat) = lambdas(I);
                
            end
            % Compute beta values with optimal Lambda
            C        = unique(lambda_hat);
            beta_hat = NaN(m, n, 'single');
            I        = eye(m, 'single');
            for lambda = 1 : length(C)
                
                beta_hat(:, C(lambda) == lambda_hat) = (varx + C(lambda) * I) \ y_train(:, C(lambda) == lambda_hat);
                
            end
            
            
            %system('df /project/3011050.04/betas','-echo')
            
        end
        all_betas(:,:,t,fold) = x_train' * beta_hat;
    end
end


%% prediction for fitdata
accuracy    = zeros(length(timesteps)-1,1) ;
for t = 1:length(timesteps)-1
    correct     = 0 ;
    incorrect   = 0 ;
    %select timeslice & append timepoints
    datasel = data(:,:,timesteps(t):(timesteps(t+1)-1));
    [numobs,n,p] = size(datasel);
    datasel = reshape(datasel,[numobs,(n*p)]);
    for fold = 1:max(cross)
        %zscore testset with mean and stdv from trainingset??
        x_test               = datasel(cross==fold,:);
        x_test               = bsxfun(@rdivide, bsxfun(@minus, x_test, squeeze(all_Mu(:,t,fold))'), squeeze(all_Sigma(:,t,fold))');
        y_test               = featv(cross==fold,:);
        % concatenate left out testvectors into two
        [num,tmp]            = size(y_test);
        y_test1              = y_test(1:num/2,:)' ;
        y_test2              = y_test(num/2+1:end,:)' ;
        y_test1              = y_test1(:) ;
        y_test2              = y_test2(:) ;
        betas                = squeeze(all_betas(:,:,t,fold));
        y_hat                = x_test * betas;
        %evaluate prediction
        %euclidean distance between vectors belonging together should be smaller
        %than distance between vectors not belonging together.
        y_hat1               = y_hat(1:num/2,:)' ;
        y_hat2               = y_hat(num/2+1:end,:)' ;
        % number of trials is odd, therfore folds are odd, therefore test1
        % longer than test2 - problematic?
        y_hat1               = y_hat1(:) ;
        y_hat2               = y_hat2(:) ;
        same                 = norm(y_hat1-y_test1)+ norm(y_hat2-y_test2);
        different            = norm(y_hat1-y_test2)+ norm(y_hat2-y_test1);
        success              = same < different;
        fprintf('timewindow: %d til %d -- testexample number %d of %d : ',timesteps(t),timesteps(t+1)-1,fold,max(cross));
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
