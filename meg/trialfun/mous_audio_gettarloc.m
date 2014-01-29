function [tarloc] = mous_audio_gettarloc(subjectname)

% get filename of .wav file from logfile
% cross ref audio filename to excel (mous_tarloc)
% insert into trialinfo

% find entries with audiofilename, and remove all other entries
lgf = read_logfile_audio(subjectname);
tmp = zeros(numel(lgf),1);
for kk = 1:numel(lgf)
    if lgf(kk).value == 14;
        tmp(kk) = 1;
    end
end
lgfwav = lgf(find(tmp));

% load target locations from excel
% col 1 = soundfile name
% col 2 = target location for corresponding file 
xlstarloc = xlsread('/home/language/nielam/MOUS_Stimuli/mous_Tarloc.xls','','','basic'); 

% cross reference target location to audiofile
wavorder = zeros(size(lgfwav,2),3);
for k = 1:size(wavorder,1)
    wavorder(k,1) = str2num(lgfwav(k).type(1:3));
    % find corresponding sentence filename for each sequence
    % sent-seq pairs share same tarloc
    if wavorder(k,1) > 409
        wavorder(k,2) = wavorder(k,1)-500;
    else wavorder(k,2) = wavorder(k,1);
    end 
end 
% get tarloc for each trial (sent / seq)
tarloc = zeros(240,2);
tarloc(:,1) = wavorder(:,2);
for k = 1:size(wavorder,1)
    idx = find(wavorder(k,2) == xlstarloc(:,1));
    tarloc(k,2) = xlstarloc(idx,2);
end 
