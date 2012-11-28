function mous_qualitycheck_pipeline(subjectname)

fileType = cell(1,2); 
fileType{1} = 'meg_ds_rest'; fileType{2} ='meg_ds_task';
fileExport = cell(1,2);
fileExport{1} = 'meg_qualitycheck_{qc_general_raw}'; fileExport{2} = 'meg_qualitycheck_{qc_general_task}';
        
for k = 1:2
    filename = mous_db_getfilename(subjectname, fileType{k});
    exportname = mous_db_getfilename(subjectname, fileExport{k});
    cfg = [];
    cfg.dataset = filename{1};
    cfg.exportname = exportname{1};
    mous_qualitycheck_general(cfg);
end 

% MOUS_QUALITYCHECK_PIPELINE calls a series of functions to calculate and store
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
% 
% %% Artifact Quality Check: blinks, saccades, jumps and muscle artifacts
% 
% if doArtCheck
%     all = {'blink','saccade','jump','muscle'};  % standard is to run a quality check for all artifact types
%     artifactType = all;                         % call individual artifacts: 'blink' 'saccade','jump','muscle'
%     if strcmp(artifactType, 'all') > 0  
%         for k = 1:4
%             mous_qualitycheck_artifact(subjectname, all{k})
%         end
%     else
%         mous_qualitycheck_artifact(subjectname, artifactType)
%     end   
% end 
% 

