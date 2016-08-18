function [stimuli, items, lexfreq] = mous_stimuli_lexfreq

load('mous_stimuli');

% load the frequency data
fid = fopen('mous_words_isubtlex.csv');
ok  = true;

% skip the first line
fgetl(fid);

items = cell(0,1);
lexfreq = zeros(0,1);
while ok
  tline = fgetl(fid);
  if ischar(tline)
    tok = tokenize(tline, ';');
    items{end+1,1}   = tok{1};
    lexfreq(end+1,1) = str2double(tok{3});
    
  else
    break;
  end
end
fclose(fid);

for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    for m = 1:stimuli(k).numwords
      id = find(strcmpi(stimuli(k).words(m).word{1}, items));
      if ~isempty(id)
        stimuli(k).words(m).lexfreq = lexfreq(id);
      else
        stimuli(k).words(m).lexfreq = nan;
      end
    end
  end
end
