function mous_tfr_pipeline(subjectname)
%% change name of input and output file accordingly!

% get the preprocessed data from the database
data = mous_db_getdata(subjectname, 'meg_processed_{rawTFR_targetword_05-3ds}');

% set up the configurations for the different analysis steps

%-------------------------------
% for planar gradient computation
cfgplanar              = [];
cfgplanar.planarmethod = 'sincos';  
cfg_neighb.method      = 'distance'; 
cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data); 

%---------------------------------
% for spectral estimation low freq   
cfgf1             = [];
cfgf1.calcdof     = 'yes';
cfgf1.output      = 'pow';
cfgf1.channel     = 'MEG';
cfgf1.method      = 'mtmconvol';
cfgf1.taper       = 'hanning';                       % If this is commented out. The default analysis is 'dpss' which is multitapering;
cfgf1.foi         = 2.5:2.5:30;                      % sliding freq window: steps of 2.5 Hz (match t_ftimwin)
cfgf1.t_ftimwin   = ones(1,numel(cfgf1.foi)).*0.4;   % length of time window for smoothing: 1/0.4 = 2.5cycles per second
cfgf1.tapsmofrq   = ones(1,numel(cfgf1.foi)).*5;     % width of freq window for smoothing: an integer multiple of number of cycles in 1sec
cfgf1.toi         = -0.25:0.05:2.75;                 % sliding time window: in steps of 50ms
cfgf1.pad         = 4.0;

%----------------------------------
% for spectral estimation high freq
cfgf2            = [];
cfgf2.calcdof    = 'yes';
cfgf2.output     = 'pow';
cfgf2.channel    = 'MEG';
cfgf2.method     = 'mtmconvol';
cfgf2.foi        = 28:4:100;                        % sliding freq window:  4Hz
cfgf2.t_ftimwin  = ones(1,numel(cfgf2.foi)).*0.25;  % length of time window 1/0.25 = 4Hz  foi x 0.25 
cfgf2.tapsmofrq  = ones(1,numel(cfgf2.foi)).*8;     % width of freq window for smoothing: foi x 8
cfgf2.toi        = -0.25:0.05:2.75;                 % sliding time window: in steps of 50ms
cfgf2.pad        = 4.0;   

% identify the trials for the two conditions
sel1 = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6);
sel2 = find(data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);

% do the spectral analysis on the axial gradient data
    cfgf1.trials   = sel1;
    cfgf2.trials   = sel1;
    TFRHann_SenTar = ft_freqanalysis(cfgf1, data);
    TFRMult_SenTar = ft_freqanalysis(cfgf2, data);

    cfgf1.trials   = sel2;
    cfgf2.trials   = sel2;
    TFRHann_SeqTar = ft_freqanalysis(cfgf1, data);    
    TFRMult_SeqTar = ft_freqanalysis(cfgf2, data); 

    % convert to planar gradient
    data = ft_megplanar(cfgplanar, data);

    % do the spectral analysis on the planar gradient data
    cfgf1.trials   = sel1;
    cfgf2.trials   = sel1;
    TFRHann_SenTar_PG = ft_freqanalysis(cfgf1, data);
    TFRMult_SenTar_PG = ft_freqanalysis(cfgf2, data);

    cfgf1.trials   = sel2;
    cfgf2.trials   = sel2;
    TFRHann_SeqTar_PG = ft_freqanalysis(cfgf1, data);    
    TFRMult_SeqTar_PG = ft_freqanalysis(cfgf2, data); 


%%%  COMBINE PLANAR %%%

% computer planar gradient magnitude over both directions to give a positive-valued number
TFRHann_SenTar_PG = ft_combineplanar([], TFRHann_SenTar_PG);
TFRHann_SeqTar_PG = ft_combineplanar([], TFRHann_SeqTar_PG);

TFRMult_SenTar_PG = ft_combineplanar([], TFRMult_SenTar_PG);
TFRMult_SeqTar_PG = ft_combineplanar([], TFRMult_SeqTar_PG);

    
%%% DIFFERENCE TFRs %%%
% (1) Create a struct to have all necessary fields (label, dimord, freq...etc) 
TFRHann_Diff    = TFRHann_SenTar;
TFRHann_Diff_PG = TFRHann_SenTar;

TFRMult_Diff    = TFRMult_SenTar;
TFRMult_Diff_PG = TFRMult_SenTar;

% (2) calculate the difference powerspectra
TFRHann_Diff.powspctrm    = (TFRHann_SenTar.powspctrm./TFRHann_SeqTar.powspctrm)-1;
TFRHann_Diff_PG.powspctrm = (TFRHann_SenTar_PG.powspctrm./TFRHann_SeqTar_PG.powspctrm)-1;

TFRMult_Diff.powspctrm    = (TFRMult_SenTar.powspctrm./TFRMult_SeqTar.powspctrm)-1;
TFRMult_Diff_PG.powspctrm = (TFRMult_SenTar_PG.powspctrm./TFRMult_SeqTar_PG.powspctrm)-1;

%% change name of file depending on word being analysed!
mous_db_putdata(subjectname, 'meg_processed_{tfr_targetword_Hann4under30_05-3ds}',    TFRHann_Diff, TFRMult_Diff, TFRHann_SenTar, TFRHann_SeqTar, TFRMult_SenTar, TFRMult_SeqTar);
mous_db_putdata(subjectname, 'meg_processed_{tfr_targetword_Hann4under30_05-3ds-pg}', TFRHann_Diff_PG, TFRMult_Diff_PG, TFRHann_SenTar_PG, TFRHann_SeqTar_PG, TFRMult_SenTar_PG, TFRMult_SeqTar_PG);

clear all;