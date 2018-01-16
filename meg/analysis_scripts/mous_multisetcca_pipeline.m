if ~exist('subjectname', 'var') && ~exist('subjectlist', 'var'),
  error('at least a subjectname or a list of subjects needs to be defined');
end

if ~exist('rootdir',     'var'), rootdir     = '/project/3011020.09/MEG/';  end
if ~exist('computedata', 'var'), computedata = 0;                           end

if computedata
  data = mous_erf_sentences(subjectname, 1);
  mous_db_putdata(subjectname, 'meg_multisetcca_data', 'data', rootdir);
end
