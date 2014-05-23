function [newtext, stimuli] = read_logfile_visual(subjectname)

%% Read in logfile
filename = mous_db_getfilename(subjectname,'meg_raw_log');

intxt   =  filename{1};
fid     = fopen(intxt);
fseek(fid,0,'eof');  % at eof to get number of elements in text
numelm  = ftell(fid);
fseek(fid,0,'bof');  % at bof to start reading
alltxt  = fread(fid,numelm,'uint8=>char');  % whole logfile
fclose(fid);

%% remove excessive information i.e. lines without words (preceded by a trigger)
% need to use regexp as there is not a consistent format in the logfile
% finaltext{1} = X xx
% finaltext{101} = Xxx
% finaltext{360} = X xx.  (end of sentence)


idx = strfind(alltxt(:)', subjectname); % skip over the line of logfile that codes the extra 'empty word'
% only index the lines that
% begin with 'V1XXX' or 'v1XXX'
if isempty(idx)
  subjectnameL = lower(subjectname);  % for some subjects, the logfile has 'v1XXX' instead of 'V1XXX'
  idx = strfind(alltxt(:)', subjectnameL);
end
if isempty(idx)
  idx = regexp(alltxt(:)',subjectname(2:end)); % for A2009 (and incase there are others) whose logfile lines begin without the 'A' (or 'V')
end

add = idx(end)+80;   % make sure get all information from logfile because 'idx' only gets the first position of the line of interest in the logfile
idx = [idx add];

alltxt = alltxt';
newtext = cell(numel(idx)-1,1);  %regroup alltxt to represent each line of interest in the logfile
for k = 1:numel(idx)-1
  newtext{k} = alltxt(idx(k):idx(k+1)-1);  % easier to find relevant entry lines in txtfile
end

stimuli = parselogfile(newtext)';

function sentence = parselogfile(txt)

selfix = find(~cellfun('isempty',strfind(txt, 'FIX')));
selfix = [selfix;numel(txt)+1];
for k = 1:numel(selfix)-1
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
    str = [str ' ' deblank(word{m})];
  end
  sentence{k} = deblank(str);
end
