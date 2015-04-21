function varargout = mous_wrdpstn_earlyvslate_strat(data,rseedinput)
% don't need to specify 'toilop' because will use randomseed when calling qsub
% [senearly, senlate, wlearly, wllate] = mous_wrdpstn_earlyvslate

% this function selects
% 1: 2nd,3rd,4th word in sentence, and in word list
% 2: n-1,n-2,n-3 word in sentence, and in word list
% lexical frequency AND number of trials for the four conditions (argout) are balanced
% averaging across words in #1 forms the senearly condition
% averaging across words in #2 forms the senlate conditions

% randseed not implemented i.e. each timepoint has diff trials removed

% add unique ID column
% 1          2            3              4                           5                                % 6           7.
% sentcount  ordinalpstn  word trigger   #smp. relative to 1st word  #smps btw word onset and offset  .wavfile    uniqueID
data.trialinfo(:,7) = (data.trialinfo(:,1)*100)+data.trialinfo(:,2); % uniqueID for each word

% get lexical frequency for each word (trial)
% extract_lexfreq assumes trialinfo to have the following order of elements
% column 5. word position in sentence/wl
% column 6. sentence ID (stimulus wav file ID)

data.trialinfo = data.trialinfo(:,[1 3 4 5 2 6 7]);
L = log10(extract_lexfreq(data.trialinfo));

% divide data into earlywords and latewords
[indx_early, indx_late] = extract_earlylate(data.trialinfo);
T = data.trialinfo(:,2);

% divide into early and late for Sentences and Word list 
cfg = [];
indx1 = intersect(find(ismember(T,[1 2 5 6])), indx_early);
cfg.trials = indx1;
sentearly = ft_selectdata(cfg, data);

indx2 = intersect(find(ismember(T,[1 2 5 6])), indx_late);
cfg.trials = indx2;
sentlate = ft_selectdata(cfg, data);

indx3 = intersect(find(ismember(T,[3 4 7 8])), indx_early);
cfg.trials = indx3;
wlearly = ft_selectdata(cfg, data);

indx4 = intersect(find(ismember(T,[3 4 7 8])), indx_late);
cfg.trials = indx4;
wllate = ft_selectdata(cfg, data);


% balance for lexical frequency across the four conditions: sentearly,
% sentlate, wlearly, wllate

% mous_stratify randomly removes trials to create a balanced in lexical
% frequency and number of trials, across conditions
% In mous_stratify:
% 1. call randomseed to use same randomization within subject
% 2. call ft_stratify which (randomly) removes trials in order to balance
% conditions

cfg = [];
cfg.binedges   = -2:0.2:4.8;
cfg.rseedinput = rseedinput;
[sentearly, sentlate, wlearly, wllate] = mous_stratify(cfg, ...
{sentearly L(indx1)}, {sentlate L(indx2)}, {wlearly L(indx3)}, {wllate L(indx4)});

% recover original position of trials in full dataset
% averaging across trials is done at a higher level (mous_makecontrast)
[c,i1] = intersect(data.trialinfo(:,7),sentearly.trialinfo(:,7));       
[c,i2] = intersect(data.trialinfo(:,7),sentlate.trialinfo(:,7));
[c,i3] = intersect(data.trialinfo(:,7),wlearly.trialinfo(:,7)); 
[c,i4] = intersect(data.trialinfo(:,7),wllate.trialinfo(:,7)); 

varargout{1} = i1;
varargout{2} = i2;
varargout{3} = i3;
varargout{4} = i4;
