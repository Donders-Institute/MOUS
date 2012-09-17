% % This function combines sentences and sequences together and produces
% descriptive plots of where prominent activity is found across both
% conditions
% NL 13.6.2012

% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1029' 'V1031'...
            'V1033' 'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};
 

%% (A) get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);

for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/TFR/' subjlist{k} 'tfr_targetword_05-3ds-pg']);

  freq1{k} = TFRHann_SenTar_PG;  % load sentences and sequences into 2 columns:      SenTar         SeqTar              % permuting between these 2 conditions
  freq2{k} = TFRMult_SenTar_PG;                                 %                 1 1 1 1 1 1       2 2 2 2 2 2         % cfg.ivar (independent variables)
  freq1{k+nsubj} = TFRHann_SeqTar_PG;                           %                 1 2 3 4 5 6       1 2 3 4 5 6         % cfg.uvar (units of observ.)
  freq2{k+nsubj} = TFRMult_SeqTar_PG;
end

%% (C) Plot the data for both conditions without statistics  %note: run part (A) first

% different plots for low and high frequencies 
% average across sentences and sequences
freqAll_Low     = ft_selectdata(freq1{:},'param','powspctrm','avgoverrpt','yes');  % Below 30Hz  
freqAll_High    = ft_selectdata(freq2{:},'param','powspctrm','avgoverrpt','yes');  % Above 30Hz

% perform baseline correction 
cfgb                = [];
cfgb.baseline       = [-0.25 -0.15];  % don't read until zero because at zero time point is start of stimulus, and baseline will thus have have leakage from brain activity where stimulus is present
cfgb.baselinetype   = 'relchange';
freqAll_Low_b     = ft_freqbaseline(cfgb, freqAll_Low);
freqAll_High_b    = ft_freqbaseline(cfgb, freqAll_High);

% plot
cfgp                = [];
cfgp.layout         = 'CTF275.lay';
cfgp.interactive    = 'yes';
cfgp.zlim           = 'maxabs';
figure; ft_multiplotTFR(cfgp,freqAll_Low_b);
figure; ft_multiplotTFR(cfgp,freqAll_High_b);


%% (D) plot data for one condition without statistics

% for ivar: the first 17 cells are one condition (sent), and the next 17 cells are the other condition (seq)

selPtp = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17];  % select participants % used to select data of participants from one condition

% select data
    % sentences only
    freqSen_Low     = ft_selectdata(freq1{:},'param','powspctrm');                      % <30Hz
    freqSen_Low     = ft_selectdata(freqSen_Low,'avgoverrpt','yes','rpt',selPtp);  
    freqSen_High    = ft_selectdata(freq2{:},'param','powspctrm');                      % >30Hz
    freqSen_High    = ft_selectdata(freqSen_High,'avgoverrpt','yes','rpt',selPtp); 

    % sequences only
    freqSeq_Low     = ft_selectdata(freq1{:},'param','powspctrm','avgoverrpt','yes');
    freqSen_Low     = ft_selectdata(freqSeq_Low,'avgoverrpt','yes','rpt',selPtp+17);
    freqSeq_High    = ft_selectdata(freq2{:},'param','powspctrm','avgoverrpt','yes');
    freqSen_High    = ft_selectdata(freqSeq_High,'avgoverrpt','yes','rpt',selPtp+17);

% perform baseline correction
cfgb                = [];
cfgb.baseline       = [-0.25 -0.15];
freqSen_Low_b = ft_freqbaseline(cfgb, freqSen_Low); % default = absolute baseline normalization of data
freqSen_High_b = ft_freqbaseline(cfgb, freqSen_High);
freqSeq_Low_b = ft_freqbaseline(cfgb, freqSeq_Low); % default = absolute baseline normalization of data
freqSeq_High_b = ft_freqbaseline(cfgb, freqSeq_High);

% plot (p) dimord: chan_freq_time
cfgp.layout = 'CTF275.lay';
cfgp.interactive = 'yes';
cfgp.zlim = 'maxabs';
figure; ft_multiplotTFR(cfgp,freqSen_Low_b) 
figure; ft_multiplotTFR(cfgp,freqSen_High_b) 
figure; ft_multiplotTFR(cfgp,freqSeq_Low_b) 
figure; ft_multiplotTFR(cfgp,freqSeq_High_b) 


%% (E) choose subset of the participants if necessary. Ideally choose the appropriate subjlist so thatthis part does not need to be implemented
% this code can be used whether plotting for one or more conditions.
% Implemented after the first ft_selectdata is called e.g., ft_selectdata(freq1{:},'param','powspctrm');
    % search for matching strings in 2 lists
    % returns indices of matches present in each list
    [a,b] = match_str(subjlist(:),{'V1013' 'V1024' 'V1028' 'V1029' 'V1030' 'V1031' 'V1033' 'V1034' 'V1044'});
    % redefine freqDesc
    freqDesc=ft_selectdata(freq1{:},'param','powspctrm');
    % rpt = indices of replicates (subjects) to be retained for subsequent analysis
    freqDesc=ft_selectdata(freqDesc,'avgoverrpt','yes','rpt',a); %define over which rpt to average, here it is 9 of the 17

% combining baselined data from both conditions if necessary 
    freqb_allcdtn = freqb_Sen;
    freqb_allCdtn.powspctrm = freqb_Sen.powpsctrm+freqb_Seq.powspctrm; % this is the quick and dirty way
    freqb_allCdtn.powspctrm = mean([freqDescSen.powspctrm freqDescSeq.powspctrm]); % this is not it
    freqb_allCdtn.powspctrm = ft_selectdata();     % what about using ft_selectdata with 'avgoverrpt' 'avgoverfreq' 'avgovertime' all set to 'yes' ?
