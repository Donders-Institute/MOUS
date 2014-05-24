function id = mous_getstimulusid(sentence, stimuli)

% MOUS_GETSTIMULUSID extracts a numeric identifier for each element in the
% cell-array sentence, based on the stimulus structure stimuli.
%
% Use as
%   id = mous_getstimulusid(sentence,stimuli);

str = {stimuli.string};
sel = find(~cellfun('isempty', str));
str = str(sel);
stimuli = stimuli(sel);

id = nan+zeros(numel(sentence),1);
for k = 1:numel(sentence)
  tmp = lower(sentence{k});
  if strcmp(tmp(1), ' ')
    [tmp1, tmp2] = strtok(tmp);
    tmp = [tmp1 tmp2];
  end
  tmp = find(~cellfun('isempty', strfind(lower(str), tmp)));
  if ~isempty(tmp)
    id(k,1) = tmp;
  elseif isempty(tmp)
    % a full match was not found, could be due to a typo, try the first
    % 75% characters
    tmp = find(~cellfun('isempty', strfind(lower(str), lower(sentence{k}(1:round(0.75*numel(sentence{k})))))));
    if ~isempty(tmp)
      id(k,1) = tmp;
    end
  end
end
for k = 1:numel(id)
  if isfinite(id(k))
    id(k) = stimuli(id(k)).id;
  end
end
id = id(:);