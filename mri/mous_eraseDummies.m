function [] = eraseDummies()

%--------------------------------------------------------------------------
% ERASE DUMMY SCANS FROM PREPROC SUBJECT FOLDERS BEFORE PREPROCESSING
%--------------------------------------------------------------------------

cd('/home/language/juludd/MOUS/preprocdata/');
infoPreproc;

    for sbjnr=1:length(info.subjects)
          cd(char(strcat(info.rootdir,filesep,info.subjects(sbjnr), ...
              filesep,info.fctdir)));
 
          delete(char(strcat('fct-',info.subjects(sbjnr),'-001.nii')))
          delete(char(strcat('fct-',info.subjects(sbjnr),'-002.nii')))
          delete(char(strcat('fct-',info.subjects(sbjnr),'-003.nii')))
   
          delete(char(strcat('ufct-',info.subjects(sbjnr),'-001.nii')))
          delete(char(strcat('ufct-',info.subjects(sbjnr),'-002.nii')))
          delete(char(strcat('ufct-',info.subjects(sbjnr),'-003.nii')))
          
       
          
    end

end