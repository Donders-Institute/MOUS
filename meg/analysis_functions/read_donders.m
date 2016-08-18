function [donders_data] = read_donders(filename)



% READ_DONDERS reads a textfile with the extension .donders, assuming the
% first line to contain the info about the fields
%
% Use as
%   data = read_donderstest(filename)
%
% Input argument:
%   filename = string that points to a file with the extension donders
%   
% Output argument:
%   data     = structure array containing the data represented in the text
%              file, containing the fields as named in the first line of
%              the file


fid   = fopen(filename);
fseek(fid, 0, 1);  
end_of_file = ftell(fid);
frewind(fid);

donders_data = struct([]);
  
row = 0;
while 1
  
  line   = fgetl(fid);              % get a single line from file
  file_position  = ftell(fid);      
  
  if isequal(line, -1)
    break;
  end
  
  % determine the entries in a single row using regex
  % columns can be either separated by space or tab
  exp = '[ \t]';
  entries_in_row = regexp(line, exp, 'split');
  
  % on the first iteration (first row) get the names of the fields
  if row == 0  
    for i = 1:length(entries_in_row)
      % replace '#' and/or '-' with underscores
      field_name{1, i} = regexprep(entries_in_row(i), '[#-]', '_'); 
    end
    
  % Check if the line is empty - if so, get to the next line in the file
  elseif strcmp(line, '')
    continue;
    
  % get every entry for the row and store the values in the appropriate 
  % field in structure array "data"
  else
    entries_in_row = entries_in_row(1:numel(field_name));
    
    for i = 1:length(entries_in_row)
      donders_data = assignoutput(donders_data, row, field_name{1, i}{1}, entries_in_row(i));  
      % TO FIX subscripting field_name with {1} cos its a cell...
    end
  end
  
  row = row+1;
  
  if file_position == end_of_file   % break if end of file
    break;
  end
   
end


function donders_data = assignoutput(donders_data, row, field_name, val)

switch field_name
  case {'word' 'POS' 'lemma' 'deprel' 'prediction' 'file'}
    donders_data(row,1).(field_name) = val;
  case {'sent_' 'word_' 'depind' 'logprob' 'entropy' 'perplexity' 'gra_perpl' 'pho_perpl' 'depjump' 'nrwords'	...
        'wordlen_av' 'wordlen_sd'	'wordlen_md' 'wordlen_iq' ...
        'deplen_av'	 'deplen_sd'	'deplen_md'  'deplen_iq' ...
        'perpl_av' 'perpl_sd' 'perpl_md' 'perpl_iq'}
    donders_data(row,1).(field_name) = str2double(val);
  otherwise
    error('invalid fieldname');
end

