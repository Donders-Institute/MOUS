% trialfuns:
%            'auditory_sentence' 
%            'auditory_word';     % onset of speech for first word and target word
%            'visual_word';       % onset of each word (but not fixation cross)
%            'visual_sentence';   % onset of fixation cross until offset of last word (marks target word type; can also retrieve first word info but not in default trl)

if ~exist('subjectname', 'var')
  error('you should specify a subjectname when running mous_preprocessing_pipeline');
end

if ~exist('prestim',      'var'), prestim      = 0.2; end
if ~exist('poststim',     'var'), poststim     = 1.0; end
if ~exist('resamplefs',   'var'), resamplefs   = 300; end
if ~exist('analysisType', 'var'), analysisType = 'ERF'; end % can be 'TFR'
if ~exist('trialfun',     'var'), 
  if strcmp(subjectname(1),'V')
    trialfun = 'trialfun_visual_word';
  else
    trialfun = 'trialfun_auditory_word';
  end
end
if ~exist('rootdir','var'), rootdir = '/project/3011020.09/annhul/';  end  % directory for saving

fprintf('Preprocessing subject %s  \n', subjectname);
mous_db_makesubjdir(subjectname)

% get the filename of the raw data
filename    = mous_db_getfilename(subjectname, 'meg_ds_task');

for k = 1:numel(filename)
  if numel(filename)==1
    % get the description of the artifacts
    mous_db_getdata(subjectname, 'meg_artifact_cfg');
    try
      mous_db_getdata(subjectname, 'meg_artifact_cfg_manual');
    catch
      cfgmanual.visual.artifact = [];
      cfgmanual.artfctdef.type = [];
    end
  else
    mous_db_getdata(subjectname, ['meg_artifact_cfg_pt',num2str(k)]);
    try
      mous_db_getdata(subjectname, ['meg_artifact_cfg_manual_pt',num2str(k)]);
    catch
      cfgmanual.visual.artifact = [];
      cfgmanual.artfctdef.type = [];
    end
  end 
   
  % add this part to ensure that there is sufficient filter padding around
  % jumps -> mous_artifact_squidjumps has fltpadding to be 0, now if we do
  % a highpass filter, this will interfere with jumps and cause problems
  if ~isempty(cfgjump.artfctdef.zvalue.artifact)
    % take half the data padding length for preprocessing
    cfgjump.artfctdef.zvalue.artifact(:,1) = cfgjump.artfctdef.zvalue.artifact(:,1)-1200*2.5;
    cfgjump.artfctdef.zvalue.artifact(:,2) = cfgjump.artfctdef.zvalue.artifact(:,2)+1200*2.5;
  end
  [trl] = mous_defineTrial(filename{k}, prestim, poststim, trialfun);
  [trl] = mous_artifact_remove(trl, filename{k}, {cfgeog1 cfgeog2 cfgjump cfgmuscle cfgmanual});
  tmp   = mous_preprocessing(filename{k}, trl, resamplefs, analysisType);
  if k==1
    data       = tmp;
    tmpsens(k) = tmp.grad;
    weights(k) = numel(tmp.trial);
  end
  
  if k>1
    % update the sentence counter in the trialinfo
    tmp.trialinfo(:,1) = tmp.trialinfo(:,1) + data.trialinfo(end,1);
    
    data       = ft_appenddata([], data, tmp);
    tmpsens(k) = tmp.grad;
    weights(k) = numel(tmp.trial);
  end
  clear tmp;
end 

% create a weighted average of the gradiometers
if numel(filename)>1
  data.grad = ft_average_sens(tmpsens, 'weights', weights);     
end

if ~ischar(poststim)
  length = [num2str(prestim*10,'%02d'),'-',num2str(poststim*10,'%02d')];
else
  length = [num2str(prestim*10,'%02d'),'-',poststim];
end
%mous_db_putdata(subjectname, ['meg_erf_allwords_',length], 'data',rootdir,1);
mous_db_putdata(subjectname, ['meg_erf_allwords_',length], 'data',rootdir,0);

