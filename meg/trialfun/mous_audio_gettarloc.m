function [tarloc] = mous_audio_gettarloc(subjectname)

% get filename of .wav file from logfile
% cross ref audio filename to excel (mous_tarloc)
% insert into trialinfo

% find entries with audiofilename, and remove all other entries
lgf = read_logfile_audio(subjectname);

% load target locations from excel
  % col 1 = soundfile name
  % col 2 = target location for corresponding file 
  xlstarloc = xlsread('/home/language/nielam/MOUS_Stimuli/mous_Tarloc.xls','','','basic'); 

for cnt = 1:numel(lgf)
  tmp = zeros(numel(lgf{cnt}),1);
  for kk = 1:numel(lgf{cnt})
      if lgf{cnt}(kk).value == 14;
          tmp(kk) = 1;
      end
  end
  lgfwav{cnt} = lgf{cnt}(find(tmp));

  % get audiofilename of each target (trial)
  wavorder{cnt} = zeros(size(lgfwav{cnt},2),3);
  for k = 1:size(wavorder{cnt},1)
      wavorder{cnt}(k,1) = str2num(lgfwav{cnt}(k).type(1:3));
      % find corresponding sentence filename for each sequence
      % sent-seq pairs share same tarloc
      if wavorder{cnt}(k,1) > 409
          wavorder{cnt}(k,2) = wavorder{cnt}(k,1)-500;
      else wavorder{cnt}(k,2) = wavorder{cnt}(k,1);
      end 
  end 
end

% cross reference: get target location of audiofile
if strcmp(subjectname,'A2002') % exception case: A2002 does not have first 20 trials.
    tarloc = zeros(220,2);

elseif numel(lgf) == 1 && ~strcmp(subjectname,'A2002')
  tarloc = zeros(size(wavorder{1},1),2);
      
elseif numel(lgf) > 1  % e.g., A2036 has 2 logfiles
  for mm = 1:numel(lgf)
    if mm == 1
      tmp = size(wavorder{mm},1);
      tmp2 = wavorder{mm};
    elseif mm > 1
      tmp = tmp + size(wavorder{mm},1);
      tmp2 = [tmp2; wavorder{mm}];
    end
  tarloc = zeros(tmp,2);
  wavorder = tmp2;
  end
end

tarloc(:,1) = wavorder(:,2);
for k = 1:size(wavorder,1)
    idx = find(wavorder(k,2) == xlstarloc(:,1));
    tarloc(k,2) = xlstarloc(idx,2);
end 
