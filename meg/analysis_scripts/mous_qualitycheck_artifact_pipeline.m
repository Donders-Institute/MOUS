%% mous_qualitycheck_artifact_pipeline(subjectname)  
% comment out line above when running through qsub since
% mous_execute_pipeline only takes scripts, not functions.
% qsub calls mous_execute_pipeline calls scripts calls 1 or more functions which do the actual calculations

% THIS PIPELINE CHECKS THROUGH THE ARTIFACTS DETECTED BY THE RAs. 
% doArtCheck PROVIDES AN OVERVIEW OF EACH TYPE OF ARTIFACT DETECTED WITHIN

% EACH TRIAL SUCH THAT THE CHECKER CAN SEE WHETHER TOO MANY / LITTLE
% ARTIFACTS HAVE BEEN DETECTED.  

% doCompile COMBINES ALL THE INDIVIDUAL FIGURES CREATED FROM doArtCheck
% INTO ONE PDF ALLOWING FOR EASIER PERUSAL OF THE DETECTED ARTIFACTS

% NL - 27.11.2012.

doArtCheck  = true;
doCompile   = true;

%% Artifact Quality Check: blinks, saccades, jumps and muscle artifacts

if doArtCheck
   % standard is to run a quality check for all artifact types
    artifactType = 'all';                    % CAN ALSO CALL INDIVIDUAL ARTIFACTS: 'blink' 'saccade','jump','muscle'
    %mous_qualitycheck_artifact(subjectname, artifactType);
    mous_qualitycheck_artifact(subjectname);
end 

%% File compilation: % make 1 pdf with all artifacts
if doCompile
    % allfiles    = cell(1,24);
    allfiles = mous_db_getfilename2(subjectname, 'meg_qualitycheck_{qc_art}');       
  
    pdfName = mous_db_getfilename(subjectname, 'meg_qualitycheck_{qc_artAll_task}');
    mous_makePDF([pdfName{1} '.pdf'], allfiles); 
end 


%% make 1 pdf for each type of artifact - useles...
%     % name of combined file
%         artifacts = {'blink','sacc','jump','musc'};
%     
%     allfiles    = cell(1,4);
%     for j = 1:size(allfiles,2)
%         allfiles{j}   = mous_db_getfilename(subjectname, ['meg_qualitycheck_{qc_art', artifacts{j}, '_task}']); 
%     end
%     
%     %% make 4 separate pdfs
%        
%     % create empty lists
%     listBlink   = cell(1,4);    listSacc    = cell(1,4);
%     listJump    = cell(1,8);    listMusc    = cell(1,8);
%     
%     % fill lists with filenames
%     for i = 1:4 % this will not work if there are less than 4 figures, potentially non-complete data sets 
%         listBlink{i} = [allfiles{1} i];
%         listSacc{i}  = [allfiles{2} i];
%     end  
%     
%     for i = 1:8
%         listJump{i} = [allfiles{3} i];
%         listMusc{i} = [allfiles{4} i];
%     end 
%     allLists = cell(1,4);
%     
%     % combine into one pdf for each type of artifact 
%     for m = 1:4
%         mous_makePDF(allfiles{m}, allLists{m});
%     end
%     


%% MOUS_QUALITYCHECK_PIPELINE calls a series of functions to calculate and store
% pdfs/pngs summarizing the quality of the data. This includes head
% movement, eye movements, squid jumps and muscle artifacts
% NL 9 NOV 2012

% doGeneralCheck = true;
% doArtCheck  = false; 

% %% Head Motion Check
% if doGeneralCheck
%     fileType = cell(1,2); 
%     fileType{1} = 'meg_ds_rest'; fileType{2} ='meg_ds_task';
%     fileExport = cell(1,2);
%     fileExport{1} = 'meg_qualitycheck_{qc_general_raw}'; fileExport{2} = 'meg_qualitycheck_{qc_general_task}';
%         
%     for k = 1:2
%         filename = mous_db_getfilename(subjectname, fileType{k});
%         exportname = mous_db_getfilename(subjectname, fileExport{k});
%         cfg = [];
%         cfg.dataset = filename{1};
%         cfg.exportname = exportname{1};
%         mous_qualitycheck_general(cfg);
%     end 
% end 
% 

