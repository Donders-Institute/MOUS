
%==========================================================================
function [subjectPath,fctPath, ...
  fct_images,structPath,struct_image]= mous_selectimages(info,sbjnr);
%==========================================================================
% FORMAT: [subjectPath,experimentPaths,sessionPaths, ...
%   fct_images,structPath,struct_image]= selectimages(info,sbjnr);
% INPUT: info - cell array with information relating to subject etc.;
% sbjnr - the number of the subject for which the jobs structure is
% created;
% OUTPUT: subjectPath - fullpath to the current subject; sessionPath -
% cell array of the full session paths; fct_images - cell array containing
% session specific cell arrays with functional image names;
% strPath - character array with the fullpath to the directory of the
% structural image; str_image - character array with structural image name;
%--------------------------------------------------------------------------
% Author(s):    kmp, julia
% Updated:      09/07/2008, 19/10/2008, 16/04/2012
% Date:         09/11/2006
% © Karl Magnus Petersson
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% infoSubjects;	% cf., infoSubjects.m
fct_images={}; 
% subjectPath=fullfile(info.sbjdir,info.ffxdatadir);
subjectPath=fullfile(info.rootdir,info.subjects{sbjnr,1});
fctPath=fullfile(subjectPath,info.fctdir);
fct_images=cellstr(spm_select('List',fctPath,info.fct));
%--------------------------------------------------------------------------
% OUTPUT - subjectPath, experimentPaths, sessionPaths, fct_images, ...
% structPath, struct_image
%--------------------------------------------------------------------------
structPath=fullfile(subjectPath,info.structdir);
subject=char(info.subjects(sbjnr));
struct_image=strcat(structPath,filesep,subject,'coregMNI.nii');
%spm_select('List',structPath,info.str);
%End of selectimages-------------------------------------------------------
