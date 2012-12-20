function mous_ptpWithFiles(subject, structnames, exportname)

% This function gets information from mous_db_getfilename, and then calculates which and how many
% participants do and do not have the file of interest

% for files in JM's directory: % type = 'jan_bfica_{_bfica_X}'
% where X = comp, source, sourcedata... etc, see mous_bfica_pipeline.m

% by default subject = 'all'
% structnames should be a cell array with list of filenames to be checked
% exportname = name that the array of structs will be saved as 

% NL: 17 Dec 2012

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIXME: Not sure how to use varagin but should be implemented
% if numel(varargin)<1
%     rootdir = '/home/language/nielam/MOUS_AnalysisNotes';
% else
%     warning('cannot proceed, please specify root directory')
% end 


%% input arguments
subject = 'all';
rootdir = '/home/language/nielam/MOUS_AnalysisNotes/';
exportname = 'Bfica_Alloutputs';

% name each struct in the field 'filename'
% FIXME: could probably use 'dir()' for this to be more efficient
structnames = {'bfica_comp','bfica_freq','bfica_freq5','bfica_freq70','bfica_ica','bfica_source'...
               'bfica_source','bfica_source5_500','bfica_source_70','bfica_source475', ...
               'bfica_source_525','bfica_sourcedata','bfica_sourcedata5_500','bfica_sourcedata70', ...
               'bfica_sourcedata475','bfica_sourcedata525','bfica_sourcedataavgword', ...
               'bfica_sourcedatadss','bfica_sourcedatasentseq','bfica_sourcedatasentseq70', ...
               'bfica_sourcedatawordsentpar'};

structnames = 
 
%% actual calculation %%%%%%%%%%%%%%%%%
% create fields in advance
for q = 1:numel(structnames)     
   % numFiles(q).filename = structnames{q};
    numFiles(q) = struct('filename',structnames{q},'preslist',[],...
                  'numpres',[],'abslist',[],...
                  'numabs', []);
end 

for q = 1:numel(structnames)    
    % FIXME: should have the "jan_bfica_" part be an argument from user???
    type = strcat('jan_bfica_{_',structnames(q),'}');% adapt 'type' from structnames to be understood by mous_db_getfilename
    
    [filename, st] = mous_db_getfilename(subject, type{1});
    numFiles(q).preslist    = find(st);
    numFiles(q).numpres     = numel(numFiles(q).preslist);

    numFiles(q).abslist     = find(st == 0);
    numFiles(q).numabs      = numel(numFiles(q).abslist);
end 

when = tokenize(date,'-');
now  = strcat(when{1:3});
save(strcat('numPtp_',exportname,'_',now),'numFiles'); %save(filename, variable) % both need to be str arguments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Notes:
% empty array of structures
% numFiles = struct('filename',mat2cell(zeros(5,1),ones(5,1)),'preslist',mat2cell(zeros(5,1),ones(5,1)),...
%                   'numpres',mat2cell(zeros(5,1),ones(5,1)),'abslist',mat2cell(zeros(5,1),ones(5,1)),...
%                   'numabs', mat2cell(zeros(5,1),ones(5,1)));

