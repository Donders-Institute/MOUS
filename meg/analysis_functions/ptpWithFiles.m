function [present, numpres, absent, numabs] = ptpWithFiles(subject, type)

% used with mous_db_getfilename to determine which and how many
% participants do and do not have the file of interest
% e.g., [present,absent] = ptpWithFiles('all', 'meg_bfica_{comp}', '/home/language/jansch/public/mous');
% for files in JM's directory:
% type = 'jan_bfica_{_bfica_X}'
% where X = comp, source, sourcedata... etc, see mous_bfica_pipeline.m


[filename, st] = mous_db_getfilename(subject, type);


present = find(st);
numpres = numel(present);

absent  = find(st == 0);
numabs  = numel(absent);


% write function so that it's able to do it for more than one file type,
% and then spits it out into a matrix. one column for each file type.
% with first row = filename, 2nd row ... Xth row = list of participants
% In a separate matrix, 1st row = filename, 2nd row = how many people