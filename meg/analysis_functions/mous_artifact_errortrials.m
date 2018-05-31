function id = mous_artifact_errortrials(subjectname)

% function to extract the stimulus IDs of the sentences/lists, where the
% subjects provided an incorrect response, to be used as information to
% throw away trials in single subject analysis.

load mous_stimuli;
stim = {stimuli.string}';
for k = 1:numel(stim)
  if isempty(stim{k})
    stim{k} = '';
  end
end
stim = lower(stim);

% extract the logfile
log = read_logfile_visual(subjectname);

sel    = find(contains(log, 'QUESTION')&contains(log, 'incorrect'));% & startsWith(log, 'V'));
selfix = find(contains(log, 'FIX'));
id = nan(numel(sel),1);
for m = 1:numel(sel)
  sel2 = selfix(find(selfix-sel(m)<0,1,'last'));
  tmplog = log(sel2:sel(m),:);
  for mm = 1:size(tmplog,1)
    tmplog{mm}(isspace(tmplog{mm}))='.';
    tok = tokenize(tmplog{mm},'.');
    tmplog{mm} = tok{4}(2:end);
    tmplog{mm}(isspace(tmplog{mm})) = '';
  end
  tmplog = tmplog(2:2:end-1)';
  str = tmplog{1};
  for mm = 2:numel(tmplog)
    str = [str ' ' deblank(tmplog{mm})];
  end
  if any(find(contains(stim,lower(str))))
    id(m,1) = stimuli(find(contains(stim,lower(str)))).id;
  else
    id(m,1) = nan;
  end
  
  if ~isfinite(id(m))
    % fall back to option 2, the sentence words are of type <trigger>
    % <space> word, thus above heuristic fails, should take tok{5}
    tmplog = log(sel2:sel(m),:);
    for mm = 1:size(tmplog,1)
      tmplog{mm}(isspace(tmplog{mm}))='.';
      tok = tokenize(tmplog{mm},'.');
      tmplog{mm} = tok{5}(1:end);
      tmplog{mm}(isspace(tmplog{mm})) = '';
    end
    tmplog = tmplog(2:2:end-1)';
    str = tmplog{1};
    for mm = 2:numel(tmplog)
      if ~isempty(tmplog{mm})
        str = [str ' ' deblank(tmplog{mm})];
      end
    end
    if any(find(contains(stim,lower(str))))
      id(m,1) = stimuli(find(contains(stim,lower(str)))).id;
    else
      id(m,1) = nan;
    end
  end
  
  
end

