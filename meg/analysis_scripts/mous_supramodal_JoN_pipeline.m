% This script contains the full analysis pipeline corresponding to our
% article "Sensory Modality-Independent Activation of the Brain Network
% for Language" in Journal of Neuroscience
% DOI: htpps://doi.org/10.1523/JNEUROSCI.2271-19.2020

% In addition to FieldTrip functions, this script calls the following custom matlab files:
% mous_multisetcca
% mous_multisetcca_createshuffle
% mous_multisetcca_extractwords
% mous_multisetcca_getparceldata
% mous_multisetcca_groupdata2singlestruct
% mous_multisetcca_lcmv
% mous_multisetcca_postprocess
% mous_multisetcca_prevalence
% mous_multisetcca_reorderaudio
% mous_multisetcca_sensor2parcel
% mous_multisetcca_stats
% mous_multisetcca_trc

% For computing sourcemodel & headmodel
% FIXME: add script names here


% Results are saved in:
% /project/3011020.09/processed/XXXX/meg/multisetcca/XXX_multisetcca_XX.mat
% /project/3011020.09/sopara/supramodal_JoN/..

% Set all paths
derivativedir    = '/project/3011020.09/processed/%s/meg/multisetcca/';
resultsdir       = '/project/3011020.09/sopara/supramodal_JoN/';

% Set flags for which parts of the script should be executed
if ~exist('contentwords_only', 'var'),contentwords_only = true;                      end
%This script is divided in different analysis steps some of which will be
%computed per subject, others per parcel, others per scenario.
% They can be called individually as well by setting the following flags:
if ~exist('create_shuffle_indx',  'var'), create_shuffle_indx = false;end % create set of files that have pre-cooked randomization sequences
if ~exist('do_prevalence',      'var'), do_clusterstats     = false; end
if ~exist('do_clusterstats',      'var'), do_clusterstats     = false; end
if ~exist('scenario',         'var'), error('a scenario index needs to be specified');   end
% analysis done per scenario
if ~exist('dolcmv',           'var'), dolcmv           = false;                       end % compute spatial filters
%analysis done per scenario and per parcel_indx
if ~exist('domscca_searchlight',  'var'), domscca_searchlight = false; end % various mscca flavours
if ~exist('dotrc',                'var'), dotrc               = false; end
if ~exist('dotrc_prior',          'var'), dotrc_prior         = false; end
if domscca_searchlight || dotrc || dotrc_prior
    if ~exist('parcel_indx', 'var'),    error('a parcel index needs to be specified');  end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Beginning analysis script %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Retrieve which subjects belong to specified scenario
load(fullfile(resultsdir,'subj_sce_info.mat'))
sel = strncmp(sce, num2str(scenario), 1);
subj = subj(sel);
clear sce
% Load stimulus info file
load(fullfile(resultsdir,'sharing','mous_stimuli_share'))

%FIXME: computedata not necessary but mous_erf_sentences script will be
%shared for information (but will not be functional because of missing
%artifact definition files), mous_erf_sentences script needs to be checked
%for commented out code.
if computedata
    for k = 1:numel(subj)
        data = mous_erf_sentences(subj{k}, 1);
        save(sprintf(fullfile(derivativedir,'%s_meg_multisetcca_data'),subj{k},subj{k}), 'data');
    end
end

% FIXME: This part should be included in the mous_erf_sentences script as it
% concludes preprocessing
if cleandata
    for k = 1:numel(subj)
        mous_db_getdata(subj{k}, 'meg_multisetcca_data');
        cfg = [];
        cfg.method = 'summary';
        cfg.keeptrial = 'nan';
        cfg.channel = 'MEG';
        data = ft_rejectvisual(cfg, data);
        save(sprintf(fullfile(derivativedir,'%s_meg_multisetcca_data'),subj{k},subj{k}), 'data');
    end
end

%Loads sourcemodel&headmodel file:
%meg_anatomy_sourcemodel2D_surfreg
%A2006vol.mat
%FIXME: Will we share mous_anatomy_pipeline with it or share the models directly?
if dolcmv
    for k = 1:numel(subj)
        mous_db_getdata(subj{k}, 'meg_multisetcca_data');
        [source_parc, filterlabel] = mous_multisetcca_lcmv(subj{k}, data);
        save(sprintf(fullfile(derivativedir,'%s_meg_multisetcca_lcmv_parc'),subj{k},subj{k}), 'source_parc', 'filterlabel');
    end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Pre-compute Shuffling order for permutation tests %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if create_shuffle_indx
    mous_db_getdata(subj{1},'meg_multisetcca_groupinfo');
    for m = 1:500
        [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
        save(fullfile(resultsdir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
        clear reorder stimid;
    end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Multiset-CCA (& time-resolved correlations) %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
%The following chunk of code does a 'searchlight' based multisetcca, where
%the searchlight is defined as the 5-component timecourse, describing a
%parcel, indicated with parcel_indx. It uses the same initialization of the
%random number generator, thus allowing identical folding across parcels,
%that can therefore be meaningfully compared post-hoc. The shuffling
%schemes implemented obeys the approximate timing information of the word
%onsets across stimulation modalities.

if domscca_searchlight
    
    if ~exist('nfold', 'var'),          nfold          = 5;       end
    if ~exist('nrand', 'var'),          nrand          = 100;     end
    if numel(nrand)==1,                 nrand          = 1:nrand; end % nrand is expected to be a vector of indices that point to a indexed file that contains the precomputed shuffle (to ensure same shuffling across parcels)
    
    groupdata     = cell(1,numel(subj));
    subjectdata   = cell(1,numel(subj));
    subjecttiming = cell(1,numel(subj));
    for k = 1:numel(subj)
        
        % load in the data FIXME: change paths to load from shared
        % structure
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_data.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_timinginfo.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_groupinfo.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_lcmv_parc.mat'),subj{k},subj{k}))
        
        source_parc.filterlabel = filterlabel; % for checking channel order
        
        % convert the sensor-level data into  parcel-level data, for the
        % requested
        subjectdata{k}   = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
        subjecttiming{k} = timinginfo; % subject specific information about timing
        
        if strncmp(subj{k}, 'A', 1)
            % align the trials' time axes to the onset of the first word, rather
            % than the onset of the audio file
            tmp = subjectdata{k}.time;
            stim_id = subjectdata{k}.trialinfo(:,end);
            for kk = 1:numel(tmp)
                tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
                tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
            end
            subjectdata{k}.time = tmp;
        end
        for kk = 1:numel(subjectdata{k}.trial)
            tmp = subjectdata{k}.trial{kk};
            tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
            subjectdata{k}.trial{kk} = tmp;
        end
        % align the subject-specific parcel data to match all other subjects
        % in terms of timing and trial-order
        groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo);
        
        cfg            = [];
        cfg.method     = 'acrosschannel';
        groupdata{k} = ft_channelnormalise(cfg, groupdata{k});
        for kk = 1:numel(groupdata{k}.trial)
            sel = nearest(groupdata{k}.time{kk},-0.1);
            groupdata{k}.trial{kk} = groupdata{k}.trial{kk}(:,sel:end);
            groupdata{k}.time{kk}  = groupdata{k}.time{kk}(sel:end);
        end
    end % for k of subj
    
    rng('default'); % reset the number generator, in order to be able to compare across parcels
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata(:), subj); % first row only
    
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 4, []);
    
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    
    trc                  = mous_multisetcca_trc(comp, stimuli);
    
    comp                 = ft_struct2single(comp);
    
    savedir = sprintf(fullfile(resultsdir,'scenario%d'), scenario);
    system(sprintf('mkdir -p %s', savedir));
    
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d',scenario,parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'trc');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% compute the shuffled version: %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % unfold the audio data to maintain word onsets across modalities,
    % but after swapping sentences
    selaudio = find(strncmp(subj, 'A', 1) | contains(subj, 'sub-2'));
    selvis   = find(strncmp(subj, 'V', 1) | contains(subj, 'sub-1'));
    groupdatashuf = groupdata;
    
    cnt = 0;
    for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        
        load(fullfile(resultsdir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m))); % use precomputed ordering for consistency across parcels
        
        groupdatashuf(selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(selaudio), subjecttiming(selaudio), groupinfo, reorder, stimid);
        
        for k = 1:numel(groupdatashuf)
            for kk = 1:numel(groupdatashuf{k}.trial)
                sel = nearest(groupdatashuf{k}.time{kk},-0.1);
                groupdatashuf{k}.trial{kk} = groupdatashuf{k}.trial{kk}(:,sel:end);
                groupdatashuf{k}.time{kk}  = groupdatashuf{k}.time{kk}(sel:end);
            end
        end
        % perform the cca
        tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf, subj);
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(tmpdata, nfold, 4, []);
        [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        trctmp = mous_multisetcca_trc(compshuf, stimuli, 'contentwords_only', contentwords_only);
        if cnt==1
            trcshuf = trctmp;
        else
            trcshuf.rho(:,:,cnt) = trctmp.rho;
        end
        Rshuf(1,1,cnt)         = single(mean(mean(rhoshuf(selvis,selvis,1))))-1./numel(selvis);
        Rshuf(1,2,cnt)         = single(mean(mean(rhoshuf(selvis,selaudio,1))));
        Rshuf(2,1,cnt)         = single(mean(mean(rhoshuf(selaudio,selvis,1))));
        Rshuf(2,2,cnt)         = single(mean(mean(rhoshuf(selaudio,selaudio,1))))-1./numel(selaudio);
        
    end
    
    trcshuf = ft_struct2single(trcshuf);
    
    filename = fullfile(resultsdir,sprintf('scenario%d',scenario), sprintf('mscca_sce%d_parcel%03dshuf2',scenario,parcel_indx));
    save(filename,'Rshuf','trcshuf', 'nrand');
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Time-resolved correlations based on canonincal components %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if dotrc
    % do time resolved correlation on canonical components
    nrand = 1000;
    filename = sprintf(fullfile(resultsdir,'scenario%d', 'mscca_sce%d_parcel%03d'),scenario,scenario,parcel_indx);
    
    %load data
    load(filename, 'comp');
        
    %compute trc for observed data
    [trc, tlck] = mous_multisetcca_trc(comp, stimuli, 'dosmooth', 5, 'contentwords_only', 1, 'output2', 'single_cross');
    
    %compute trc for shuffled data
    bin = ones(size(tlck.trial,1),1);
    selaudio = find(contains(tlck.label, 'A2') | contains(tlck.label, 'sub-2'));
    selvis   = find(contains(tlck.label, 'V1') | contains(tlck(1).label, 'sub-1'));
    %permute trials in both visual & auditory modality, for each subject
    %respectively
    rng('default'); % ensure same 'random' behaviour for each parcel
    for m = 1:nrand
        if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
        tmptlck = tlck;
        for mmv = 1:numel(selvis)
            r_idx = (1:numel(bin))';
            ubin  = unique(bin);
            for mm = 1:numel(ubin)
                tmpB = r_idx(bin==ubin(mm));
                r_idx(bin==ubin(mm)) = tmpB(randperm(numel(tmpB)));
            end
            tmptlck.trial(:,selvis(mmv),:) = tmptlck.trial(r_idx,selvis(mmv),:);
        end
        for mma = 1:numel(selaudio)
            r_idx = (1:numel(bin))';
            ubin  = unique(bin);
            for mm = 1:numel(ubin)
                tmpB = r_idx(bin==ubin(mm));
                r_idx(bin==ubin(mm)) = tmpB(randperm(numel(tmpB)));
            end
            tmptlck.trial(:,selaudio(mma),:) = tmptlck.trial(r_idx,selaudio(mma),:);
        end
        trcshuf2(m) = mous_multisetcca_trc(tmptlck, stimuli, 'output2', 'single_cross');
    end
    trcshuf2(1).rho = cat(3,trcshuf2(:).rho);
    trcshuf2 = trcshuf2(1);
    
    if contentwords_only
        suffix_out = '_sent_contentwords';
    end
    filename = sprintf(fullfile(resultsdir,'scenario%d','mscca_sce%d_parcel%03d_trc%s'),scenario,scenario,parcel_indx,suffix_out);
    save(filename, 'trcshuf2','trc');
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Time-resolved correlations based on source time courses %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if dotrc_prior
    % For the modality-specific results we computed the time-resolved
    % correlations both prior and after MCCA-transformation (for scenario 1 only). The following
    % code does the trc on the source data prior to MCCA and then saves the
    % result together with the post-MCCA correlations
    % We specifically compared three parcels: 175 BA17 visual, 95 BA43 subcentral, 126 B42 primary auditory
    
    for k = 1:numel(subj)
        
        % load in the data
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_data.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_timinginfo.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_groupinfo.mat'),subj{k},subj{k}))
        load(sprintf(fullfile(derivativedir,'%s_multisetcca_lcmv_parc.mat'),subj{k},subj{k}))
        
        source_parc.filterlabel = filterlabel; % for checking channel order
        subjectdata{k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
        subjecttiming{k} = timinginfo; % subject specific information about timing
        if strncmp(subj{k}, 'A', 1)
            tmp = subjectdata{k}.time;
            stim_id = subjectdata{k}.trialinfo(:,end);
            for kk = 1:numel(tmp)
                tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
                tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
            end
            subjectdata{k}.time = tmp;
        end
        for kk = 1:numel(subjectdata{k}.trial)
            tmp = subjectdata{k}.trial{kk};
            tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
            subjectdata{k}.trial{kk} = tmp;
        end
        groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo);
        
        cfg            = [];
        cfg.method     = 'acrosschannel';
        groupdata{k} = ft_channelnormalise(cfg, groupdata{k});
        for kk = 1:numel(groupdata{k}.trial)
            sel = nearest(groupdata{k}.time{kk},-0.1);
            groupdata{k}.trial{kk} = groupdata{k}.trial{kk}(:,sel:end);
            groupdata{k}.time{kk}  = groupdata{k}.time{kk}(sel:end);
        end
    end
    tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata(1,:), subj); % first row only
    for i = 1:length(tmpdata.trial)
        tmpdata.trial{i} = tmpdata.trial{i}(1:5:165,:);
    end

    tmpdata.label = tmpdata.label(1:5:165);
    trc_pre       = mous_multisetcca_trc(tmpdata, stimuli);
    
    %combine with post-mscca results and save together. Note that results
    %will be overwritten when computing this for different scenarios.
    load(sprintf(fullfile(resultsdir,'scenario%d','mscca_sce%d_parcel%03d_trc.mat'),scenario,scenario,parcel_indx),'trc','trcshuf2')
    save(sprintf(fullfile(resultsdir,'trc_data','trcdata_parcel%03d',parcel_indx)), 'trc_pre', 'trc', 'trcshuf2');
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Stats %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if do_clusterstats
        
    % 1) based on shuffling of words after MCCA (This version has been
    % computed for all scenarios and output will be used by next step
    % mous_multisetcca_prevalence
    
    trcname = '_sent_contentwords';
    [s, T, Tshuf] = mous_multisetcca_stats(sprintf(fullfile(resultsdir,'scenario%d'),scenario),scenario,'trcname', trcname,'shufflefname',trcname);
    
    filename = sprintf(fullfile(resultsdir, 'scenario%d','scenario%d_results_sent_contentwords'),scenario,scenario);
    save(filename, 's', 'T', 'Tshuf');

    % 2) based on shuffling of sentences pre-MCCA (control analysis only computed for scenario 1)
    if scenario == 1
        trcname = '';
        [s, T, Tshuf] = mous_multisetcca_stats(sprintf(fullfile(resultsdir,'scenario%d'),scenario),scenario,'trcname', trcname,'shufflefname','shuf2');
        
        filename = sprintf(fullfile(resultsdir, 'scenario%d','scenario%d_results_sent_shuf2',scenario,scenario));
        save(filename, 's', 'T', 'Tshuf');
    end
end

%% 

if do_prevalence
    % For results of the confirmatory analysis, we combined the correlatinos across groups and used prevalence
    % statistics to evaluate the robustness of the supramodal effect.
    % Averaging and stats are computed within mous_multisetcca_prevalence
    % and saved to disk
    mous_multisetcca_prevalence(resultsdir,resultsdir,6) % combine over all 6 scenarios
end

