% This script has been run on a windows machine to take advantage of the
% xls-file reading functionality that is not present under Linux.
% Intended functionality:
%  -extract the coded relative clause and prepositional clause ordinal onsets and 
%  offsets that have been marked by Laura, and convert that to a more
%  convenient format
%  -link a stimulus identifier to the content of the stimulus

% use the JMS version because this has some inconsistencies (questions by
% Laura?) removed, which allows for easier processing
clear all;
[data_num,data_txt,data_raw] = xlsread('COMPLETEstimulusSet_RelativeClauseCheck_19052014_JMS.xls');

% convert the data into a structure.
sel = find(isfinite(data_num(:,1)));
for k = 1:numel(sel)
  % get a numeric identifier
  ix = data_num(sel(k),1);
  stimuli(ix).id = ix;
  
  % get the text
  str = '';
  tmp = data_txt(sel(k),:);
  for m = 1:numel(tmp)
      if ~isempty(tmp{m})
          str = [str, tmp{m}, ' '];
      end
  end
  str = str(1:end-1);
  stimuli(ix).string   = str;
  stimuli(ix).numwords = sum(~cellfun('isempty', tmp));
  
  % get the additional info
  if ix<205
      % RC sentence codes mean something else than in non-RC sentences
      stimuli(ix).RConsetword        = data_num(sel(k),18);
      stimuli(ix).MCcontinuationword = data_num(sel(k),19);
      
      tmp = data_num(sel(k),20);
      if ~isfinite(tmp),
          tmp = 0;
      end
      stimuli(ix).numadditionalclauses = tmp;
      if tmp>0
          tmp2 = reshape(data_num(sel(k),21:end),2,[])';
          stimuli(ix).additionalclauseinfo = tmp2(sum(isfinite(tmp2),2)>0,:);
      end
  else
      
      tmp = data_num(sel(k),18);
      if ~isfinite(tmp),
          tmp = 0;
      end
      stimuli(ix).numadditionalclauses = tmp;
      if tmp>0
          tmp2 = reshape(data_num(sel(k),19:end),2,[])';
          stimuli(ix).additionalclauseinfo = tmp2(sum(isfinite(tmp2),2)>0,:);
      end
      
  end
end

