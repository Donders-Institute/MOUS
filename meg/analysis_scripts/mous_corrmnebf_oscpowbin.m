%function mous_corrmnebf_oscpowbin(subjectname)

% this is a version of mous_corrmnebf_cormat in which oscillatory trials
% are sorted by magnitude of power at pre-stimulus (word) onset.
% (1) For each power bin then a Beamforming and MNE solution is produced 
%      note: 20 powerbins per subject (keep track of power ranges for each bin!)
% For each bin specific MNE (event-related) solution and BF (oscillatory)
% solution a vector is produced:
%    beamformer: 27 voxels by 1 bin (avg'd trials) = currbinbf
%    MNE: 8196 vertices by 1 bin (avg'd trials) = currbinmne
% (2) Each bin's solution is then compiled into a voxM and a vertM:
% voxM = 27 voxels * 20 bins
% vertM = 8196 vertices * 20 bins
% (3) averaged word order (of trials from each bin) is regressed out of
% voxM and vertM respectively
% (4) the correlation matrix (cor) is calculated:  voxM*vertM';
% As we are dealing with bins, a fisher transform (used to standardise
% matrices for the number of trials contributed by each subject) is not
% performed.

% 16-8-2013 note: In the ERFs, the baseline is calculated for defined toi so that
% less resources are spent on projecting from sensor to source space. As
% the steps of applying baseline, averaing and toi are linear, the order
% shouldnt matter.  
% But if things don't work, we may want to try another order: apply baseline to entire trial, avg
% across trials, select toi. 


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
dobeam_oscpowbin_mnesingle_reg_cor    = true;  % calculate beamforming solution, regress word order and then calc correlation matrix

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
    
    % remove eogchannels
    channel = {'MEG', '-EEG057', '-EEG058'};   % remove unwanted channels
    data = ft_selectdata(data,'channel',channel);
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

if dobeam_oscpowbin_mnesingle_reg_cor
    %% Calc Beamformer, bin oscillations by power, use those trials for MNEs,regress word order and calculate correlation matrix
        % FOR MNE the noise covariance matrix is calculate using stimuli from all cdtn (so sent and seq have same noise cov mat)
        % MNE estimate averaged across all trials DOES differ between cdtns
    
    %%%%%%%%%%% PARAMETER DEFINITION FOR ROI SELECTION %%%%%%%%%%
    % define ROIs
    roi(1).x = 6;    
    roi(1).y = 7;
    roi(1).z = 17;
    roi(1).seed = 'TFRseed';
    roi(1).area = 'Lparietal';

    roi(2).x = 16;   
    roi(2).y = 8;
    roi(2).z = 17;
    roi(2).seed = 'TFRseed';
    roi(2).area = 'Rparietal2';

    roi(3).x = 7; 
    roi(3).y = 20;
    roi(3).z = 16;
    roi(3).seed = 'TFRseed';
    roi(3).area = 'Lfrontal2';

    roi(4).x = 5;
    roi(4).y = 17;
    roi(4).z = 17;
    roi(4).seed = 'TFRseed';
    roi(4).area = 'Rfrontal2';

    % get sourcemodel
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);

    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], & limit the inside sources
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen']);
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
        sourcemodel = rmfield(sourcemodel,'cfg');
    end
    rmf = {'xgrid','ygrid','zgrid','unit'}; sourcemodel = rmfield(sourcemodel,rmf);

    load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord.mat
        
    for ccnt = 1:2  % ccnt = condition counter;  % 1 = sentences; 2 = sequences
        
        %%%%%%%%%%%%%%% BEAMFORMING SOLUTION FOR OSCPOWBIN %%%%%%%%%%%%%%%%%%%%%%%%%
        freqin{ccnt}.calc = 1;
        freqin{ccnt} = rmfield(freqin{ccnt},'time');
        freqin{ccnt}.dimord = 'rpttap_chan_freq'; 
        [source, trialinfo] = mous_bfica_source(subjectname, freqin{ccnt}, param.toi, 8);  % source is needed in mous_corrmnebf_interpolate, not an immediate next step, therefore save.

        freqin{ccnt}.cumtapcnt = ones(size(freqin{ccnt}.fourierspctrm,1),1);
        sourcedata = mous_bfica_sourcedata(source, freqin{ccnt});                          % sourecedata is needed to calculate correlation matrix, which is the immediate next step

        if ccnt == 1
            mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_4powbin_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'source','trialinfo');
        else
            mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_4powbin_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],'source','trialinfo');
        end  
          
        %%%%%%%%%%%%%%% MNE SPATIAL FILTER defined %%%%%%%%%%%%%%%%%%%%%%
        if ccnt == 1   
            mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent}');
            sd = sd_Sent;
        elseif ccnt == 2;
            mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq}');
            sd = sd_Seq;
        end 

        % create the vertex x channel spatial filter matrix 
        mnefilter = zeros(size(sd.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
        for k = 1:size(mnefilter,1)
          if ~isempty(sd.avg.ori{k}) 
            mnefilter(k,:) = sd.avg.ori{k}*sd.avg.filter{k};
          else
            mnefilter(k,:) = nan; % some sources are on edge of sourcemodel.inside / outside of sourcemodel.inside
          end
        end
              
        % for each ROI, assign trials to bins and calculate source solution
        for rcnt = 1:numel(roi)
 
            % define voxels for ROI
            dum=zeros(stat.dim);
            sub2ind(stat.dim,roi(rcnt).x,roi(rcnt).y,roi(rcnt).z);
            dum(roi(rcnt).x-1:roi(rcnt).x+1,roi(rcnt).y-1:roi(rcnt).y+1,roi(rcnt).z-1:roi(rcnt).z+1)=1;
            sel = find(dum);
            idxROI = find(ismember(sourcemodel.inside,sel));
            
            % select voxels from a voxel * trial matrix (ROI selection on
            % row dimension)  %% FIXME: consolidate with line 247
            currROItrials  = sourcedata.trial{1}(idxROI,:);   % select voxels for each ROI
            currROItrials  = nanmean(currROItrials,1);                  % average across voxels (mean amplitude across voxels, for each trial)
            
            % sort trials, calculate parameters for trial assignment
            [sortedtrial,itrial]  = sort(currROItrials);      % sorted vector of trial power
            mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_oscpowbin_avgregwordord_',roi(rcnt).area,'_sortedtrials_',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'sortedtrial','itrial');
            
            numtrials = numel(sortedtrial);
            numbin  = 20;
            numtrialperbin = floor(numtrials/numbin);
            remainder = rem(numtrials,numbin);
            
            voxM  = zeros(numel(idxROI),numbin);
            vertM = zeros(8196,numbin);
            trialinfoperbin = zeros(numtrialperbin,numbin);
                
            % assign trials, calculate vox*trial and vert*trial matrices
            % Formula below ensures (1) equal numtrials across bins,  (2) equal numbins across subjects
            % to do this remainder/2 trials are removed from each end of sorted power distribution of trials
            for bcnt = 1:numbin  % bcnt = bin counter
                currbintrials = itrial(floor(remainder/2)+(bcnt-1)*numtrialperbin+(1:numtrialperbin));
                
                %%% MNE SOLUTION FOR CURRENT ROI BIN %%%%%%%%%%%%%%%%%%%%%%
                currbindata = ft_selectdata(datin{ccnt},'rpt',currbintrials);
                
                %%% BEAMFORMING SOLUTION FOR CURRENT ROI BIN %%%%%%%%%%%%%%
                currbinbf = sourcedata.trial{1}(idxROI,currbintrials);
                idxNan = find(isnan(currbinbf(1,:))); % remove nans
                if ~isempty(idxNan)
                    currbinbf(:,idxNan) = [];
                    seltrial = setdiff(1:numel(currbintrials),idxNan);
                    currbindata = ft_selectdata(currbindata,'rpt',seltrial);
                end

                % average trial amplitude for currbin (273sensors*31timepoints)
                cfg = [];
               
                tmpdatatlck = ft_timelockanalysis(cfg,currbindata); 
                
                % project to source space (8196 vertices * 31 timepoints)
                currbinmne = abs(mnefilter*tmpdatatlck.avg);  % take absolute value                              
                               
                %%% build voxM and vertM: vox/vert by bin (avg'd trials) %%
                voxM(:,bcnt) = mean(currbinbf,2);  % avg across trials
                vertM(:,bcnt) = mean(currbinmne,2); % avg across time
%                 voxM = mean(currbinbf,2);
%                 vertM = mean(currbinmne,2);

                %%% store trialinfo for mous_corrmnebf_regression 
                tmptrialinfo = trialinfo(currbintrials,5);
                if ~ isempty(idxNan)  %account for trials with NaN
                    tmptrialinfo(idxNan) = NaN;
                end 
                trialinfoperbin(:,bcnt) = tmptrialinfo;%trialinfo(currbintrials,5);
            end
            
            %%% average word order regression
            [voxMr, vertMr] = mous_corrmnebf_regression(voxM, vertM, trialinfoperbin,numbin);  % if 4th argument is given, then regression is done on average word order (not individual standardised word order)

            %%% compute correlation matrix
            [cor] = mous_corrmnebf_computecormat(voxMr, vertMr); % last argument is needed to tell how many trials are contributed from current subject (for fisher z-transform)
            if ccnt == 1
                mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_oscpowbin_avgregwordord_',roi(rcnt).area,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'cor','trialinfoperbin'); 
            elseif ccnt == 2
                mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_oscpowbin_avgregwordord_',roi(rcnt).area,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],'cor','trialinfoperbin'); 
            end  
            
        end %  loop through ROIs
    end % loop through conditions (sent/seq)
end %  dobeam_oscpowbin_mnesingle_reg_cor