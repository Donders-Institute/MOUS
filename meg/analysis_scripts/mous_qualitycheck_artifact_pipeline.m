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
artFile = mous_db_getfilename(subjectname, 'meg_artifact_cfg'); 
if exist(artFile{1}, 'file')  % only run this script for participants whom have artifacts detected 
    if doArtCheck
         mous_qualitycheck_artifact(subjectname);
    end 
    %% File compilation: % make 1 pdf with all artifacts
    if doCompile
        allfiles    = cell(1,24);
        filebase    = mous_db_getfilename(subjectname, 'meg_qualitycheck_{_qc_art}');           
        d           = dir([filebase{1}, '*']);
        [p,fn,e]    = fileparts(filebase{1});
        for q = 1:size(d,1)
            allfiles{q} = [p,'/',d(q).name];
        end 
        pdfName     = mous_db_getfilename(subjectname, 'meg_qualitycheck_{qc_artAll_task}');
        mous_makePDF([pdfName{1}, '3','.pdf'], allfiles); 
    end 
end 


