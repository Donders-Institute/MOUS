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
    ind_noun = [];
    ind_verb = [];
    ind_adj = [];
    featv = [];
    wordv = {};
    for i = 1:length(tlck_sent.trialinfo)
        wavid = tlck_sent.trialinfo(i,6);
        posword = tlck_sent.trialinfo(i,5);
        vec = stimuli(wavid).words(posword).word2vec;
        label = strtok(stimuli(wavid).words(posword).POS,'(');
        if ~isempty(vec) %&& (strcmp(label,'N') || strcmp(label,'WW') || strcmp(label,'ADJ'))
            featv(i,:) = vec;
            indsel = [indsel i];
            wordv{i} = label;%stimuli(wavid).words(posword).word;
            if strcmp(label,'N')
                ind_noun = [ind_noun i];
            elseif strcmp(label,'WW')
                ind_verb = [ind_verb i];
            elseif strcmp(label,'ADJ')
                ind_adj = [ind_adj i];
            end
        end
    end
    featv = featv(indsel,:);
    wordv = wordv(indsel);
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
%select time window of interest
[numobs,n,p]     = size(data);
[numobs,numfeat] = size(featv);
steps            = 31;
timesteps        = 1:steps:p;
%lambdas          = [0.000000001,0.0000000001,0.000000001,0.00000001,0.0000001,0.000001,1,5,8];%,0.0001,0.001,0.01,0.1,1,5];
k                = 5; % number of folds for Lambda
%% Generate cross-validation set
%leave out several vectors at a time for higher sensibility
% 1. find divisor without remainder
range            = 1:numobs;
div              = range(rem(numobs,range) == 0);
leaveout         = div(nearest(div,2));
cross            = crossvalind('Kfold',numobs,numobs/leaveout);
% 2. Get rid of repetitions (each examplar only exists once)
[C,IA,IC] = unique(featv,'rows');
data = data(IA,:,:);
featv = featv(IA,:);
[numobs,numfeat] = size(featv);
range            = 1:numobs;
div              = range(rem(numobs,range) == 0);
leaveout         = div(nearest(div,2));
cross            = crossvalind('Kfold',numobs,numobs/leaveout);
%% Regression
accuracy    = zeros(length(timesteps)-1,1) ;
misswords   = [];
for t = 1:length(timesteps)-1 %FIX: does not take last timewindow for now
    %select timeslice & append timepoints
    datasel = data(:,:,timesteps(t):(timesteps(t+1)-1));
    [numobs,n,p] = size(datasel);
    datasel = reshape(datasel,[numobs,(n*p)]);
    correct          = 0;
    for fold = 1:max(cross)
%         fprintf('processing timewindow: %d til %d -- testexample number %d of %d : ',timesteps(t),timesteps(t+1)-1,fold,max(cross));
%         fprintf('\n');
        %assign data according to fold indices and coding direction
        %(encoding/decoding)
        %indfold = or((IC == fold),(IC==(fold+1)));
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
        
        %sanity check: permute labels
        %y_train = y_train(randperm(size(y_train,1)),:);
        
        [stat.model{fold},stat.result{fold},lambda_hat]     = ridgeregression_sa(cfg,x_train,x_test,y_train);
        %y_hat = randn(leaveout,320);y_hat = y_hat*0.05;%create random vector as
        %prediction

        stat.design{fold}                                = y_test;
    end
        success = eval_euclideandistance(cfg,stat);
        
        %success = eval_corr(y_hat,y_test,featv,1);
        correct = correct + success;
        
%         indices = find(cross==fold);
%         leftoutword1 = cell2mat(wordv{indices(1)});
%         leftoutword2 = cell2mat(wordv{indices(2)});
%         fprintf('left out words: %s and %s',leftoutword1,leftoutword2);
%         fprintf('\n')
%          if success
%              fprintf('predicted label matches');
%          else
%              fprintf('predicted label does NOT match');
%              misswords(t,fold,:) = indices;
%          end
%          fprintf('\n');
    accuracy(t,:) = correct/max(cross);
end
%save('/project/3011020.09/sopara/betas/all_betas','all_betas','-v7.3')

function success = eval_euclideandistance(y_hat,y_test)

[num,tmp]            = size(y_test);
y_test1              = y_test(1:num/2,:)' ;
y_test2              = y_test(num/2+1:end,:)' ;
y_test1              = y_test1(:) ;
y_test2              = y_test2(:) ;

y_hat1               = y_hat(1:num/2,:)' ;
y_hat2               = y_hat(num/2+1:end,:)' ;
y_hat1               = y_hat1(:) ;
y_hat2               = y_hat2(:) ;

%evaluate prediction
%euclidean distance between vectors belonging together should be smaller
%than distance between vectors not belonging together.
same                 = norm(y_hat1-y_test1)+ norm(y_hat2-y_test2);
different            = norm(y_hat1-y_test2)+ norm(y_hat2-y_test1);
success              = same < different;
fprintf('same = %.2f ', same);
fprintf('different = %.2f', different);
fprintf('distance test vectors = %.2f',norm(y_test1-y_test2))
fprintf('\n');
end
%%
%%
