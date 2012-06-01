% get the preprocessed data from the database
data = mous_db_getdata(subjectname, 'meg_processed_{raw05-3ds}');

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
cfgf1.output      = 'pow';
cfgf1.channel     = 'MEG';
cfgf1.method      = 'mtmconvol';
cfgf1.taper       = 'hanning';
cfgf1.foi         = 2:2:30;          % analysis 2 to 30 Hz in steps of 2 Hz
cfgf1.t_ftimwin   = ones(1,numel(cfgf1.foi)).*0.5;  % sliding time window;
cfgf1.toi         = -0.25:0.05:2.75;  % Here: -0.25 to 2.75s in steps of 0.05s (50ms)
cfgf1.pad         = 4.0;

%----------------------------------
% for spectral estimation high freq
cfgf2 = [];
cfgf2.output     = 'pow';
cfgf2.channel    = 'MEG';
cfgf2.method     = 'mtmconvol';
cfgf2.foi        = 28:4:100;   % Frequencies of interest: 28 to 100 in steps of 4Hz
cfgf2.t_ftimwin  = ones(1,numel(cfgf2.foi)).*0.25;  
cfgf2.tapsmofrq  = ones(1,numel(cfgf2.foi)).*8;   
cfgf2.toi        = -0.25:0.05:2.75; 
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

mous_db_putdata(subjectname, 'meg_processed_{tfr05-3ds}',    TFRHann_Diff, TFRMult_Diff, TFRHann_SenTar, TFRHann_SeqTar, TFRMult_SenTar, TFRMult_SeqTar);
mous_db_putdata(subjectname, 'meg_processed_{tfr05-3ds-pg}', TFRHann_Diff_PG, TFRMult_Diff_PG, TFRHann_SenTar_PG, TFRHann_SeqTar_PG, TFRMult_SenTar_PG, TFRMult_SeqTar_PG);
