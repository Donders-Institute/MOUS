function [TFRHann_Diff,TFRHann_Diff_PG,TFRMult_Diff,TFRMult_Diff_PG] = mous_tfrtargetword_pipeline(subjectname)

% Computer start-up for matlab
addpath /home/common/matlab/fieldtrip
ft_defaults


%%% READ IN HEADER DATA %%%
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');
cfg         = [];
cfg.dataset = filename{1};
hdr         = ft_read_header(filename{1});  


%%% DEFINE TRIALS - padded trials %%%
cfg.trialdef.pre    = 0.5;                      % baseline
cfg.trialdef.post   = 3.0-1/hdr.Fs;             % pad
cfg.trialfun        = 'trialfun_AllTargets';    % 1s duration from onset of target word
[cfg]               = ft_definetrial(cfg);      % ft_definetrial defines trials which are created in cfg.trl which is a parameter for ft_preprocessing

%%% PRE-PROCESSING %%%
cfg.continuous = 'yes';
cfg.padding = 12;        %pad trials with a bit more data than required to remove effects filter's tails 
cfg.dftfilter = 'yes';   %remove 50Hz
cfg.channel = {'MEG' 'EEG057' 'EEG058'}; 
data = ft_preprocessing(cfg); %FT PREPROCESSING

%%% ARTIFACT REJECTION %%%

% load location of artifacts 
cfg = [];
cfg = strcat(subjectname,'artifactcfg');
load(cfg);
% mous_db_getdata(subjectname, 'meg_artifactcfg');   % eventually can use this function to load the file with location of artefacts

% reassign outputs from above functions
cfg.artfctdef.eog       = cfgeog1.artfctdef.zvalue;  
cfg.artfctdef.eog2      = cfgeog2.artfctdef.zvalue;  
cfg.artfctdef.jump      = cfgjump.artfctdef.zvalue; 
cfg.artfctdef.muscle    = cfgmuscle.artfctdef.zvalue;

% delete artifacts
cfg.artfctdef.reject       = 'partial';              % needs to be reinstated here, even though it is also in mous_artifact_pipeline                                                    
data_rejArt = ft_rejectartifact(cfg, data);

% trials / channels                                                  
% cfg          = [];
% cfg.method   = 'summary';
% cfg.channel  = 'MEG';
% data_rejVis  = ft_rejectvisual(cfg,data_DS); 

% downsample the data
cfg                 = [];
cfg.resamplefs      = 300;  % can leave these fields here as so.
cfg.detrend         = 'yes';
data_DS             = ft_resampledata(cfg, data_rejArt);

%%% CONVERT TO PLANAR GRADIENT %%%
cfg = [];
cfg.planarmethod    = 'sincos';  
cfg_neighb.method   = 'distance'; 
cfg.neighbours      = ft_prepare_neighbours(cfg_neighb, data_DS); 
data_PG1            = ft_megplanar(cfg,data_DS);

%%% TFR analyses %%%  Window lengths are frequency dependent
% hanning taper
    cfg             = [];
    cfg.output      = 'pow';
    cfg.channel     = 'MEG';
    cfg.method      = 'mtmconvol';
    cfg.taper       = 'hanning';
    cfg.foi         = 2:2:30;          % analysis 2 to 30 Hz in steps of 2 Hz 
    cfg.t_ftimwin   = ones(1,numel(cfg.foi)).*0.5;  % slidaftering time window;       
                                                     % numel returns number of elements in array
                                                     % If: 7./cfg.foi = 7 cycles per time window
                                                     % Nowafter: 500ms
    cfg.toi         = -0.25:0.05:2.75;  % Here: -2 to 12s in steps of 0.05s (500ms)
    cfg.pad         = 4.0;

    % Analyze according to condition which is specified in the first column of trialinfo (which begins on 4th column of trl)
    % ft_freqanalysis takes the entire dataset and analyzes bits of data as defined in cfg.
    
    cfg.trials         = find(data_PG1.trialinfo(:,1) == 2 | data_PG1.trialinfo(:,1) == 6);  % sentence Targets
    TFRHann_SenTar     = ft_freqanalysis(cfg, data_DS);
    TFRHann_SenTar_PG  = ft_freqanalysis(cfg, data_PG1); 
    
    cfg.trials         = find(data_PG1.trialinfo(:,1) == 4 | data_PG1.trialinfo(:,1) == 8); % sequence Targets
    TFRHann_SeqTar     = ft_freqanalysis(cfg, data_DS);    
    TFRHann_SeqTar_PG  = ft_freqanalysis(cfg, data_PG1);  
    
% multitaper
    % provides better control over smoothing i.e   . more tapers gives greater smoothing. 
    % Ideal when dealing with a broad band of frequencies, i.e. Gamma 30 - 100Hz
    % A set of tapers for each time window; shorter time window for higher frequencies
    cfg = [];
    cfg.output     = 'pow';
    cfg.channel    = 'MEG';
    cfg.method     = 'mtmconvol';
    cfg.foi        = 28:4:100;   % Frequencies of interest: 30 to 100 in steps of 2Hz  
                                 % smaller step size = smoother due to more redundancy, but doesn't 'give more info' and addes to computation time 
                                 % start at 28, because its a multiple of number of cycles at 1s (steps also changed to accordingly)
                                 
    cfg.t_ftimwin  = ones(1,numel(cfg.foi)).*0.25;  % length of time window (timwin): 250ms means 4 cycle at 1s. 5 cycles per window.  At higher frequencies: the same time period has more cycles fit in, therefore smaller window
     cfg.tapsmofrq  = ones(1,numel(cfg.foi)).*8;     % width of frequency smoothing should be an integer multiple of number of cycles at 1s (here 4)
                                                    % smoothing increases w/ frequency
    cfg.toi        = -0.25:0.05:2.75;  %time interval of interest (50ms window): where power values is calculated; smaller window = smoother
    cfg.pad        = 4.0;    % pad end of trial with filter when specified duration becomes longer than trial itself i.e. at 10s
                             % pad should also be a multiple of number of cycles at 1s (here 4)
  
    cfg.trials         = find(data_PG1.trialinfo(:,1) == 2 | data_PG1.trialinfo(:,1) == 6);  % sentence target
    TFRMult_SenTar     = ft_freqanalysis(cfg, data_DS);  
    TFRMult_SenTar_PG  = ft_freqanalysis(cfg, data_PG1); 
    
    cfg.trials       = find(data_PG1.trialinfo(:,1) == 4 | data_PG1.trialinfo(:,1) == 8);  % sequence target
    TFRMult_SeqTar  = ft_freqanalysis(cfg, data_DS); 
    TFRMult_SeqTar_PG   = ft_freqanalysis(cfg, data_PG1); 
 
%%%  COMBINE PLANAR %%%

% computer planar gradient magnitude over both directions to give a positive-valued number
TFRHann_SenTar_PG2 = ft_combineplanar([], TFRHann_SenTar_PG);
TFRHann_SeqTar_PG2 = ft_combineplanar([], TFRHann_SeqTar_PG);

TFRMult_SenTar_PG2 = ft_combineplanar([], TFRMult_SenTar_PG);
TFRMult_SeqTar_PG2 = ft_combineplanar([], TFRMult_SeqTar_PG);

    
%%% DIFFERENCE TFRs %%%
% (1) Create a struct to have all necessary fields (label, dimord, freq...etc) 
TFRHann_Diff    = TFRHann_SenTar;   % doesn't matter which condition is used for creation because they are the same across conditions
TFRHann_Diff_PG = TFRHann_SenTar;

TFRMult_Diff    = TFRMult_SenTar;
TFRMult_Diff_PG = TFRMult_SenTar;

% (2) calculate the difference powerspectra
TFRHann_Diff.powspctrm = (TFRHann_SenTar.powspctrm./TFRHann_SeqTar.powspctrm)-1;
TFRHann_Diff_PG.powspctrm = (TFRHann_SenTar_PG2.powspctrm./TFRHann_SeqTar_PG2.powspctrm)-1;

TFRMult_Diff.powspctrm = (TFRMult_SenTar.powspctrm./TFRMult_SeqTar.powspctrm)-1;
TFRMult_Diff_PG.powspctrm = (TFRMult_SenTar_PG2.powspctrm./TFRMult_SeqTar_PG2.powspctrm)-1;


    
% %%% PLOT %%% 
% % axes: ylim = frequencies of interest;  xlim = time period of interest;  zlim = power
% 
% % multiplot
% cfg = [];
% cfg.interactive  = 'yes';
% cfg.channel      = 'all';   % 'all' is the default.
% cfg.showlabels   = 'yes';	
% cfg.layout       = 'CTF275.lay';
% cfg.zlim = 'maxabs';
% %cfg.zlim         = [-0.61 0.48];
% 
% 
% % LESS 30Hz 
% figure; ft_multiplotTFR(cfg, TFRHann_Diff);     
% title('<30 TFRHann_Diff');
% 
% figure; ft_multiplotTFR(cfg, TFRHann_Diff_PG);     
% title('<30 TFRHann_Diff_PG');
% 
% %  MORE 30Hz
% figure; ft_multiplotTFR(cfg, TFRMult_Diff);     
% title('>30 TFRMult_Diff');
% 
% figure; ft_multiplotTFR(cfg, TFRMult_Diff_PG);   
% title('>30 TFRMult_Diff_PG');
% 
% % single plot
% % cfg = [];
% % cfg.baseline     = [-1.0 0.0];
% % cfg.baselinetype = 'absolute';  	
% % cfg.zlim         = [-3e-27 3e-27];	
% % %cfg.xlim         = [2 12];
% % %cfg.ylim         = [4 12];
% % cfg.channel      = 'MLO31';  % The 'O' is a letter, not the number zero
% 
% % figure; ft_multiplotTFR(cfg, dataset);   
% 
% 
% % topoplot
% % cfg = [];
% % cfg.baseline     = [-1.0 0.0];	
% % cfg.baselinetype = 'absolute';
% % cfg.xlim         = [0.9 1.3];   
% % cfg.zlim         = [-1.5e-27 1.5e-27];
% % cfg.ylim         = [15 20];
% % cfg.showlabels   = 'markers';
% % figure 
% % ft_multiplotTFR(cfg, dataset);   