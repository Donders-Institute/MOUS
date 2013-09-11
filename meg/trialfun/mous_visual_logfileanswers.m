function [output] = mous_visual_logfileanswers(subjectname)

%% Read in logfile
[oritxt] = read_logfile_visual(subjectname);

% get indices of logfile that contains 'Response' which codes the
% response to question of the current trial (sent/seq)
wordpresent = zeros(size(oritxt));
for m = 1:size(oritxt,1)
    check = regexp(oritxt{m},'Question\d\d');  % check if text of interest exists
    if ~isempty(check)
        wordpresent(m) = 1;
    end 
end 
idxq = find(wordpresent == 1);
idxr = idq + 1;
onlyresp = oritxt(idxq); % only parts of logfile that contain responses;

% In the logfile:
% Response 1 &  Response 2 - these are fine
% Response  3 - do not code this because it is the experimenter pressing
% the space bar, nothing to do with the subject


end 


%  the following was found for the first question in V1106; see if the num
%  spaces is regular  across Questions in the logfile.
%% Response <spaces> X 
% X = response on button box (1 or 2)
% number of spaces = 19  