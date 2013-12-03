function mous_qualitycheck_artifact_pipeline(subjectname)  
% comment out line above when running through qsub since
% mous_execute_pipeline only takes scripts, not functions.
% qsub calls mous_execute_pipeline calls scripts calls 1 or more functions which do the actual calculations

% THIS PIPELINE CHECKS THROUGH THE ARTIFACTS DETECTED BY THE RAs. 
% doArtCheck PROVIDES AN OVERVIEW OF EACH TYPE OF ARTIFACT DETECTED WITHIN

% EACH TRIAL SUCH THAT THE CHECKER CAN SEE WHETHER TOO MANY / LITTLE
% ARTIFACTS HAVE BEEN DETECTED.  

% doCompile COMBINES ALL THE INDIVIDUAL FIGURES CREATED FROM doArtCheck
% INTO ONE PDF ALLOWING FOR EASIER PERUSAL OF THE DETECTED ARTIFACTS

% NL - 27.11.2012.  edit: 28.11.2013

%% Artifact Quality Check: blinks, saccades, jumps and muscle artifacts

whichart     = [1 1 1 1];  % which artifacts to detect (blink sacc jump musc]
datafilename = mous_db_getfilename(subjectname,'meg_raw_task');

% determine number of datasets
% options: '_pt1' '_pt2' 'meg_artifact_cfg';
if numel(datafilename) > 1
    for k = 1:numel(datafilename)
        fileinart   = ['meg_artifact_cfg_pt',num2str(k)];
        artFile     = mous_db_getfilename(subjectname,fileinart);
        savesuff    = fileinart(end-3:end);    % suffix for saving PDF: '_pt1' or '_pt2';
        fileindat   = datafilename{k}(end-3);  % which RAW .ds file
        
        epsin   = ['meg_qualitycheck_{_qc_art*pt',num2str(k),'*.eps}'];   % orig:  {_qc_art*.eps};
        pdfin   = ['meg_qualitycheck_{_qc_artAll_task_pt',num2str(k),'}'];
        tmp     = date; 
        tnp     = tokenize(tmp,'-');
        pdfdate = [tnp{1} tnp{2} tnp{3} '.pdf'];

        
        if exist(artFile{1}, 'file')  % only run this script for participants whom have artifacts detected 
            %                                      artifacts raw data  
            mous_qualitycheck_artifact(subjectname,fileinart,fileindat,whichart,savesuff);
       
            %% File compilation: % make 1 pdf with all artifacts
            % If doing pdf for 2nd round use <allfiles(2:end)>
            % If 3rd round: <allfiles(3:end)> and so on...

            filebase    = mous_db_getfilename(subjectname, epsin);           
            d           = dir([filebase{1}, '*']);
            [p,fn,e]    = fileparts(filebase{1});
            for q = 1:size(d,1)
                allfiles{q} = [p,'/',d(q).name];  % don't preassign space because not all ptps have 240 trials
            end 
            pdfName     = mous_db_getfilename(subjectname,pdfin);
            mous_makePDF([pdfName{1},'_',pdfdate], allfiles); 
        end 
    end 
else
    fileinart   = 'meg_artifact_cfg';  
    artFile     = mous_db_getfilename(subjectname,fileinart);   
    savesuff    = '';
    fileindat   = [];
    
    epsin   = 'meg_qualitycheck_{_qc_art*.eps}';   % orig:  {_qc_art*.eps};
    pdfin   =  'meg_qualitycheck_{_qc_artAll_task}';
    tmp     = date;     
    tnp     = tokenize(tmp,'-');
    pdfdate = [tnp{1} tnp{2} tnp{3} '.pdf'];


    
    if exist(artFile{1}, 'file')  % only run this script for participants whom have artifacts detected 
        %                                      artifacts raw data  
        mous_qualitycheck_artifact(subjectname,fileinart,fileindat,whichart,savesuff);
       
        %File compilation: % make 1 pdf with all artifacts
        % If doing pdf for 2nd round use <allfiles(2:end)>
        % If 3rd round: <allfiles(3:end)> and so on...

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

% eps file parameter
% whichart = [1 1 1 1]; % corresponds to: blink sacc jump musc
% savesuff = '_pt1';        % options: ''  , '_pt1', '_pt2'
% fileindat = [];       % options: '2', '3', '4', [] to refer to RAW .ds file

% pdf parameters
% epsin   = 'meg_qualitycheck_{_qc_art*_pt1*.eps}';
% pdfin   =  'meg_qualitycheck_{_qc_artAll_task_pt1_}';
% epsin   = 'meg_qualitycheck_{_qc_art*.eps}';   % orig:  {_qc_art*.eps};
% pdfin   =  'meg_qualitycheck_{_qc_artAll_task}';
% pdfdate = '26Nov2013.pdf';

% if exist(artFile{1}, 'file')  % only run this script for participants whom have artifacts detected 
%     %                                      artifacts raw data  
%     mous_qualitycheck_artifact(subjectname,fileinart,fileindat,whichart,savesuff);
% end 
% filebase    = mous_db_getfilename(subjectname, epsin);           
% d           = dir([filebase{1}, '*']);
% [p,fn,e]    = fileparts(filebase{1});
% for q = 1:size(d,1)
%     allfiles{q} = [p,'/',d(q).name];  % don't preassign space because not all ptps have 240 trials
% end 
% pdfName     = mous_db_getfilename(subjectname,pdfin);
% mous_makePDF([pdfName{1},pdfdate], allfiles); 
%     
 
