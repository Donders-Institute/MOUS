function [] = mous_CopyCoregMNIStructural()
%==========================================================================
% Author(s):    Julia, kmp
% Updated:      5/10/2012
% Date:         09/11/2006
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
clear all; clc; warning('off');

infoCopy;	% cf., infoPreproc.m
spm_defaults;
%--------------------------------------------------------------------------
% LOOP OVER SUBJECTS
%--------------------------------------------------------------------------

  %------------------------------------------------------------------------
for sbjnr=1:length(info.subjects);
    
%--------------------------------------------------------------------------
subject=char(info.subjects(sbjnr));
oldSubjectPath=fullfile('/home/language/annhul/MOUS/Processed',subject);
newSubjectPath=fullfile(info.rootdir,subject,'Structural');
sourcePath=fullfile(oldSubjectPath,'meg_anatomy');
copyPath=fullfile(newSubjectPath);
      if exist(copyPath,'dir')~=7; mkdir(copyPath); end
      fileNames=strcat(subject,'coregMNI.nii');
       for nr=1:size(fileNames,1);
      fileName=fileNames(nr,1:end);
      oldPath=fullfile(sourcePath,fileName);
      newPath=fullfile(copyPath,fileName);
      [status,message,messageid]=copyfile(oldPath,newPath);
            if ~status
            fprintf('Could not copy %s\n',newPath);
            fprintf(message);
            end
       end
        
        %[status,message,messageid]=copyfile(oldPath,newPath);
        %if ~status
      %fprintf('Could not copy %s\n',newPath);
      %fprintf(message);
        end
end
%--------------------------------------------------------------------------
% OUTPUT - DONE []
%End of copyJob------------------------------------------------------------
