function [match] = mous_artifact_check(subjectname)

% MOUS_ARTIFACT_CHECK checks whether the artifact specification is derived
% from the same datafile as what is suggested by subjectname. This is
% inspired by the fact that for subject V1010 this was clearly not the
% case. The artifactcfg was obtained from V1001!
%
% Use as 
%   match = mous_artifact_check(subjectname), 
% where subjectname is a string or cell-array of strings and match is a
% boolean vector or matrix, indicating whether there was a match or not.

if iscell(subjectname)
  % call recursively
  match = false(numel(subjectname),4);
  for k = 1:numel(subjectname)
    match(k,:) = mous_artifact_check(subjectname{k});
  end
  return;
end

dat   = mous_db_getdata(subjectname, 'meg_artifact_cfg');
fn    = fieldnames(dat);
match = zeros(1,numel(fn));
for k = 1:numel(fn)
  sel        = strfind(dat.(fn{k}).datafile, 'V1');
  match(1,k) = strcmp(subjectname, dat.(fn{k}).datafile(sel(1):sel(1)+4)); 
end

