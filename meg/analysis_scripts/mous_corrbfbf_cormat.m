% function mous_corrbfbf_cormat(subjectname,param)
% This function correlates power estimates at each voxel of one frequency
% with that of another frequency.
% Currently (30.12.2013) the idea is to 


% select frequency(ies) and time window of interest
% create correlation matrix
% regress out word order
% do a fisher transform
% statistics:  see mous_corrbfbf_grpstat

param.suff1      = '_low';  % which file
param.suff2      = '_medium';
param.foi1       = 5;      % which freq within file
param.foi2       = 16;
param.savesuff   = '-01505';  
param.toi        = -0.15:0.05:0.5;
param.rootdir    = '/project/3011020.09/nielam/';

doselfreq                   = true;
domnesingle_beam_reg_cor    = true;  % calculate beamforming solution, regress word order and then calc correlation matrix

if doselfreq
    %% OSCILLATIONS select frequency 

    % vis low/med freq = JM rdir;  
    % vis high & all aud = NL rdir 
    mous_db_getdata(subjectname,['meg_bfica_freq',param.suff1],'/project/3011020.09/jansch/');
    warning off;
    freq   = ft_struct2double(freq);
    warning on;
% FIXME: ft_selectdata_new doesn't work
% FIXME: ft_selectdata_old works but doesn't change dimord
%     cfg = [];
%     cfg.foilim = param.foi1*[1 1];
%     freq1 = ft_selectdata(cfg,freq);
    freq1 = ft_selectdata(freq,'foilim',param.foi1*[1 1]);
    
    if ~strcmp(param.suff1,param.suff2)
        mous_db_getdata(subjectname,['meg_bfica_freq',param.suff2],'/project/3011020.09/jansch/');
        warning off;
        freq   = ft_struct2double(freq);
        warning on;
    end 
%     cfg = [];
%     cfg.foilim = param.foi2*[1 1];
%     freq2 = ft_selectdata(cfg,freq);
    freq2 = ft_selectdata(freq,'foilim',param.foi2*[1 1]);

    
    % FIXME: is it necessary to do it here since this seems to be taken cared of in
    % the initial section of code in  mous_bfica_source
    % FIXME: the first time point of fourierspctrm is *all NaNs* - I also
    % noticed this for the auditory subjects such that mous_bfica_source
    % didn't work. (30.12.2013)
    
    % select time points and remove trials with missing data (NaN) due to artifact rejection
%     if isfield(param,'selfq')
%         cfg = [];
%         cfg.latency  = [param.selfq(1) param.selfq(2)];  
%         freq1        = ft_selectdata(cfg,freq1); 
%         idxful       = find(~isnan(freq1.fourierspctrm(:,1,1,1)));  % first trial time point is all NaNs, need (:,1,1,2)
%         freq1        = ft_selectdata(freq1,'rpt',idxful);  
%         
%         freq2        = ft_selectdata(cfg,freq2); 
%         idxful       = find(~isnan(freq2.fourierspctrm(:,1,1,1)));  % first trial time point is all NaNs, need (:,1,1,2)
%         freq2        = ft_selectdata(freq2,'rpt',idxful);  
%     end
end 

if dobeam_reg
    %%  Beamformer, regress word order and calculate correlation matrix
    freqin{1} = freq1; freqin{2} = freq2;    
%     VoxM1 = zeros(5782,size(freq1.trialinfo,1),numel(freq1.time)); % vox,trial,time
%     VoxM2 = zeros(5782,size(freq2.trialinfo,1),numel(freq2.time)); % vox,trial,time
    voxM1 = cell(1,numel(param.toi));
    voxM2 = cell(1,numel(param.toi));
    for mm = 1:2
        
        for toilop = 1:numel(param.toi)      % -0.15 to 0.5 (9 tois)

            %%% BEAMFORM %%%
            freqin{mm}.calc = 1;  % use freqin.calc to skip the balancing of numtrials btw sent and seq
%             freqin{mm} = rmfield(freqin{mm},'time');
%             freqin{mm}.dimord = 'rpttap_chan_freq'; 
            [source, trialinfo] = mous_bfica_source(subjectname, freqin{mm}, param.toi(toilop), 8);  

            freqin{mm}.cumtapcnt = ones(size(freqin{mm}.fourierspctrm,1),1);
            sourcedata = mous_bfica_sourcedata(source, freqin{mm},param.toi(toilop));                          

            %%% REMOVE NaN %%% from trials in the'freq' variable, not 'source' variable
            % so that the same numtrial in 'source' and 'freq', allow correct filters applied to freq data
            tmpM  = sourcedata.trial{1};     % create new variable, cuz sourcedata contains other unnecessary fields
           
            % THINK: if i decide to balance numtrials btw Sent and Seq, then I should compare that trialinfo 
            % to remove the same numtrials below here:
            idxNan = find(isnan(tmpM(1,:))); % which column (trial) has NaN
            if ~isempty(idxNan)
                tmpM(:,idxNan) = []; 
            end

            %%% COMPUTE LEAVE-ONE-OUT ESTIMATES %%% 
            % tmpM = vox*trials;  Msum = total for each row (across cols)
            Msum = sum(tmpM,2);
            % subtract each element from it's row total and divide by n-1 numtrials. 
            tmpM = (Msum*ones(1,size(tmpM,2)) - tmpM)./(size(tmpM,2)-1);

            %%% regress out standardized word order %%%
            [tmpM] = mous_corrmnebf_regression(trialinfo,tmpM); 
            
            %%% save vox.trial matrix (of specific toi) into cell array
            if mm == 1
                voxM1(toilop) = tmpM;
            elseif mm == 2
                voxM2(toilop) = tmpM;
            end
        end 
    end
    mous_db_putdata(subjectname,['meg_corrbfbf_mat',num2str(param.foi1),'Hz',num2str(param.foi2),'Hz_toi',param.savesuff],param.rootdir);
end

if docor
    %%% FIXME:       
        % Build a checker for numtrial in each matrix.
        % equalise numtrials btw matrices if necessary (should I put this
        % into mous_corrmnebf_computecormat ?  I might forget it's there
        % and this would be problematic if my matrix is trial*vox, instead
        % of vox*trial
            
        [cor] = mous_corrmnebf_computecormat(trialinfo, tmpM); % check correct trialinfo is given
        
        % FIXME:  the toi should change from the above mous_db_putdata
        % because it should be for only 1 toi or averaged across multiple tois
        param.savetoisuff

        if mm == 1
            mous_db_putdata(subjectname,['meg_corrbfbf_cormat',num2str(param.foi1),'Hz',num2str(param.foi2),'Hz_toi',param.savetoisuff],'cor',param.rootdir); 
        elseif mm == 2
            mous_db_putdata(subjectname,['meg_corrbfbf_cormat',num2str(param.foi1),'Hz',num2str(param.foi2),'Hz_toi',param.savetoisuff],'cor',param.rootdir); 
        end
    
end 
