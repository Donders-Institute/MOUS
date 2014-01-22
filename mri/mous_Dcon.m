function [] = kmpDcon()
%==========================================================================
% Author(s):    kmp
% Update:       19/10/2008
% Date:         19/09/2008
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
clc; cwd=pwd; warning('off');
% addpath('C:\spm5');
spm_defaults;
infoDcon;   %cf., infoDcon.m
%--------------------------------------------------------------------------
jobType='none';
if strcmp(info.todo,'Dcon')
  copyType=info.todo;
else
  fprintf('-------------------------------------------------\n');
  fprintf('Note: no Dcon job\n');
  if ~isempty(info.todo)
    str=strcat('/',info.todo); str=strcat(str{:});
    fprintf('info.todo reads:  %s\n',str);
  else
    fprintf('info.todo is empty');
  end
  fprintf('Returning control');
  return
end
jobType=copyType;
%--------------------------------------------------------------------------
outDir=info.outdir;
if exist(outDir,'dir')~=6; mkdir(outDir); end
%--------------------------------------------------------------------------
% LOOP OVER SUBJECTS
% LOAD TEMPLATE BATCH, EXPAND TO FULL JOB STRUCTURE, AND SAVE
%--------------------------------------------------------------------------
fprintf('-------------------------------------------------\n');
fprintf('Expanding jobs\n');
nrsbj=size(info.subjects,1);
for sbjnr=1:nrsbj
  subject=info.subjects{sbjnr,1};
dcmDir1=fullfile(info.dcmdata,subject);
if exist(outDir,'dir')~=7; mkdir(outDir); end
sbjDir=fullfile(outDir,subject);
if exist(sbjDir,'dir')~=7; mkdir(sbjDir); end
fprintf('-------------------------------------------------\n');
fprintf('Expanding job: %s %s\n',subject);
%----------------------------------------------------------------------
% APPLY SUBFUNCTION xpdjob5
%----------------------------------------------------------------------
for k=1:length(info.sf)
  if strcmp(info.sf{k},'s')
    clear('jobs');
    if strcmp(jobType,'Dcon');
        
      load(info.jobDcon);
    else
      fprintf('-------------------------------------------------\n');
      fprintf('Note: jobType = %s\n',jobType);
      fprintf('Returning control\n');
      return
    end
    try
      jobs=xpdjob5('s',jobs,info,subject);
      jobname=strcat(subject,'_s',info.jobname);
      jobDir=fullfile(sbjDir,info.strdir);
      if exist(jobDir,'dir')~=7; mkdir(jobDir); end
      dcmDir=fullfile(dcmDir1,info.strdir);
      save(fullfile(dcmDir,jobname),'jobs'); % here lies the problem I guess 
      fprintf('Saved: %s\n',fullfile(dcmDir,jobname));
    catch
      fprintf('Could not expand job for %s/%s\n', ...
        subject,info.strdir); fprintf(lasterr); fprintf('\n');
      fprintf('Moving on to next subject/session\n');
    end
  elseif strcmp(info.sf{k},'f')
    nrses=info.subjects{sbjnr,2};
    for sesnr=1:nrses
          clear('jobs');
      if strcmp(jobType,'Dcon');
        load(info.jobDcon);
      else
        fprintf('-------------------------------------------------\n');
        fprintf('Note: jobType = %s\n',jobType);
        fprintf('Returning control\n');
        return
      end
      try
        jobs=xpdjob5('f',jobs,info,subject);
        jobname=strcat(subject,'_f',info.jobname);
        jobDir=fullfile(sbjDir,info.fctdir);
        if exist(jobDir,'dir')~=7; mkdir(jobDir); end
        dcmDir=fullfile(dcmDir1,info.fctdir);
        save(fullfile(dcmDir,jobname),'jobs');
        fprintf('Saved: %s\n',fullfile(dcmDir,jobname));
      catch
        fprintf('Could not expand job for %s/session %d\n', ...
          subject,sesnr); fprintf(lasterr); fprintf('\n');
        fprintf('Moving on to next subject/session\n');
      end
    end
  end
    
  end
end
fprintf('-------------------------------------------------\n');
fprintf('Done: Expanding\n\n\n');
%--------------------------------------------------------------------------
% LOOP OVER SUBJECTS/SESSIONS, LOAD JOB STRUCTURE, AND RUN THE JOB
%--------------------------------------------------------------------------
fprintf('Running jobs\n');
for sbjnr=1:nrsbj
  
 
    subject=info.subjects{sbjnr,1};
    sbjDir=fullfile(outDir,subject);
    dcmDir1=fullfile(info.dcmdata,subject);
    for k=1:length(info.sf)
      if strcmp(info.sf{k},'s')
        jobDir=fullfile(sbjDir,info.strdir);
        dcmDir=fullfile(dcmDir1,info.strdir);
        clear('jobs');
        jobname=strcat(subject,'_s',info.jobname);
        load(fullfile(dcmDir,jobname));
        fprintf('-------------------------------------------------\n');
        fprintf('Running: %s\n',fullfile(dcmDir,jobname));
        spm_jobman('run',jobs);
        if strcmp('Dcon',copyType)
          fprintf('--------------------------\n');
          fprintf('Renaming files: %s, %s, %s\n', ...
           subject,info.strdir);
          fprintf('--------------------------\n');
          copyJob('s',copyType,jobDir,info,subject);
        end
      elseif strcmp(info.sf{k},'f')
        nrses=info.subjects{sbjnr,2};
        for sesnr=1:nrses
          clear('jobs');
          jobname=strcat(subject,'_f',info.jobname);
          jobDir=fullfile(sbjDir,info.fctdir);
          dcmDir=fullfile(dcmDir1,info.fctdir);
          load(fullfile(dcmDir,jobname));
          fprintf('-------------------------------------------------\n');
          fprintf('Running: %s\n',fullfile(dcmDir,jobname));
          spm_jobman('run',jobs);
          if strcmp('Dcon',copyType)
            fprintf('--------------------------\n');
            fprintf('Renaming files: %s, %s, %s\n',subject, 'Functional');
            fprintf('--------------------------\n');
            copyJob('f',copyType,jobDir,info,subject);
          end
        end
     
    end
  end
end
fprintf('-------------------------------------------------\n');
cd(cwd);
fprintf('Done\n');
%End of kmpDcon------------------------------------------------------------


%==========================================================================
% SUBFUNCTION SECTION
%==========================================================================
function xpd_jobs = xpdjob5(flax,jobs,info,subject)
%==========================================================================
% Author(s):  kmp
% Update:     19/09/2008, 19/10/2008
% Date:       29/01/2008
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
dcmPath=info.dcmdata;
if strcmp(flax,'s')
  sesPath=fullfile(dcmPath,subject,info.strdir);
  outDir=fullfile(info.dcmdata,subject,info.strdir);
elseif strcmp(flax,'f')
  sesPath=fullfile(dcmPath,subject,info.fctdir);
  outDir=fullfile(info.dcmdata,subject,info.fctdir);
end
dcmImages=cellstr(spm_select('List',sesPath,info.dcmid));
filePaths=imagePaths(sesPath,dcmImages);
jobs{1}.util{1}.dicom.data=filePaths;
jobs{1}.util{1}.dicom.outdir={outDir};
xpd_jobs=jobs;
%End of xpdjob5------------------------------------------------------------


%==========================================================================
function [filePaths] = imagePaths(sesPath,dcmImages)
%==========================================================================
% Author(s):	kmp
% Update:     19/09/2008, 19/10/2008
% Date:       29/01/2008
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
filePaths=cell(length(dcmImages),1);
for nr=1:length(dcmImages);
  filePaths{nr}=strcat(sesPath,filesep,dcmImages{nr});
end
%End of imagePaths---------------------------------------------------------


%==========================================================================
function [] = copyJob(flax,copyType,copyPath,info,subject)
%==========================================================================
% Author(s):	kmp
% Update:     19/10/2008
% Date:       19/09/2008
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
infoDcon
if strcmp(flax,'s')
  sourcePath=fullfile(info.dcmdata,subject,info.strdir);
  fileNames=spm_select('List',sourcePath,info.strid);
  %fileNames=spm_select('List',sourcePath,info.dcmid);
  for k=1:min(length(fileNames(:,1)),11)
    fprintf(fileNames(k,:));
    fprintf('\n');
  end
  fprintf('...\n');
  extensions=info.extensions;
  for nr=1:size(fileNames,1);
    oldName=fileNames(nr,1:end-3);
    newName=strcat('str-',subject,'-');
    if nr<10
      filenr=strcat('00',num2str(nr));
    elseif nr<100
      filenr=strcat('0',num2str(nr));
    else
      filenr=num2str(nr);
    end
    newName=strcat(newName,filenr,'.');
    for k=1:length(extensions)
      old=strcat(oldName,extensions{k});
      new=strcat(newName,extensions{k});
      oldPath=fullfile(sourcePath,old);
      newPath=fullfile(copyPath,new);
      [status,message,messageid]=copyfile(oldPath,newPath);
      delete(oldPath);
      if ~status
        fprintf('Could not copy %s\n',newPath);
      end
    end
  end
elseif strcmp(flax,'f')
  sourcePath=fullfile(info.dcmdata,subject,info.fctdir);
  fileNames=spm_select('List',sourcePath,info.fctid);
  for k=1:min(length(fileNames(:,1)),11)
    fprintf(fileNames(k,:));
    fprintf('\n');
  end
  fprintf('...\n');
  extensions=info.extensions;
  for nr=1:size(fileNames,1);
    oldName=fileNames(nr,1:end-3);
    newName=strcat('fct-',subject,'-');
    if nr<10
      filenr=strcat('00',num2str(nr));
    elseif nr<100
      filenr=strcat('0',num2str(nr));
    else
      filenr=num2str(nr);
    end
    newName=strcat(newName,filenr,'.');
    for k=1:length(extensions)
      old=strcat(oldName,extensions{k});
      new=strcat(newName,extensions{k});
      oldPath=fullfile(sourcePath,old);
      newPath=fullfile(copyPath,new);
      [status,message,messageid]=copyfile(oldPath,newPath);
      delete(oldPath);
      if ~status
        fprintf('Could not copy %s\n',newPath);
      end
    end
  end
end
%End of copyJob------------------------------------------------------------



