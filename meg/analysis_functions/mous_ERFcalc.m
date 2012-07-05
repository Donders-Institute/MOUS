function [Target_AG, Target_PG]=mous_ERFcalc(subjectname, condition, baseline)

% edited by Nietzsche for trialdef.post 29-5-2012

% Computer start-up for matlab
%addpath /home/common/matlab/fieldtrip
%ft_defaults


filename = mous_db_getfilename(subjectname, 'meg_ds_task'); 


%%%%%% Read in data %%%%%%%%%%%%%%%
%clear all
cfg = [];
cfg.dataset = filename{1};
hdr = ft_read_header(filename{1});

%%%%% Define trial window %%%%%%%%%%


cfg.trialdef.pre    = 0.5;                      % baseline
cfg.trialdef.post   = 3.0-1/hdr.Fs;             % pad
cfg.trialfun = condition; 
[cfg] = ft_definetrial(cfg);
cfg.datatype = 'continuous';
%data_raw = ft_preprocessing(cfg); %FT PREPROCESSING

%%%%%%%%filter%%%%%%%%%%%
%cfg            = [];

cfg.baselinewindow  = [baseline 0];
cfg.lpfilter   = 'yes';   % apply lowpass filter
cfg.lpfreq     = 40;
cfg.demean     = 'yes';
% defined.blc = 'yes'
cfg.continuous='yes';
cfg.hpfilter = 'yes';
cfg.hpfilttype = 'fir';  %not in Tinekes script
cfg.hpfiltord  = 100;   %not in Tinekes script
cfg.hpfreq = 0.5; %wired number  % tineke has 0.5
cfg.padding = 10; %big padding for hp to work 
cfg.channel = {'MEG' 'EEG057' 'EEG058'}; 
data_filtered = ft_preprocessing(cfg);

%trl = cfg.trl(:,:); %put the trial information into memory


%%%%%%%%%%%%%%%%
% read in the predefined artifact trials and reject the, 

arteFile = mous_db_getfilename(subjectname, 'meg_artifactcfg');

load(arteFile{1});

% reassign outputs from above functions
cfg.artfctdef.eog       = cfgeog1.artfctdef.zvalue;  
cfg.artfctdef.eog2      = cfgeog2.artfctdef.zvalue;  
cfg.artfctdef.jump      = cfgjump.artfctdef.zvalue; 
cfg.artfctdef.muscle    = cfgmuscle.artfctdef.zvalue;

cfg.artfctdef.reject = 'partial'; 
data_rejArt = ft_rejectartifact(cfg, data_filtered); 

% downsample the data
cfg                 = [];
cfg.resamplefs      = 300;  % can leave these fields here as so.
cfg.detrend         = 'no';
cfg.demean          = 'yes';
data_DS             = ft_resampledata(cfg, data_rejArt);

% %%% CONVERT TO PLANAR GRADIENT %%%
cfg = [];
cfg.planarmethod    = 'sincos';  
cfg_neighb.method   = 'distance'; 
cfg.neighbours      = ft_prepare_neighbours(cfg_neighb, data_DS); 
data_PG1            = ft_megplanar(cfg,data_DS);

%TIMELOCK

cfg = [];
cfg.vartrllength    = 2; 
timelockedData_AG   = ft_timelockanalysis(cfg, data_DS);  
timelockedData_PG   = ft_timelockanalysis(cfg, data_PG1);

Target_AG           = timelockedData_AG;

% COMBINE PLANAR GRADIENT
Target_PG           = ft_combineplanar(cfg,timelockedData);







