%% renaming scripts/files
for  k = 1:100
    
subjectname = ['V' int2str(k+1000)];    
list = dir(['/home/language/annhul/MOUS/meg/',subjectname,'/erf/', subjectname, 'rawERF_tarplusOne_02-1ds.mat']);
%list = cat(1, list, dir(['/home/language/annhul/MOUS/Processed/',subjectname,'/TFR/*raw*']));
%list = cat(1, list, dir(['/home/language/annhul/MOUS/Processed/',subjectname,'/other/*raw*']));

    for t= 1:length(list)

    %raw-preproc
    %tmp = findstr(list(t).name, 'raw');
    %fileType = list(t).name(tmp:end-4);
    %old = mous_db_getfilename(subjectname, ['meg_processed_{' fileType '}']);
    %new = mous_db_getfilename(subjectname, ['meg_processed_{preProc' fileType(4:end) '}']);

    %binks
    % tmp = findstr(list(t).name, 'arti');
    % fileType = list(t).name(tmp:end-4);
    % old = ['/home/language/annhul/MOUS/meg/',subjectname,'/other/', list(t).name];
    % new = mous_db_getfilename(subjectname, ['meg_' fileType ]);

        old = ['/home/language/annhul/MOUS/meg/',subjectname,'/erf/', list(t).name];
        new = ['/home/language/annhul/MOUS/meg/',subjectname,'/erf/', subjectname, '_', list(t).name(6:end)];

        str =['mv ' old ' ' new];
        system(str);
    end

clear list

end

%% deleting files
% need to specify: foldername & filename
for k = 1:100
    subjectname = ['V' int2str(k+1000)];
    list = dir(['/home/language/annhul/MOUS/meg/',subjectname,'/mne/', subjectname, '_mne_0-05ms_singletrials.mat']);
   
    for t = 1:length(list)
        delfile = ['/home/language/annhul/MOUS/meg/',subjectname,'/mne/', list(t).name];
        str = ['rm ' delfile];
        system(str);
    end 
end

%% rename and move files
if doHeadCheck
    cfg2 = [];
    cfg2.dataset = filename{1};
    [info, timelock, freq, summary, heapos] = mous_qualitycheck(cfg2);  % One .mat file, .pdf and .png files produced from .mat file

    % from info derive filename format: yyyymmdd_hhss e.g., 20120322_1303
    [path, name, ext] = fileparts(filename{1});
    filedate = name(end-10:end-3);
    savedFilename = [filedate '_' info.starttime(1:2) info.starttime(4:5)];

    % list all .mat, .pdf and .png files under savedFilename
    moveList = dir([savedFilename '*']); % * for orig files, and pt2, 3..etc
    numFiles = size(moveList,1);

    % rename and move files:
    for j = 1:numFiles
        old = ['/home/language/nielam/', moveList(j).name];  % if qsub, where  will file be generated, what is the path?
        new = ['/home/language/annhul/MOUS/meg/', subjectname,'/qualitycheck/', name(1:13), moveList(j).name];  % need to specify file type!
        str = ['mv ' old ' ' new];
        system(str);
    end 
end 
