function [newtext] = read_logfile_auditory_linebyline(subjectname)

% this function is created specifically for mous_auditory_logfileanswers.
% nielam 2013
% to extract all information from logfiles see read_logfile_audio.m
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