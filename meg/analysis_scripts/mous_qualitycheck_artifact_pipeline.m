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

doArtCheck  = false;
doCompile   = true;

%% Artifact Quality Check: blinks, saccades, jumps and muscle artifacts
artFile = mous_db_getfilename(subjectname, 'meg_artifact_cfg'); 
if exist(artFile{1}, 'file')  % only run this script for participants whom don't yet have the pdf file generated 

    if doArtCheck
       % standard is to run a quality check for all artifact types

            artifactType = 'all';                    % CAN ALSO CALL INDIVIDUAL ARTIFACTS: 'blink' 'saccade','jump','muscle'
            %mous_qualitycheck_artifact(subjectname, artifactType);
            mous_qualitycheck_artifact(subjectname);
    end 

    %% File compilation: % make 1 pdf with all artifacts
    if doCompile
        allfiles    = cell(1,24);
        allfiles = mous_db_getfilename2(subjectname, 'meg_qualitycheck_{qc_art}');       

        pdfName = mous_db_getfilename(subjectname, 'meg_qualitycheck_{qc_artAll_task}');
        mous_makePDF([pdfName{1} 'b.pdf'], allfiles); 
    end 
end 