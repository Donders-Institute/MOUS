function [textgrid_data] = mous_read_textgrid(filename)

% MOUS_READ_TEXTGRID reads *.TextGrid files containing timing information for the
% individual words in the file
%
% Input argument:
%   path of the *.TextGrid file
%
% Output argument:
%   matrix with wordid in the first column and time of onset in the second
%

file_id = fopen(filename);

%-----------------------------------------
% first few lines contain the general header

% check the first and second lines
line   = fgetl(file_id);
line2  = fgetl(file_id);

% report error if the file is of the wrong type
if ~strcmp(line, 'File type = "ooTextFile"') || ~strcmp(line2, 'Object class = "TextGrid"')
  error('the file %s may be of an unsupported file format, abort reading');
end

line = fgetl(file_id);
while ~isnumeric(line) 
  line = fgetl(file_id);
  switch line
    case ''
      % do nothing
    case -1
      break;
    otherwise
      % process the line
      if ~isempty(strfind(line, 'points ['))
        idx  = str2double(line( (strfind(line, 'points')+8):(strfind(line, ']')-1) ));
        line = fgetl(file_id);
        if ~isempty(strfind(line, 'number'))
          time = str2double(line( (strfind(line, 'number')+8):end ));
          textgrid_data(idx,1) = round(idx);
          textgrid_data(idx,2) = time;
        elseif ~isempty(strfind(line, 'time'))
          time = str2double(line( (strfind(line, 'time')+7):end ));
          textgrid_data(idx,1) = round(idx);
          textgrid_data(idx,2) = time;
          
        end 
      elseif ~isempty(strfind(line, 'xmax')) && strfind(line, 'xmax')==1
        duration = str2double(line( 8:end ));
      end
  end
end
textgrid_data(end+1,1) = nan;
textgrid_data(end  ,2) = duration;

fclose(file_id);
