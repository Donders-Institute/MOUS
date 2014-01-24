mous_corrmnebf_pipeline

% calculates correlation matrix between ERFs and TFRs for sentences and
% sequences, independently

% calculate statistics between conditions (sent vs. seq) or one condition
% and dummy condition (all zeros), using monte-carlo permutation statistics

% uses an 8mm sourcemodel

% I can run mous_corrmnebf_corrmat via this script, however, it would be
% quicker and more direct to do so by having the parameters in step2 be
% inarg for mous_execute_pipeline. 
% Furthermore, I can give different frequences/tois as inarg, so that I run
% comparison, each with different parameters, in parallel.

% 23 July 2013. NL


mous_db_makesubjdir(subjectname)
 

%% step 2: 

        cfgmain.foi         = 16;        
        cfgmain.toie        = [0.35 0.45];  % toi for ERFs
        cfgmain.selfq       = [-0.12 -0.08];
        cfgmain.toi         = [];           % toi for TFR % not neded because selfq defines  toi
        cfgmain.cdtn        = 'sen';        % options 'seq','svs_sen','svs_seq'
        if strcmp(cfgmain.cdtn,'sen')
           cfgmain.sencdtn = [1 2 5 6];
        else
           cfgmain.sencdtn = [3 4 7 8];
        end
        cfgmain.suff        = num2str(cfgmain.foi);   
        cfgmain.savebf      = regexprep([num2str(mean(cfgmain.selfq))],'[.]','');
        cfgmain.savemne     = regexprep([num2str(cfgmain.toie(1)) num2str(cfgmain.toie(2))],'[.]',''); 

        mous_corrmnebf_corrmat(subjectname,cfgmain)
        
%% step 3: interpolation and statistics
        
        % group-level statistics are computed once for each comparison
        
        % subjectnames = cell array of all subjects to be used in
        % statistical calculation
        subjectnames = {'V1001' 'V1002' 'V1003' 'V1004' 'V1005' 'V1007' 'V1008' ...
                     'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                     'V1020' 'V1021' 'V1022' 'V1023' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028'...
                     'V1030' 'V1031' 'V1032' 'V1036' 'V1037' ...
                     'V1040' 'V1044' 'V1045' 'V1049'...
                     'V1050' 'V1052' 'V1053' 'V1054' 'V1055' 'V1057' 'V1058' 'V1059'...
                     'V1061' 'V1062' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                     'V1071' 'V1073' 'V1074' 'V1076' 'V1077' 'V1079'...
                     'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1087' 'V1088' 'V1089'...
                     'V1090' 'V1092'  'V1095' 'V1099'...
                     'V1100' 'V1102' 'V1103' 'V1104' 'V1106' 'V1107'};   
        
        mous_corrmnebf_grpstat_roi2whole(subjectnames,param)
        
        % one specific ERF/TFR roi to another TFR/ERF roi.
        % to be implemented (23 July 2013)
        %mous_corrmnebf_grpstat_roi2roi(subjectnames,param)
        
        
%% step 1
% only perform this step when cannot use data from AH (or JM).
        doleadbf    = false;  % leadbf currently taken from JM
        doleadmne   = false;  % leadmne, tlck, mneavg currently taken from AH
        dotlck      = false;
        domneavg    = false;  % calculated to use noise covariance matrix from all data (within one condition)     
                              % do this to avoid biasing MNE estimates
if doleadbf   
    %% leadfields for beamformer (not specific to toi/cdtn of interest)
    % not toi/cdtn specific because the only data required from freq is
    % freq.grad (which is sensor channels)
    % Get  sourcemodel and headmodel
    headmodel = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
    sourcemodel = mous_db_getdata(subjectname, ['meg_anatomy_sourcemodel3D_nonlin','8mm']);

    % forward solution
    suff = '';
    mous_db_getdata(subjectname,['meg_corrmnebf_freq',suff]);
    cfg = [];
    cfg.grid = sourcemodel;
    cfg.vol = headmodel;
    cfg.channel = 'MEG';
    cfg.grad = ft_struct2double(freq.grad);
    cfg.normalize = 'yes';
    sourcemodelbf = ft_prepare_leadfield(cfg);
    mous_db_putdata(subjectname, 'meg_corrmnebf_bfsourcemodel_-02-1s','sourcemodelbf');
end  

if doleadmne
    %% leadfields for MNE (specific to cdtn of interest, because covariance matrix is used, and that is cdtn dependent)
    % Get  sourcemodel and headmodel
    sourcemodel = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  
    if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
        sourcemodel.pos  = sourcemodel.pnt;
        sourcemodel      = rmfield(sourcemodel, 'pnt');
    end
    sourcemodel.inside = 1:8196; % hard code because coreg not perfect so some subj have sources hovering on border
    sourcemodel.outside = [];
    mous_db_getdata(subjectname,  'meg_anatomy_headmodel'); 
    
    cfg             = [];
    cfg.grad        = tlck.grad;  % sensor positions
    cfg.vol         = vol;
    cfg.grid        = sourcemodel;
    cfg.channel     = {'MEG', '-EEG057', '-EEG058'};
    cfg.feedback    = 'textbar';
    sourcemodelmne  = ft_prepare_leadfield(cfg);
    mous_db_putdata(subjectname, 'meg_corrmnebf_mnesourcemodel_sent_-02-1s','sourcemodelmne');
end

if dotlck
    %% Timelock data and calc covariance matrix
    cfg              = [];
    cfg.vartrllength = 2;
    cfg.feedback     = 'textbar';
    cfg.covariance   = 'yes';
    cfg.covariancewindow = [-inf 1]; % calculate the covariance matrix for timepoints before the zero-time point (onset of word) 
    cfg.preproc.demean = 'yes';
    cfg.channel        = {'MEG', '-EEG057', '-EEG058'};
    cfg.preproc.baselinewindow = [-inf 0];
    tlck = ft_timelockanalysis(cfg, data);  
    % save full seconds data for covariance matrix (and incase need to reproduce tlck)
    if toie(2) == 1 
        mous_db_putdata(subjectname,'meg_corrmnebf_tlck_-02-1s','tlck');
    end 
    
end

if domneavg  
    %% calculate sources for averaged data
    cfg                     = [];
    cfg.channel             = {'MEG', '-EEG057', '-EEG058'};
    cfg.method              = 'mne';
    cfg.vol                 = vol;             % vol and grid from "doleadmne"
    cfg.grid                = sourcemodelmne;
    cfg.mne.prewhiten       = 'yes';
    cfg.mne.lambda          = 3; % used to be 2
    cfg.mne.scalesourcecov  = 'yes';
    cfg.mne.keepfilter      = 'yes';
    source                  = ft_sourceanalysis(cfg, tlck);  % noise covariance matrix used here
    % need to save this data for it to be used by corrmnebf_interpolate

    cfg            = [];
    cfg.demean     = 'yes';
    cfg.projectmom = 'yes';
    cfg.zscore     = 'no';
    sd             = ft_sourcedescriptives(cfg, source);
end 
        