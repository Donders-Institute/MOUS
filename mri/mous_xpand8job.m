function []=xpand8job()


%%%%UNDER CONSTRUCTION%%%%%%%%%%%%%%%%%%%%%%
%I am modifying this batch originally developed by Karl Magnus Petersson to
%work with SPM8. It is specifically made for use in the neurocognition of
%language group at the DCCN/MPI.

%Roel Willems, Aug 2011
%
%I am doing the same,
%Julia Udden, May 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script loops over subjects, and fills in the subject-specific
% details of a prespecified job-structure by calling upon xpandjob5.
%--------------------------------------------------------------------------
% Author(s): KMP
% Date:    09/11/2006
%==========================================================================
% SUBJECT-SPECIFIC INFORMATION
% This construction presupposes a given directory structure, specified in
% infoSubjects.m, which generates info.subjects. In addition:
% rootdir (info.rootdir) contains a skeletton job-structure (info.job) and
% the subject directories (info.subjects{sbjnr,1}); each subject directory
% contains a number of experiments (info.subjects{sbjnr,2}), each with a
% number of functional sessions specified by info.subjects{sbjnr,3}, 
% a structural directory specified by info.subjects{sbjnr,4} and a 
% condition directory (info.subjects{sbjnr,5}) containing a mat-file 
% specifying condition names, onsets, durations etc.
%--------------------------------------------------------------------------
% addpath('/home/common/matlab/spm8/');

clear all;
InfoPreproc;

%--------------------------------------------------------------------------
% LOOP OVER SUBJECTS, EXPAND JOB STRUCTURE, AND SAVE EXPANDED JOB
%--------------------------------------------------------------------------
cwd=pwd; cd(info.rootdir);
dimSubjects=size(info.subjects);
for sbjnr=1:dimSubjects(1)
  clear jobs;
  load(fullfile(info.rootdir,info.job));
  %some renaming because of SPM8:
  jobs=matlabbatch;
  jobs=xpandjobs(jobs,info,sbjnr);
  jobname=strcat(info.subjects{sbjnr,1},'_xpanded8job');
  matlabbatch=jobs;
  save(fullfile(info.rootdir,info.subjects{sbjnr,1}, ...
    jobname),'matlabbatch');
end
%--------------------------------------------------------------------------
% LOOP OVER SUBJECTS, LOAD JOB STRUCTURE, AND RUN THE JOB
%--------------------------------------------------------------------------
spm_jobman('initcfg')
for sbjnr=1:dimSubjects(1)
  clear jobs;
  cd(fullfile(info.rootdir,info.subjects{sbjnr,1}));
  jobname=strcat(info.subjects{sbjnr,1},'_xpanded8job');
  load(fullfile(info.rootdir,info.subjects{sbjnr,1}, ...
    jobname));
  disp(info.subjects{sbjnr,1});
  spm_jobman('run',matlabbatch);
end
cd(cwd);
%--------------------------------------------------------------------------
