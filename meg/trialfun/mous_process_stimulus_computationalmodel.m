% this script is used to append information to the stimuli struct-array,
% incorporating the output from Antal's computational model to the data

load mous_stimuli;

x = read_donders(fullfile('/home/language/jansch/projects/mous/meg/stimuli/','mous_stimuli.txt.donders'));
y = read_donders(fullfile('/home/language/jansch/projects/mous/meg/stimuli/','mous_stimuli.txt.stats'));

% match x and y, and merge it into z
x_sentid = [x.sent_];
y_sentid = [y.sent_];
z = y;
for k = 1:numel(y_sentid)
  curr_match = x_sentid==y_sentid(k);
  z(k).words = x(curr_match);
end

% match z to stimuli
for k = 1:numel(z)
  % get the text
  str = '';
  tmp = [z(k).words.word];
  for m = 1:numel(tmp)
    if ~isempty(tmp{m})
      str = [str, tmp{m}, ' '];
    end
  end
  str = str(1:end-1);
  text_data{k} = str;
end

ok = false(numel(stimuli));
for k = 1:numel(stimuli)
  ix = strcmp(stimuli(k).string, text_data);
  if sum(ix)
    ok(k) = true;
    indx(k) = find(ix);
  else
    indx(k) = nan;
  end
end

fnames = fieldnames(z);
fnames = fnames(2:end); % remove 'file'

for k = 1:numel(stimuli)
  if isfinite(indx(k))
    for m = 1:numel(fnames)
      stimuli(k).(fnames{m}) = z(indx(k)).(fnames{m});
    end
  end
end


