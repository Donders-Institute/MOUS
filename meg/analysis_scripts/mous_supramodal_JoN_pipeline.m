% This script contains the full analysis pipeline corresponding to our
% article "Sensory Modality-Independent Activation of the Brain Network
% for Language" in Journal of Neuroscience
% DOI: htpps://doi.org/10.1523/JNEUROSCI.2271-19.2020

% In addition to FieldTrip functions, this script calls the following custom matlab files:
% mous_multisetcca_lcmv
% mous_multisetcca_createshuffle
% cellcolselect
% mous_multisetcca_sensor2parcel
% mous_multisetcca_getparceldata
% mous_multisetcca_groupdata2singlestruct
% mous_multisetcca
% mous_multisetcca_postprocess
% mous_multisetcca_coh
% mous_multisetcca_trc
% ft_struct2single
% mous_multisetcca_reorderaudio

% For source reconstruction:


% intermediate & final results are saved in:
% /project/3011020.09/processed/XXXX/meg/multisetcca/XXX_multisetcca_XX.mat
% /project/3011020.09/sopara/supramodal_JoN/clusterstats
% /project/3011020.09/sopara/supramodal_JoN/prevalence

rootdir          = '/project/3011020.09';
derivativedir    = '/project/3011020.09/processed/%s/meg/multisetcca/';
resultsdir       = '/project/3011020.09/sopara/supramodal_JoN/';

load(fullfile(resultsdir,'sharing','mous_stimuli_share'))

suffix = ''; %no suffix will load only data of the sentence condition rather than wordlist conditino (suffix = "_seq")

%This script is divided in different analysis steps some of which will be
%computed per subject, others per parcel, others per scenario.
% They can be called individually as well by setting the following flags:

if ~exist('create_shuffle_indx',  'var'), create_shuffle_indx = false;end % create set of files that have pre-cooked randomization sequences
if ~exist('do_prevalence',      'var'), do_clusterstats     = true; end
if ~exist('do_clusterstats',      'var'), do_clusterstats     = true; end

% analysis done per scenario
if ~exist('computedata',      'var'), computedata      = false;  end % create sensor-level data structure
if ~exist('cleandata',        'var'), cleandata        = false;                       end % manual step (rejectvisual) to clean data
if ~exist('dolcmv',           'var'), dolcmv           = false;                       end % compute spatial filters
if ~exist('computealignment', 'var'), computealignment = false;                       end % compute timing information necesseary for temporal alignment
if computedata || cleandata || dolcmv || computealignment
    if ~exist('scenario',         'var'), error('a scenario index needs to be specified');   end
end

%analysis done per scenario / per parcel_indx
if ~exist('domscca_searchlight',  'var'), domscca_searchlight = true; end % various mscca flavours
if ~exist('dotrc',                'var'), dotrc               = true; end
if ~exist('dotrc_prior',          'var'), dotrc_prior         = true; end
if domscca_searchlight || dotrc || dotrc_prior
    if ~exist('scenario',         'var'), error('a scenario index needs to be specified');   end
    if ~exist('parcel_indx', 'var'),    error('a parcel index needs to be specified');  end
end

%%%%% Beginning analysis script %%%%%

%Retrieving all subject IDs belonging to specified scenario
%FIXME: Either we share data in subfolders per scenario or we need to have
%a file that lists the correspondance
if exist('scenario', 'var')
    subj = mous_db_getfilename('allAV', 'subjectname');
    sce  = mous_db_getfilename(subj,    'scenario');
    sel  = false(numel(subj,1));
    for m = 1:numel(scenario)
        sel = strncmp(sce, num2str(scenario(m)), 1) | sel;
    end
    subj = subj(sel);
    sce  = sce(sel);
end

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

% This part should be included in the mous_erf_sentences script as it
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
%Will we share mous_anatomy_pipeline with it or share the models directly?
if dolcmv
    for k = 1:numel(subj)
        mous_db_getdata(subj{k}, 'meg_multisetcca_data');
        [source_parc, filterlabel] = mous_multisetcca_lcmv(subj{k}, data);
        save(sprintf(fullfile(derivativedir,'%s_meg_multisetcca_lcmv_parc'),subj{k},subj{k}), 'source_parc', 'filterlabel');
    end
end

% Uses:
% s_multisetcca_timinginfo.mat, which contains information of how to adjust
% the timing of individual words in order to correct for some variability
% during presentation. The structure contains the following
% info:
% trials: trial index where a trial corresponds to a sentence
% smpin: 
% smpout:
% time: time info for all samples of each sentence
% trialinfo: sentence index (col1), sentence conditions (col2 + col3), pre-sentence samples ??
% (col4), sentence ID ?? (col5)

% s_multisetcca_groupinfo.mat
% trialid: sentence index
% ntrl: number of trials/sentences
% sel: which trials are available (clean??) from which subjects 
% nsmp: number of samples per sentence and subject
% begtim: time at sample 0 per sentence and subject
% endtim: time at final sample per sentence and subject
% maxnsmp: maximum number of sample per sentence across subjects
% mintim: earliest time point per sentence across subjects
% maxtim: latest time point per sentence across subjects
% subj: all subjects belonging to this scenario
% stiminfo:
%   id: sentence id
%   string: sentence as string
%   words: information on each word within sentence (FIXME: needs pruning before sharing!)
%   timinginfo: word index (col1), onset time in s (col2) for auditory
%   presentation
%   timinginfo_visual: word index(col1), onset time in s (col2) for visual
%   presentation

if create_shuffle_indx
    mous_db_getdata(subj{1},'meg_multisetcca_groupinfo');
    for m = 1:500
        [reorder, stimid]       = mous_multisetcca_createshuffle(groupinfo);
        save(fullfile(resultsdir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m)),'reorder','stimid'); % use precomputed ordering for consistency across parcels
        clear reorder stimid;
    end
end


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
        mous_db_getdata(subj{k}, 'meg_multisetcca_data');
        mous_db_getdata(subj{k}, 'meg_multisetcca_timinginfo');
        mous_db_getdata(subj{k}, 'meg_multisetcca_lcmv_parc');
        mous_db_getdata(subj{k}, 'meg_multisetcca_groupinfo');
        
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
        % align the subject-specific parcel data to match all others subjects
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
    
    [W, A, rho, C, comp] = mous_multisetcca(tmpdata, nfold, 4, [],false);
    
    [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
    
    trc                  = mous_multisetcca_trc(comp, stimuli);
    
    comp                 = ft_struct2single(comp);
    
    savedir = sprintf(fullfile(resultsdir,'scenario%d'), scenario);
    system(sprintf('mkdir -p %s', savedir));
    
    filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03d',scenario,parcel_indx));
    save(filename, 'rho', 'W', 'A', 'comp', 'trc');
    
    %compute the shuffled version
    
    % unfold the audio data to maintain word onsets across modalities,
    % but after swapping sentences
    if ~exist('contentwords_only', 'var'),contentwords_only = false;                      end
    if contentwords_only, suffix_out = [suffix_out '_content']; end
    
    selaudio = find(strncmp(subj, 'A', 1) | contains(subj, 'sub-2'));
    selvis   = find(strncmp(subj, 'V', 1) | contains(subj, 'sub-1'));
    groupdatashuf = groupdata;
    
    cnt = 0;
    for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        paramdir = '/project/3011020.09/jansch/mscca_group/';
        
        load(fullfile(paramdir,'params',sprintf('shuff_sce%d_indx%04d',scenario,m))); % use precomputed ordering for consistency across parcels
        
        groupdatashuf(selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(selaudio), subjecttiming(selaudio), groupinfo, reorder, stimid, shift, stretch);
        
        for k = 1:numel(groupdatashuf)
            for kk = 1:numel(groupdatashuf{k}.trial)
                sel = nearest(groupdatashuf{k}.time{kk},-0.1);
                groupdatashuf{k}.trial{kk} = groupdatashuf{k}.trial{kk}(:,sel:end);
                groupdatashuf{k}.time{kk}  = groupdatashuf{k}.time{kk}(sel:end);
            end
        end
        % perform the cca
        tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf, subj);
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(tmpdata, nfold, 4, [], false);
        [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        cfg = [];
        cfg.trials = compshuf.trialinfo(:,end)<=500;
        compshufsel = ft_selectdata(cfg,compshuf);
        trctmp = mous_multisetcca_trc(compshufsel, stimuli, 'contentwords_only', contentwords_only);
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
    
    filename = fullfile(rootdir,'jansch','mscca_group',sprintf('scenario%d',scenario), sprintf('mscca_sce%d_parcel%03dshuf2%s',scenario,parcel_indx,suffix_out));
    
    if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Rshuf = cat(3,tmp.Rshuf,Rshuf);
        trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
        if isfield(tmp, 'nrand')
            nrand = cat(1,tmp.nrand(:),nrand(:));
        else
            nrand = cat(1,nan*ones(size(tmp.Cshuf,3),1),nrand(:));
        end
    end
    trcshuf = ft_struct2single(trcshuf);
    save(filename,'Rshuf','trcshuf', 'nrand');
    
end
%--------------------------------------------------------------------------

if dotrc
    % do time resolved correlation on canonical components
    
    %% set default flags if necessary
    if ~exist('stimuli', 'var'),          load mous_stimuli;                              end
    if ~exist('contentwords_only', 'var'),contentwords_only = true;                      end
    %%
    suffix_out = '_sent';
    
    nrand = 1000;
    
    filename = sprintf(fullfile(resultsdir,'scenario%d', 'mscca_sce%d_parcel%03d',scenario,scenario,parcel_indx));
    load(filename, 'comp');
    
    cnt = 0;
    
    cnt = cnt+1;
    cfg = [];
    cfg.trials = find(comp.trialinfo(:,end)<= 500);
    tmp(cnt) = ft_selectdata(cfg,comp);
    
    comp = tmp;
    for k = 1:numel(comp)
        tlck(k) = mous_multisetcca_extractwords(comp(k), stimuli);
    end
    
    for k = 1:numel(tlck)
        [trc(k), tlck] = mous_multisetcca_trc(tlck(k), stimuli, 'dosmooth', 5, 'contentwords_only', 1, 'longwords_only', 0, 'output2', 'single_cross');
    end
    
    selaudio = find(contains(tlck(1).label, 'A2') | contains(tlck(1).label, 'sub-2'));
    selvis   = find(contains(tlck(1).label, 'V1') | contains(tlck(1).label, 'sub-1'));
    
    %permute trials in both visual & auditory modality, for each subject
    %respectively
    rng('default'); % ensure same 'random' behaviour for each parcel
    for m = 1:nrand
        if mod(m,50)==0,fprintf('running randomization %d/%d\n',m,nrand);end
        tmptlck = tlck;
        for mmm = 1:numel(tlck)
            for mmv = 1:numel(selvis)
                r_idx = (1:numel(bin{mmm}))';
                ubin  = unique(bin{mmm});
                for mm = 1:numel(ubin)
                    tmpB = r_idx(bin{mmm}==ubin(mm));
                    r_idx(bin{mmm}==ubin(mm)) = tmpB(randperm(numel(tmpB)));
                end
                tmptlck(mmm).trial(:,selvis(mmv),:) = tmptlck(mmm).trial(r_idx,selvis(mmv),:);
            end
            for mma = 1:numel(selaudio)
                r_idx = (1:numel(bin{mmm}))';
                ubin  = unique(bin{mmm});
                for mm = 1:numel(ubin)
                    tmpB = r_idx(bin{mmm}==ubin(mm));
                    r_idx(bin{mmm}==ubin(mm)) = tmpB(randperm(numel(tmpB)));
                end
                tmptlck(mmm).trial(:,selaudio(mma),:) = tmptlck(mmm).trial(r_idx,selaudio(mma),:);
            end
            trcshuf2(m,mmm) = mous_multisetcca_trc(tmptlck(mmm), stimuli, 'output2', 'single_cross');
        end
    end
    
    for m = 1:size(trcshuf,2)
        trcshuf2(1,m).rho = cat(3,trcshuf2(:,m).rho);
    end
    trcshuf2 = trcshuf2(1,:);
    
    if ~exist('suffix2', 'var')
        suffix_out = '';
    end
    if contentwords_only
        suffix_out = [suffix_out '_contentwords'];
    end
    filename = fullfile(sprintf(resultsdir,'scenario%d','mscca_sce%d_parcel%03d_trc%s',scenario,scenario,parcel_indx,suffix_out));
    save(filename, 'trcshuf2','trc');
    
end

if dotrc_prior
    % For the modality-specific results we computed the time-resolved
    % correlations both prior and after MCCA-transformation. The following
    % code does the trc on the source data prior to MCCA.
    if ~exist('stimuli', 'var'),          load mous_stimuli;
        scenario = 1; % Doing this only for the first scenario
        parcel_indx = 126; % run this part for parcels: 175 BA17 visual, 95 BA43 subcentral, 126 B42 primary auditory
        
        subj = mous_db_getfilename('allAV', 'subjectname');
        sce  = mous_db_getfilename(subj,    'scenario');
        sel  = false(numel(subj,1));
        for m = 1:numel(scenario)
            sel = strncmp(sce, num2str(scenario(m)), 1) | sel;
        end
        subj = subj(sel);
        sce  = sce(sel);
        
        for k = 1:numel(subj)
            
            % load in the data
            mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s', ''));
            mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',''));
            mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc%s',  ''));
            groupinfo = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',''));
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
        save(sprintf('/project/3011020.09/sopara/trc_data/trcdata_parcel%03d',parcel_indx), 'trc_pre', 'trc', 'trcshuf2');
    end
    
    
    %--------------------------------------------------------------------------
    if do_clusterstats
        
        scenario = 1; %cluster-based permutation test have only been computed for first scenario
        
        % Stats have been computed twice
        % 1) based on shuffling of words after MCCA
        
        trcname = '_sent_contentwords';
        [s, T, Tshuf] = mous_multisetcca_stats(datadir,scenario,'trcname', trcname,'shufflefname',trcname);
        
        filename = sprintf(fullfile(resultsdir, 'scenario%d','scenario%d_results_sent',scenario,scenario));
        save(filename, 's', 'T', 'Tshuf');
        
        % 2) based on shuffling of sentences pre-MCCA
        trcname = '';
        [s, T, Tshuf] = mous_multisetcca_stats(datadir,scenario,'trcname', trcname,'shufflefname','shuf2');
        
        
        filename = sprintf(fullfile(resultsdir, 'scenario%d','scenario%d_results_sent_shuf2',scenario,scenario));
        save(filename, 's', 'T', 'Tshuf');
    end
    %--------------------------------------------------------------------------
    
    if do_prevalence
        mous_multisetcca_prevalence(6)
    end
