% script to move the logfiles to the subject specific ses-meg folder.

% % audio subjects
% subj = mous_db_getfilename('allA','subjectname');
% f    = mous_db_getfilename(subj,  'meg_raw_task');
% for k = 1:numel(f)
%   [p,fx,e] = fileparts(f{k});
%   f{k} = p;
% end
% f = unique(f);
% 
% f2 = mous_db_getfilename(subj, 'meg_raw_log');
% 
% % A2036 has 2 logfiles...
% f = cat(1,f(1:30),f(30:end));
% 
% for k = 1:numel(f)
%   file1 = f2{k};
%   [px,fx,ex] = fileparts(file1);
%   file2 = fullfile(f{k}, strrep([fx ex], 'A2','sub-2'));
%   str = sprintf('rsync -rvpu %s %s', file1, file2);
%   system(str);
% end

% % visual subjects
% subj = mous_db_getfilename('allV','subjectname');
% f    = mous_db_getfilename(subj,  'meg_raw_task');
% for k = 1:numel(f)
%   [p,fx,e] = fileparts(f{k});
%   f{k} = p;
% end
% f = unique(f);
% 
% f2 = mous_db_getfilename(subj, 'meg_raw_log');
% 
% % V1017 and v1006 have 2 logfiles...
% f = cat(1,f(1:6),f(6:16),f(16:end));
% 
% for k = 1:numel(f)
%   file1 = f2{k};
%   [px,fx,ex] = fileparts(file1);
%   file2 = fullfile(f{k}, strrep([fx ex], 'V1','sub-1'));
%   str = sprintf('rsync -rvpu %s %s', file1, file2);
%   system(str);
% end

% subj = mous_db_getfilename('allAV','subjectname');
% f    = mous_db_getfilename(subj,  'meg_raw_pos');
% 
% for k = 1:numel(f)
%   file1 = f{k};
%   file2 = fullfile('/project/3011020.09/raw/', subj{k}, [subj{k},'.pos']);
%   str = sprintf('rsync -rvpu %s %s', file1, file2);
%   system(str);
% end

subj = mous_db_getfilename('allAV','subjectname');
f    = mous_db_getfilename(subj,  'meg_raw_fidpic');

for k = 1:numel(f)
  file1 = f{k};
  [p,fx,e] = fileparts(file1);
  fx = strrep(strrep(fx, 'A2','sub-2'),'V1','sub-1');
  
  sub_id = file1(25:29);
  sub_id = strrep(strrep(sub_id,'V1','sub-1'),'A2','sub-2');
    
  file2 = fullfile('/project/3011020.09/raw/', sub_id, [fx, e]);
  str = sprintf('rsync -rvpu %s %s', file1, file2);
  system(str);
end
