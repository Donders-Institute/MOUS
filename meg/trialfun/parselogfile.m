function sentence = parselogfile(txt);

selfix = find(~cellfun('isempty',strfind(txt, 'FIX')));
selfix = [selfix;numel(txt)+1];
for k = 1:numel(selfix)
  tmp = txt((selfix(k)+1):(selfix(k+1)-1));
  sel = find(cellfun('isempty',strfind(tmp, 'ISI')));
  tmp = tmp(sel);
 
  % extract the words
  word = cell(1,numel(tmp));
  for m = 1:numel(tmp)
    ix   = regexp(tmp{m}, 'Picture');
    [str1,str2] = strtok(tmp{m}((ix+8):end));
    
    if isempty(str1) && isempty(str2)
      word{m} = '';
      continue;
    end
    
    if strcmp(str1, 'blank')
      word = word(1:(m-1));
      break;
    end
    
    % now it seems that sometimes the trigger is not separated from the
    % word by a space (sequences?), and sometimes it is.
    if numel(str1)==1
      word{m} = strtok(str2);
    elseif isfinite(str2double(str1(1)))
      word{m} = strtok(str1(2:end));
    end
    
    % the following only works for sentences, because they end with a full
    % stop
    if ~isempty(strfind(word{m},'.'))
      word{m} = word{m}(1:(strfind(word{m},'.')-1));
      word    = word(1:m);
      break;
    end
  end
  
  % convert it into a single string
  str = word{1};
  for m = 2:numel(word)
    str = [str ' ' word{m}];
  end
  sentence{k} = str;
end
 