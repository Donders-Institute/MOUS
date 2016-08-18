function [textgrid_data] = read_textgrid(filename)

% READ_TEXTGRID reads *.TextGrid files containing timing information for the
% individual words in the file
%
% Input argument:
%   path of the *.TextGrid file
%
% Output argument:
%   data structure containing some header info and the following fields:
%     times = Nx2 matrix with the corresponding begin and end times
%     words = Nx1 cell-array with the words
%

file_id = fopen(filename);

%-----------------------------------------
% first 7 lines contain the general header

% check the first and second lines
line   = fgetl(file_id);
line2  = fgetl(file_id);

% report error if the file is of the wrong type
if ~strcmp(line, 'File type = "ooTextFile"') || ~strcmp(line2, 'Object class = "TextGrid"')
  error('the file %s may be of an unsupported file format, abort reading');
end

% skip a few lines data
skiplines(file_id, 4);

% get the number of tiers
ntier = str2double(fgetl(file_id));

% end of header
%----------------------------------


% loop over the tiers
textgrid_data = struct('speaker', '', 'time_beg', nan, 'time_end', nan, 'ninterval', nan, 'times', [], 'words', {});
for k = 1:ntier
  fgetl(file_id);               % reads the line saying "IntervalTier", does nothing.
  speaker = fgetl(file_id);
  textgrid_data(k).speaker   = speaker(2:end-1);
  textgrid_data(k).time_beg  = str2double(fgetl(file_id));
  textgrid_data(k).time_end  = str2double(fgetl(file_id));
  textgrid_data(k).ninterval = str2double(fgetl(file_id));

  % read the text for this tier
  times = zeros(textgrid_data(k).ninterval,2);       % create 2 columns for start and end times
  words = cell(textgrid_data(k).ninterval,1);        % create 1 column for the word
  
  index = 1;
  while 1
    
    % check if there is a word or an empty string (indicating silence in audio)
    position = ftell(file_id);
    skiplines(file_id, 2)               % move 2 lines forward to the line with the word
    line = fgetl(file_id);
    
    if strcmp(line, '""')
      continue
    end
    fseek(file_id, position, -1);       % move to the position in file indicated by 'position'

    position = ftell(file_id);          % get position in file
    line = fgetl(file_id);              % get the line from file
    
    % checks for the next tier (the line saying "IntervalTier") or EOF
    if strcmp(line, '"IntervalTier"') || ~ischar(line)
      fseek(file_id, position, -1);
      % remove zeroes from the end of 'times' array
      times(~any(times, 2), :) = [];
      % remove empty cells from the end of the 'words' cell array 
      emptyCells = cellfun('isempty', words); 
      words(emptyCells) = [];
      break
    end
    fseek(file_id, position, -1);       % move back one line
    
    times(index, 1) = str2double(fgetl(file_id));
    times(index, 2) = str2double(fgetl(file_id));
    
    % check if there is a fullstop at the end of the word
    % if so, remove it and add the fullstop as the next word in column
    word = fgetl(file_id);
    if strcmp(word(end-1), '.')
      word = strrep(word, '.', '');     % remove the dot
      words{index, 1} = word;           % remove the quotation marks
      
      index = index + 1;
      times(index, 1) = times(index-1, 2);  % NOT a typo..
      times(index, 2) = times(index-1, 2);
      words{index, 1} = '.';
      
    else
      words{index, 1} = word;           % remove the quotation marks
      
    end
    
    index = index+1;                    % increment the index  
    
  end
  
  textgrid_data(k).times = times;
  textgrid_data(k).words = words;
  
end

fclose(file_id);


function skiplines(file_id, n)

for k = 1:n
  fgetl(file_id);
end
