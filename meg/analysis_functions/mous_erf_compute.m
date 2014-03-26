function [senWord_AG, seqWord_AG, senWord_PG, seqWord_PG, senWord_CPG, seqWord_CPG, stdev] = mous_erf_compute(subjectname, data)

% This function performs ERF analyses on preprocessed data for one subject
% To run across subjects use qsub

% NL, AH 1-6-2012. Mod: 9-17-2012 (NL)

%% Parameters
% Window length: long/
% wordType = target/ all/firstWord
% trialfun = auditory_word /visual_word
% The trial fun is only used to generate the correct input file 

% deal with the data loading outside the function
baseln = -0.2;

% identify the trials for the conditions (ref: trialfun in mous_preprocessing pipeline)
% implement later in this script (or in a script at an earlier/latter stage
% to identify specific words e.g., noun only, target + 1)

wordType = '';

% bypass the following, because the variable wordType is not known to this
% function
if strcmp(wordType, 'target') %&& strcmp(trialfun, 'visual_word')
  sel1 = find(data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6);   % sentences target word
  sel2 = find(data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);   % sequences target word
elseif strcmp(wordType,'all')  % all words in the sentence
  sel1 = find(data.trialinfo(:,2)==1 | data.trialinfo(:,2)==5 | data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 );  % sentences
  sel2 = find(data.trialinfo(:,2)==3 | data.trialinfo(:,2)==7 | data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);  % sequences
elseif strcmp(wordType,'sentence')
  for k = 1:length(data.trialinfo)
    if data.trialinfo(k,2) == 20 && (data.trialinfo(k+1,2) == 1 || data.trialinfo(k+1,2)==5)
      sel1(k)= data.trialinfo(k+1,2);
    elseif data.trialinfo(k,2) == 20 && (data.trialinfo(k+1,2) == 3 || data.trialinfo(k+1,2)==7)
      sel2(k)= data.trialinfo(k+1,2);
    end
  end
end

sel1 = find(data.trialinfo(:,2)==1 | data.trialinfo(:,2)==5 | data.trialinfo(:,2)==2 | data.trialinfo(:,2)==6 );  % sentences
sel2 = find(data.trialinfo(:,2)==3 | data.trialinfo(:,2)==7 | data.trialinfo(:,2)==4 | data.trialinfo(:,2)==8);  % sequences

n    = min(numel(sel1),numel(sel2));
tmp  = randperm(numel(sel1)); sel1 = sort(sel1(tmp(1:n)));
tmp  = randperm(numel(sel2)); sel2 = sort(sel2(tmp(1:n)));

% Calculate the ERF
fprintf('Calculating ERF for subject %s for conditions SenTar and SeqTar\n', subjectname);

% Create configurations for steps in analysis -----------------------------

% for planar gradient computation
cfgplanar              = [];
cfgplanar.planarmethod = 'sincos';  
cfg_neighb.method      = 'distance';
cfg_neighb.neighbourdist = 3;
cfgplanar.neighbours   = ft_prepare_neighbours(cfg_neighb, data); 

% cfg for condition specific analyses
cfg1                = [];       %  1 = sentences
cfg1.trials         = sel1;  
cfg1.channel        = 'MEG';
cfg1.vartrllength   = 2;

cfg2                = [];       %  2 = sequences
cfg2.trials         = sel2; 
cfg2.channel        = 'MEG';
cfg2.vartrllength   = 2;

cfgbaseline          = [];
cfgbaseline.baseline = [baseln 0];
cfgbaseline.channel  = 'MEG';

% AG calculations  --------------------------------------------------
% timelock analysis for axial gradient data
senWord_AG = ft_timelockanalysis(cfg1, data);
senWord_AG = ft_timelockbaseline(cfgbaseline, senWord_AG);
seqWord_AG = ft_timelockanalysis(cfg2, data);
seqWord_AG = ft_timelockbaseline(cfgbaseline, seqWord_AG);

% compute the std in the basline (Axial data) for visualization purpose
label = ft_channelselection('MEG', data.label);
data = ft_selectdata(data, 'toilim', [-inf 0-1/300], 'rpt', [sel1(:);sel2(:)], 'channel', label);
data = ft_megplanar(cfgplanar, data);
data = ft_combineplanar([], data);
tmp  = cat(2, data.trial{:});
stdev = std(tmp, [], 2);
clear data tmp;

% PG calculations -----------------------------------------------------
% convert data to planar gradient: this is most efficiently done on the
% timelocked AG-data, rather than on all trials separately. Since it's a
% linear step, the result should be the same (added JMS: 27/08/13)

% data                = ft_megplanar(cfgplanar,data);
% cfg1.trackcallinfo = 'no'; 
% cfg2.trackcallinfo = 'no';

% timelock analysis for planar gradient data
% senWord_PG = ft_timelockanalysis(cfg1, data);
% seqWord_PG = ft_timelockanalysis(cfg2, data);

% cfg          = [];  
% cfg.baseline = [baseln 0];
% cfg.channel  = 'MEG';
% senWord_PG   = ft_timelockbaseline(cfg, senWord_PG);
% seqWord_PG   = ft_timelockbaseline(cfg, seqWord_PG);

senWord_PG = ft_megplanar(cfgplanar, senWord_AG);
senWord_PG = ft_timelockbaseline(cfgbaseline, senWord_PG);
seqWord_PG = ft_megplanar(cfgplanar, seqWord_AG);
seqWord_PG = ft_timelockbaseline(cfgbaseline, seqWord_PG);

% combine planar gradient (CPG)
senWord_CPG = ft_combineplanar([], senWord_PG);
seqWord_CPG = ft_combineplanar([], seqWord_PG);

