function [output] = mous_visual_logfileanswers(subjectname)

%% Read in logfile
% In the logfile:
% Response 1 &  Response 2 are responses from the subject
% Response 3 -  is the experimenter pressing the space bar
[oritxt] = read_logfile_visual(subjectname);

%% get relevant lines of logfile
% retrieve indices of logfile that logs whether subjects response is
% correct ('hit') or incorrect ('incorrect').
wordpresent = zeros(size(oritxt));
for m = 1:size(oritxt,1)
    check = regexp(oritxt{m},'QUESTION \d\d');  % check if text of interest exists
    if ~isempty(check)
        wordpresent(m) = 1;
    end 
end 

idxq  = find(wordpresent == 1);% index of logfile with "QUESTION... hit/incorrect" 
%idxr = idq + 1;               % index of responses
resp  = oritxt(idxq);          % lines in logfile that only contain "QUESTION..." 

% checks for a complete number of questions
% if <48 find out why e.g., subject was only presented 23 blocks / dsq
% crash...etc
if numel(resp) < 48
    warning('there are less than %d questions in the this logfile',numel(resp));

cor     = zeros(24,1);
incor   = zerps(24,1);
for m = 1:size(oritxt,1)
    checkcor = regexp(oritxt{m},'hit');
    checkincor = regexp(oritxt{m},'incorrect');
    if ~isempty(checkcor)
        checkcor(m) = 1;
    end
    if ~isempty(checkincor)
        checkincor(m) = 1;
    end
end
    


%% organise information
% number & percentage correct


% number & percentage incorrect



end 

