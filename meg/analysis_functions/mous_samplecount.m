function  mous_samplecount(subjectname,datasegmenter,artifactsel,saveartifact)
% this function quantifies the amount of data (in samples) before and after
% preprocessing (artifact rejection)
% quantified in terms of 
% (1) number of samples
% (2) number of trials, for each conditions (sent and word list)

% datasegmenter: 'meg_artifact_rawprocsamplediff_trialfunword' or '...trialfunsent'
% artifactsel:


rootdir = '/project/3011020.09/MEG';
  
% define trial for RAW data and get sample information
dataset = mous_db_getfilename(subjectname,'meg_raw_task',0,'/project/3011020.09/MEG');

% load detected artifact(s) and combine raw datasets if necessary
if numel(dataset)>1
  for k = 2:numel(dataset)
    tmpdataset   = dataset{k};
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);  % separate artifact cfg for each task file
    tmpartfctcfg = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
    [trlpre trlpost] = compute_data(tmpdataset, tmpartfctcfg,subjectname,datasegmenter,artifactsel);
    
    if k==2,
      pre = trlpre;
      post = trlpost;
    else
      % update the sentence counter
      pre   = [pre;  trlpre];
      post  = [post; trlpost]; 
    end
  end 
else
  mous_db_getdata(subjectname, 'meg_artifact_cfg');
  artfctcfg = {cfgeog1 cfgeog2 cfgjump cfgmuscle};
  [pre,post]      = compute_data(dataset{1}, artfctcfg, subjectname,datasegmenter,artifactsel);
end

mous_db_putdata(subjectname,[datasegmenter,'_',saveartifact],'pre','post',rootdir,1);


% subfunction for preprocessing %%
function [trlpre trlpost] = compute_data(dataset, artfctcfg, subjectname,datasegmenter,artifactsel)

% get data and apply artifact rejection
cfg          = [];
cfg.dataset  = dataset;

if regexp(datasegmenter,'sent')
  if strcmp(subjectname(1),'V')
    cfg.trialfun = 'trialfun_visual_sentence';
  elseif strcmp(subjectname(1),'A')
    cfg.trialfun = 'trialfun_auditory_sentence';
    cfg.trialdef.prestim = 0.2;
  end
else
  if strcmp(subjectname(1),'V')
      cfg.trialfun = 'trialfun_visual_word';
      cfg.trialdef.prestim = 0.2; 
      cfg.trialdef.poststim = 'nextword'; 
  elseif strcmp(subjectname(1),'A')
      cfg.trialdef.prestim = 0.5;  % if use 0.3, timepoint -0.15s (because of f_timwin = 0.4) will be NaNs!!
      cfg.trialdef.poststim = 0.8;
      if strcmp(subjectname,'A2036')
        cfg.trialfun = 'trialfun_auditory_word_A2036';
      else
        cfg.trialfun = 'trialfun_auditory_word';
      end
  end
end
cfg          = ft_definetrial(cfg);
trlpre       = cfg.trl;
whichart = [1 2 3 4]; % default remove all artifacts
whichart = whichart(logical(artifactsel));
trlpost      = mous_artifact_remove(trlpre, dataset, artfctcfg(whichart), 'partial', 0.1); 

% trl > 2 second does not make sense, sanity check: FIXME
if regexp(datasegmenter,'word')
  nsmp = trlpost(:,2)-trlpost(:,1);
  trlpost  = trlpost(nsmp<2400,:);
end 



