%% get filenames
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
    
end

%Create list of auditory subjects and which scenario they were presented with
sce_group = cell(6,1);
for k = 1:Nsubj
    path = strcat('/project/3011020.09/MEG/',subjA{k},'/RAW/');
    logfile = dir(strcat(path,'*.log'));
    if length(logfile) > 1
        for i = 1:length(logfile)
            scenario = str2num(logfile(i).name(7));
            indx = length(sce_group{scenario});
            sce_group{scenario}{indx+1}= subjA{k};
        end
    else
        scenario = str2num(logfile.name(7));
        indx = length(sce_group{scenario});
        sce_group{scenario}{indx+1}= subjA{k};
    end
end
