function [comp, data] = mous_bfica_sourcedatadss(subjectname, rootdir)

if nargin<2
  rootdir = '';
end

data           = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_sourcedata}', rootdir);

toi            = -0.85:0.05:12;
[trial, time, trialinfo] = trial2sentences(data.trial{1}, data.trialinfo(:,[1 5]), toi);
source         = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_source}', rootdir);

% get the trial definition for the words
dataset      = mous_db_getfilename(subjectname, 'meg_raw_task');
cfg          = [];
cfg.dataset  = dataset{1};
cfg.trialfun = 'trialfun_visual_word';
cfg.trialdef.prestim  = 0;
cfg.trialdef.poststim = 0;
cfg          = ft_definetrial(cfg);
trl          = cfg.trl;
wordinfo     = trl(:,[4 6 7]); % 4th column is trial index, 6th column is word start
wordinfo(:,2:3) = wordinfo(:,2:3)/1200; % in s

p  = cell(1,numel(trialinfo));
ppst = cell(1,numel(trialinfo));
ppre = cell(1,numel(trialinfo));
for k = 1:numel(trialinfo)
  tmp = wordinfo(wordinfo(:,1)==trialinfo(k),:);
  if ~isempty(tmp)
    cnt = 0;
    for m = 1:size(tmp,1)
      try
        ix  = nearest(time{k},tmp(m,2),true);
        cnt = cnt+1;
        p{k}(1,cnt)    = ix;
        ppre{k}(1,cnt) = 0;%3;
        ppst{k}(1,cnt) = floor((tmp(m,3)+0.3333-0.125)/0.05); % assume a window of 0.250 and 0.05 steps
      catch
      end
    end
  end
end
paramscell.tr       = p;
paramscell.tr_begin = ppre;%3;
paramscell.tr_end   = ppst;%16;
paramscell.demean   = true;

% keep track of the condition per trial
T          = data.trialinfo;
[uT,iT,jT] = unique(T(:,1));
T          = T(iT,1:2);

for k = 1:numel(trialinfo)
  trialinfo(k,2) = T(T(:,1)==trialinfo(k),2);
end

data.trial = trial;
data.time  = time;
data.trialinfo = trialinfo;
clear trial time trialinfo

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = paramscell;
cfg.dss.wdim          = 100;
cfg.numcomponent      = 50;
cfg.cellmode          = 'yes';
comp                  = ft_componentanalysis(cfg, data);

