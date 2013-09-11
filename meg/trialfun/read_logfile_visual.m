function [newtext] = read_logfile_visual(subjectname)

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
    if isempty(idx)
       subjectnameL = lower(subjectname);  % for some subjects, the logfile has 'v1XXX' instead of 'V1XXX'
       idx = strfind(alltxt(:)', subjectnameL);
    end 
    add = idx(end)+80;  
    idx = [idx add];
    alltxt = alltxt';
    newtext = cell(numel(idx)-1,1);
    for k = 1:numel(idx)-1
        newtext{k} = alltxt(idx(k):idx(k+1)-1);  % easier to find relevant entry lines in txtfile
    end