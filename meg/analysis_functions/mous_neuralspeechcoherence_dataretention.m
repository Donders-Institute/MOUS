function [remain] = mous_neuralspeechcoherence_dataretention
% mous_neuralspeechcoherence_dataretention determines the amount of data
% retained after artifact rejection.

[subjlist,~] = mous_db_getfilename('allA','subjectname');
% subjlist = {'A2011'};

for q = 1:numel(subjlist)
  % load raw data
  dataset   = mous_db_getfilename(subjlist(q), 'meg_raw_task');

  % define trials, remove artifacts, preprocess data
  if numel(dataset) == 1
    mous_db_getdata(subjlist(q),'meg_artifact_cfg','/project/3011020.09/MEG/');
    artfctcfg      = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [pre, post]    = computedata(dataset{1}, artfctcfg);

  elseif numel(dataset) > 1
    for k = 1:numel(dataset)
      tmpdataset    = dataset{k};
      mous_db_getdata(subjlist(q), ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
      tmpartfctcfg  = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
      [pre, post]   = computedata(tmpdataset, tmpartfctcfg);
      
      if k == 1
        pre1  = pre;
        post1 = post;
      else 
        pre2  = pre;
        post2 = post;
        
        pre   = [pre1; pre2];
        post  = [post1; post2];
      end 
    end
  end
  
  raw   = sum(pre(:,2) - pre(:,1)); 
  clean = sum(post(:,2) - post(:,1));
  remain(q) = (clean/raw)*100;
  
end

%%%%%%%%%%%%%%%
%% subfunction%
%%%%%%%%%%%%%%%

function [trl,trl2] = computedata(dataset, artfctcfg)

%% define trial
cfg                   = [];
cfg.dataset           = dataset;
cfg.trialfun          = 'trialfun_auditory_sentence';
cfg.trialdef.prestim  = 'audioonset';
cfg.trialdef.poststim = 0.2;
cfg = ft_definetrial(cfg);

%% define audio onset to be time point 0, and remove artifacts
trl = cfg.trl;
trl(:,3) = 0;
trl2 = mous_artifact_remove(trl, dataset, artfctcfg, 'partial', 1); 

