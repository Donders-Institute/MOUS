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
fileinart = 'meg_artifact_cfg';  % options: '_pt1' '_pt2' 'meg_artifact_cfg';
artFile = mous_db_getfilename(subjectname,fileinart);   

% eps file parameter
whichart = [1 1 1 1]; % corresponds to: blink sacc jump musc
savesuff = '';        % ''  
fileindat = [];       % give specific raw data file: 02.ds or 03.ds, or []

% pdf parameters
epsin   = 'meg_qualitycheck_{_qc_art*.eps}';
pdfin   =  'meg_qualitycheck_{_qc_artAll_task}';
pdfdate = '30Sept2013.pdf';

if exist(artFile{1}, 'file')  % only run this script for participants whom have artifacts detected 
    if doArtCheck
         %                                      artifacts raw data  
         mous_qualitycheck_artifact(subjectname,fileinart,fileindat,whichart,savesuff);
    end 
    %% File compilation: % make 1 pdf with all artifacts
    % If doing pdf for 2nd round use <allfiles(2:end)>
    % If 3rd round: <allfiles(3:end)> and so on...
    if doCompile
        filebase    = mous_db_getfilename(subjectname, epsin);           
        d           = dir([filebase{1}, '*']);
        [p,fn,e]    = fileparts(filebase{1});
        for q = 1:size(d,1)
            allfiles{q} = [p,'/',d(q).name];  % don't preassign space because not all ptps have 240 trials
        end 
        pdfName     = mous_db_getfilename(subjectname,pdfin);
        mous_makePDF([pdfName{1},pdfdate], allfiles); 
    end 
end 
