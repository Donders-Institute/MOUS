function str = print_stimuli_string(stimuli, ix)

% PRINT_STIMULI_STRING plots the string and the corresponding depind in a
% nice format

if numel(ix)>1,
  for k = 1:numel(ix)
    str{k} = print_stimuli_string(stimuli, ix(k));
  end
  return;
end

str    = stimuli(ix).string;
spaces = [0 strfind(str, ' ')];

for k = 1:numel(spaces)
  tmp = num2str(k);
  str(2,spaces(k)+(1:numel(tmp))) = tmp;
  tmp = num2str(stimuli(ix).words(k).depind);
  str(3,spaces(k)+(1:numel(tmp))) = tmp;
  tmp = num2str(ix);
  str(4,1:numel(tmp)) = tmp;
end
str(5,1) = ' ';
str = str([4 1 2 3 5],:);
disp(str);
