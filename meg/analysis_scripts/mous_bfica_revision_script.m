% this script is a placeholder to be able to run the requested revision
% analysis for the oscillation paper

if ~exist('subjectname', 'var'), error('subjectname is requested'); end
if ~exist('frequency', 'var'), error('frequency is requested'); end
if ~exist('suff', 'var'), error('suff is requested'); end


output = mous_bfica_revision(subjectname,suff,frequency);
mous_db_putdata(subjectname, ['meg_bfica_revision_erfanalysis',num2str(frequency),'Hz'], 'output');
