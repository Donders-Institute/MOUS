%function mous_corrmnebf_cormat(subjectname,param)

param.range       = 'medium';
param.foi         = 16;        
param.toie        = [0.35 0.45];  % toi for ERFs
param.selfq       = [-0.12 -0.08];
param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
param.suff        = num2str(param.foi);   
param.savebf      = regexprep([num2str(mean(param.selfq))],'[.]','');
param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 

% CONSIDERME: build in functionality to toggle on/off regressing word order and
% fisher transformation, and in turn update filenames being saved

doselfreq                   = true;
doselerf                    = true; 
domatch                     = true;   
domnesingle_beam_reg_cor    = true;  % calculate beamforming solution, regress word order and then calc correlation matrix

if doselfreq
    %% OSCILLATIONS select frequency 

    rootdir = '/home/language/jansch/public/mous/';      % all the low frequencies, where freq.freq = [2.5 5 7.5 10 12]
    mous_db_getdata(subjectname,['meg_bfica_freq_',param.range],rootdir);
    freq = ft_selectdata(freq,'foilim',param.foi*[1 1]);

    warning off;
    freq   = ft_struct2double(freq);
    warning on;

    cfg = [];
    cfg.latency = [param.selfq(1) param.selfq(2)];  
    freq        = ft_selectdata(cfg,freq); 
    idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
    freq        = ft_selectdata(freq,'rpt',idxful);  
end 

if doselerf
    %% ERF select only the sentences and baseline normalise
    mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); 

    % calc baseline
    all = size(data.trial,2);
    bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
    bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)

    % apply baseline (normalize); adjust baseline to fit each trial's dimensions)
    for k = 1:size(data.trial,2)
        rows = 1; columns = size(data.trial{k},2);  % matrix dim for each trial
        bslrep = repmat(bslavgVec, [rows columns]); % replicate bslvector to fit size of toi trials
        data.trial{k} = data.trial{k}-bslrep;     
    end

    % select toi 
    cfg = [];
    cfg.latency = [param.toie(1) param.toie(2)];  % cfg.latency instead of cfg.toilim
    data       = ft_selectdata(cfg,data);     

    % take only trials with full number of samples (no artifacts removed)
    erftime = param.toie(2) - param.toie(1);
    tmp = floor(erftime*300); % make integer instead of with decimals i.e. XX.000)
    corrsmp = [tmp tmp+1];    % because of matlab rounding/nearest function/precision issues, will take trials that have 300 or 301 samples
    nsmp = cellfun('size',data.trial,2);

    fulltrial = find(ismember(nsmp,corrsmp));    
    data = ft_selectdata(data,'rpt',fulltrial);
end 

if domatch
    %% match trials between ERFs and TFRs
    % find matching trials
    erf = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
    tfr = freq.trialinfo(:,1)*1000+freq.trialinfo(:,5);  
    [comm, ierf, itfr] = intersect(erf, tfr);    % comm = same trials in both

    % exclude non-matching trials from both datasets
    freq = ft_selectdata(freq,'rpt',itfr);
    data = ft_selectdata(data,'rpt',ierf);    
    clear comm itfr ierf

    %% match number of trials between conditions (sent and seq) for each measure (ERF, Osc) separately
    T = freq.trialinfo(:,2);
    sel1 = find(ismember(T, [1 2 5 6])); n1 = numel(sel1);
    sel2 = find(ismember(T, [3 4 7 8])); n2 = numel(sel2);

    n = min(n1,n2);  % previous n = minimum number of trials compared between sent and seq, across all subjs. 
    tmp1 = randperm(n1);
    tmp2 = randperm(n2);
    sel1 = sel1(sort(tmp1(1:n)));
    sel2 = sel2(sort(tmp2(1:n)));

    freqSen = ft_selectdata(freq, 'rpt', sel1);
    freqSeq = ft_selectdata(freq, 'rpt', sel2); 
    
    freqin = cell(2,1);
    freqin{1} = freqSen; freqin{2} = freqSeq;

    %% having determine the trials using freq data, select same trials for ERF data 
    % SENTENCES
    erfSen = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
    tfrSen = freqSen.trialinfo(:,1)*1000+freqSen.trialinfo(:,5);  
    [comm, ierf, itfr] = intersect(erfSen, tfrSen);    % comm = same trials in both
    dataSen = ft_selectdata(data,'rpt',ierf);	       % select same ones for dataSen

    % SEQUENCES
    erfSeq = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
    tfrSeq = freqSeq.trialinfo(:,1)*1000+freqSeq.trialinfo(:,5);  
    [comm, ierf, itfr] = intersect(erfSeq, tfrSeq);    % comm = same trials in both
    dataSeq = ft_selectdata(data,'rpt',ierf);          % select same ones for dataSeq

    datin = cell(2,1);
    datin{1} = dataSen; datin{2} = dataSeq;
end

if domnesingle_beam_reg_cor
    %% Calc MNE, Beamformer, regress word order and calculate correlation matrix
    
    % MNE:
        % Noise covariance matrix is calculate using stimuli from all cdtn (so sent and seq have same noise cov mat)
        % MNE estimate averaged across all trials DOES differ between cdtns

    for mm = 1:2  % first loop = sentences; second loop = sequences
        
        %%%%%%%%%%%%%%% BEAMFORMING SOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%
        freqin{mm}.calc = 1;
        freqin{mm} = rmfield(freqin{mm},'time');
        freqin{mm}.dimord = 'rpttap_chan_freq'; 
        [source, trialinfo] = mous_bfica_source(subjectname, freqin{mm}, param.toi, 8);  % source is needed in mous_corrmnebf_interpolate, not an immediate next step, therefore save.

        freqin{mm}.cumtapcnt = ones(size(freqin{mm}.fourierspctrm,1),1);
        sourcedata = mous_bfica_sourcedata(source, freqin{mm});                          % sourecedata is needed to calculate correlation matrix, which is the immediate next step

        if mm == 1
            mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'source','trialinfo');
        else
            mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],'source','trialinfo');
        end  
        
        clear source
        
        %%%%%%%%%%%%%%% MINIMUM NORM ESTIMATES %%%%%%%%%%%%%%%%%%%%%%
        
        if mm == 1   
            mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent}');
            sd = sd_Sent;
        elseif mm == 2;
            mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq}');
            sd = sd_Seq;
        end 
        
        % create the vertex x channel spatial filter matrix
        mnefilter = zeros(size(sd.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
        for k = 1:size(mnefilter,1)
          if ~isempty(sd.avg.ori{k}) 
            mnefilter(k,:) = sd.avg.ori{k}*sd.avg.filter{k};    
          else
            mnefilter(k,:) = nan;  % some sources are on edge of sourcemodel.inside / outside of sourcemodel.inside
          end
        end

        channel   = {'MEG', '-EEG057', '-EEG058'};   % remove unwanted channels
        datin{mm} = ft_selectdata(datin{mm},'channel',channel);
        
        % timelock all trials to use for leave-one-out estimate
        cfg = [];
        tlck = ft_timelockanalysis(cfg, datin{mm});   % tlck avg of all toi sentences
        mnetlck = mnefilter*tlck.avg;
        nword   = numel(datin{mm}.trial);

        vertM = nan(size(mnefilter,1), numel(datin{mm}.trial)); % MNE filter for jack knife
        for k = 1:numel(datin{mm}.trial)
            tmp = (mnetlck.*nword-mnefilter*datin{mm}.trial{k})./(nword-1); % leave-one-out estimate
            tmp = nanmean(abs(tmp),2);
            vertM(:,k) = tmp;  % Vertices(8196) by Trials (words: number varies depending on artifact rejection and MEG condition)
        end
        
              
        %%%%%%%%%%%%%%% REGRESS WORD ORDER ; CORRELATION MATRIX %%%%%%% 
        % remove trials with NaNs
        voxM  = sourcedata.trial{1};     
        idxNan = find(isnan(voxM(1,:))); % which column (trial) has NaN
        if ~isempty(idxNan)
            voxM(:,idxNan) = [];
            vertM(:,idxNan) = [];
        end
        
%         idxNan = find(isnan(vertM(:,1))); % which column
%         if ~isempty(idxNan)
%             voxM(idxNan,:) = [];
%             vertM(idxNan,:) = [];
%         end

        % compute leave-one-out etimates for the oscillations (leave-one-out estimates for mne are done within do mnesingle)
        voxMsum = sum(voxM,2);
        voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);
 
        [voxM, vertM] = mous_corrmnebf_regression(voxM, vertM);
                
        [cor] = mous_corrmnebf_computecormat(voxM, vertM, trialinfo); % check correct trialinfo is given

        if mm == 1
            mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'cor'); 
        elseif mm == 2
            mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],'cor'); 
        end 
    end 
end
