% function mous_corrbfbf_cormat(subjectname,param)
% This function correlates all beamforming estimates at each voxel with
% each other for a specified frequency(ies) of interest

% select frequency(ies) and time window of interest
% create correlation matrix
% regress out word order
% do a fisher transform
% statistics:  see mous_corrbfbf_grpstat

param.range       = 'medium';
param.foi1        = 5;        
param.foi2        = 16;
%param.selfq       = [-0.12 -0.08];
param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
param.suff        = num2str(param.foi);   
param.savebf      = regexprep([num2str(mean(param.selfq))],'[.]','');
param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 

doselfreq                   = true;
domnesingle_beam_reg_cor    = true;  % calculate beamforming solution, regress word order and then calc correlation matrix

if doselfreq
    %% OSCILLATIONS select frequency 

    % bfica tapsmofrq = 8 = 8Hz smoothing
    rootdir = '/home/language/jansch/public/mous/';      % all the low frequencies, where freq.freq = [2.5 5 7.5 10 12]
    mous_db_getdata(subjectname,['meg_bfica_freq_',param.range],'/project/3011020.09/jansch/');
    freq1 = ft_selectdata(freq,'foilim',param.foi1*[1 1]);
    freq2 = ft_selectdata(freq,'foilim',param.foi2*[1 1]);

    warning off;
    freq   = ft_struct2double(freq);
    warning on;

    if isfield(param,'selfq')
        cfg = [];
        cfg.latency = [param.selfq(1) param.selfq(2)];  
        freq1        = ft_selectdata(cfg,freq1); 
        idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
        freq1        = ft_selectdata(freq1,'rpt',idxful);  
        
        freq2        = ft_selectdata(cfg,freq2); 
        idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
        freq2        = ft_selectdata(freq2,'rpt',idxful);  
    end
end 

if dobeam_reg_cor
    %%  Beamformer, regress word order and calculate correlation matrix
            
    %%%%%%%%%%%%%%% BEAMFORMING SOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%
    % freqin{mm}.calc = 1;  % without freqin.calc then the number of trials are balance between sentences and sequences
    freqin{mm} = rmfield(freqin{mm},'time');
    freqin{mm}.dimord = 'rpttap_chan_freq'; 
    [source, trialinfo] = mous_bfica_source(subjectname, freqin{mm}, param.toi, 8);  
    
    freqin{mm}.cumtapcnt = ones(size(freqin{mm}.fourierspctrm,1),1);
    sourcedata = mous_bfica_sourcedata(source, freqin{mm});                          
    
    %mous_db_putdata(subjectname, ['meg_corrbfbf_bfsourcesingletrial8mm_bf',param.savebf,'_',param.suff,'Hz_senandseq'],'source','trialinfo');
    %clear source

    %%%%%%%%%%%%%%% REGRESS WORD ORDER ; CORRELATION MATRIX %%%%%%% 
    % remove trials with NaNs
    voxM  = sourcedata.trial{1};     
    idxNan = find(isnan(voxM(1,:))); % which column (trial) has NaN
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
    end
        
        
    for mm = 1:2  % first loop = sentences; second loop = sequences

        % compute leave-one-out etimates for the oscillations (leave-one-out estimates for mne are done within do mnesingle)
        voxMsum = sum(voxM,2);
        voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);
 
        %[voxM, vertM] = mous_corrmnebf_regression(voxM, vertM)
        %% FIX ME, fix function to work with voxM & trialinfo; i.e. read vertM as a option inarg
        [voxM] = mous_corrmnebf_regression(voxM,trialinfo); 
        
        %% CHECK ME: does function work properly when 1st and 2nd inarg are the same?
        [cor] = mous_corrmnebf_computecormat(voxM, voxM, trialinfo); % check correct trialinfo is given

        if mm == 1
            mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],'cor'); 
        elseif mm == 2
            mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],'cor'); 
        end 
    end 
end
