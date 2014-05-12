function [event] = read_logfile_audio(subjectname)

filename = mous_db_getfilename(subjectname, 'meg_raw_log');

for k = 1:numel(filename)        % loop created since A2036 has >1 logfile to be used 
  
  % open logfile
  fid = fopen(filename{k});
 
  % read line-by-line
  line = fgetl(fid);
  while isempty(strfind(line, subjectname))
    % we are still in the header of the file
    line = fgetl(fid);
  end

  % now we are going to parse each line to extract the relevant info
  % we cannot use textscan because the number of columns per line may be
  % different
  event{k} = [];
  while ~isempty(strfind(line, subjectname))
    tok  = tokenize(line, char(9), 1); % use tab as delimiter, multiple allowed

    % somehow the 4th column is often a trigger value plus event string
    % deal with this below

    triggervalue = [];
    triggertime  = [];
    switch tok{3}
      case 'Picture'
        if ~isempty(strfind(tok{4}, 'FIX'))
          triggervalue = 20;
          triggertime  = str2double(tok{5});
          triggertype  = 'fixation';
        elseif ~isempty(strfind(tok{4}, 'QUESTION'))
          triggervalue = 40;
          triggertime  = str2double(tok{5});
          triggertype  = 'question';
        elseif ~isempty(strfind(tok{4}, 'ZINNEN'))
          triggervalue = 10;
          triggertime  = str2double(tok{5});
          triggertype  = 'zinnen';
        elseif ~isempty(strfind(tok{4}, 'WOORDEN'))
          triggervalue = 10;
          triggertime  = str2double(tok{5});
          triggertype  = 'woorden';
        else
        end
      case 'Nothing'
        if ~isempty(strfind(tok{4}, 'Audio onset'))
          triggervalue = str2double(tok{4}(1)); % code 1:8, i.e. 1 digit
          triggertime  = str2double(tok{5});
          triggertype  = 'onset firstword';
        elseif ~isempty(strfind(tok{4}, 'target'))
          triggervalue = str2double(tok{4}(1)); % code 1:8, i.e. 1 digit
          triggertime  = str2double(tok{5});
          triggertype  = 'onset targetword';
        elseif ~isempty(strfind(tok{4}, 'End of file'))
          triggervalue = str2double(tok{4}(1:2)); % code 15, i.e. 2 digits
          triggertime  = str2double(tok{5});
          triggertype  = 'offset audiofile';
        end
      case 'Sound'
        if ~isempty(strfind(tok{4}, 'Start File'))
          triggervalue = str2double(tok{4}(1:2)); % code 14, i.e. 2 digits
          triggertime  = str2double(tok{5});
          tmp = strfind(tok{4}, 'Start File');
          triggertype = tok{4}((tmp+11):end);
        else
        end

      otherwise
    end
    if ~isempty(triggervalue)
      event{k}(end+1).type = triggertype;
      event{k}(end).value  = triggervalue;
      event{k}(end).sample = triggertime;
    end
    line = fgetl(fid);
  end

  fclose(fid);
end