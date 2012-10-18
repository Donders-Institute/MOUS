function [trl] = mous_defineTrial(filename, prestim, poststim, wordType, trialfun)

cfg                   = [];
cfg.dataset           = filename;
cfg.trialdef.prestim  = prestim;              % baseline
cfg.trialdef.poststim = poststim-1./1200;     % pad
cfg.trialfun          = trialfun;             % 'visual_word' or 'visual_sentence'
[cfg]                 = ft_definetrial(cfg);  % ft_definetrial defines trials which are created in cfg.trl which is a parameter for ft_preprocessing
trl                   = cfg.trl;

if (strcmp(wordType,'all') > 0)              % focus on all words
    trl = trl;

elseif (strcmp(wordType,'target') > 0)           % focus on the target words
    sel = mod(trl(:,5),2)==0; 
    trl = trl(sel,:);
    
elseif (strcmp(wordType,'tarplusOne') > 0)   % focus on the 1st word after the target
    sel_tar = mod(trl(:,5),2)==0;            % all triggers, 1 = target
    if sel_tar(end) == 1                     % if ultimate word is a target, then remove the last target's index. 
        sel_tar = sel_tar(1:end-1);          % Otherwise trl(sel_tar,4) will not be the same size as trl(tarOne_tmp,4)
    end
    tarOne_tmp = [false;sel_tar(1:end-1)];   % all triggers, 1 = tar+1 
    sel_tarOne = find(tarOne_tmp);           % index position of all tar+1 
    sel_tarOne = sel_tarOne(trl(sel_tar,4)==trl(tarOne_tmp,4));  % trial of tar+1 = trial of target % ORIG4;.js
    trl        = trl(sel_tarOne,:);
    
elseif (strcmp(wordType,'tarplusTwo') > 0)   % focus on the 2nd word after the target
    sel_tar = mod(trl(:,5),2)==0;
    if sel_tar(end) == 1 || sel_tar(end-1) == 1; % if penultimate is a target, then remove the last target's index. 
        sel_tar = sel_tar(1:end-2);            % Otherwise trl(sel_tar,4) will not be the same size as trl(tarOne_tmp,4)
    end    
    tarTwo_tmp = [false; false; sel_tar(1:end-2)];  
    sel_tarTwo = find(tarTwo_tmp);    
    sel_tarTwo = sel_tarTwo(trl(sel_tar,4)==trl(tarTwo_tmp,4)); % doesn't work if target is penultimate word in sentence 
    trl      = trl(sel_tarTwo,:);                               % accounting that the last X-15 pair does not actually have a word.
end 
