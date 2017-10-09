% script to move the audio logfiles to the subject specific ses-meg folder.

subj = mous_db_getfilename('allA','subjectname');
f    = mous_db_getfilename(subj,  'meg_raw_task');
for k = 1:numel(f)
  [p,fx,e] = fileparts(f{k});
  f{k} = p;
end
f = unique(f);

f2 = mous_db_getfilename(subj, 'meg_raw_log');

% A2036 has 2 logfiles...
f = cat(1,f(1:30),f(30:end));

for k = 1:numel(f)
  file1 = f2{k};
  [px,fx,ex] = fileparts(file1);
  file2 = fullfile(f{k}, strrep([fx ex], 'A2','sub-2'));
  str = sprintf('rsync -rvpu %s %s', file1, file2);
  system(str);
end
