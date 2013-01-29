% this script contains the sequential steps for the anatomical processing pipeline.
% it consists of the following steps:
%
% $Id: mous_anatomy_pipeline.m 31 2012-03-30 18:12:08Z jansch $

%% Set subject, input & output dirs
%mous_db_makesubjdir(subjectname);

if ~exist('docoregistration', 'var'), docoregistration = false; end
if ~exist('doskullstrip', 'var'), doskullstrip = true; end
if ~exist('doheadmodel', 'var'), doheadmodel = true; end
if ~exist('dosourcemodel2d', 'var'), dosourcemodel2d = true; end
if ~exist('dosourcemodel3d', 'var'), dosourcemodel3d = true; end
if ~exist('doqualitycheck', 'var'), doqualitycheck = true; end

if ~exist('thr_headmodel', 'var'), thr_headmodel = 0.5; end

%% Coregister to MNI coordinate system
if docoregistration
  % FIXME Subject V1048 has an issue with the FOV, use (hardcoded) another nifti
  if strcmp(subjectname, 'V1048')
    mri = ft_read_mri(fullfile('/home/language/juludd/MOUS/preprocdata/V1048/Structural/old/', 'str-V1048-001.nii'));
  else
    mri = mous_db_getdata(subjectname, 'mri_nifti');
  end

  [mri, T] = mous_anatomy_coregMNI(mri);
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNI', mri); % creates a V1024coregMNI.nii file
end

%% Coregister to CTF coordinate system
if docoregistration
  % display the pictures of the ears
  filename3 = mous_db_getfilename(subjectname, 'meg_raw_fidpic');
  % read in the picture(s)
  if numel(filename3)>0
    for k = 1:numel(filename3)
      picture = imread(filename3{k});
      figure;image(picture);
      title(filename3{k});
    end
  end
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
  pos = mous_db_getdata(subjectname, 'meg_raw_pos');
  mri = mous_anatomy_coregCTF(mri, pos);
  mous_db_putdata(subjectname, 'meg_anatomy_coregCTF', mri);% creates a V1025coregCTF.nii file
end

% next step is not necessary anymore when using the converted nifties
%
% % reslice
% mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
% mri.coordsys = 'mni';
% mri = mous_anatomy_reslice(mri);
% mous_db_putdata(subjectname, 'meg_anatomy_coregMNIresliced', mri);

%% Skull strip
if doskullstrip
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
  mri.coordsys = 'mni';
  threshold = 0.5;
  T = inv(mri.transform);
  center = round(T(1:3,4))';
  [seg, mask] = mous_anatomy_skullstrip(subjectname, threshold, center); % threshold is a configurable parameter that determines the skullstrip behavior
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNIskullstrip', seg); % creates a V1025coregMNIskullstrip.nii file
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNIskullstripmask', mask);
end

%% Create singleshell volume conductor model of the head
if doheadmodel
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri.coordsys = 'ctf';
  vol = mous_anatomy_headmodel(mri, thr_headmodel);
  mous_db_putdata(subjectname, 'meg_anatomy_headmodel', 'vol');
end

%% Freesurfer pipeline
if dosourcemodel2d
  % create directory that will contain the results
  subjdirfs = ['/home/language/annhul/MOUS/meg/',subjectname,'/anatomy'];

  str = which('freesurferscript1.sh');
  [p,f,e] = fileparts(str);
  
  % run the first part of the freesurfer pipeline
  system([p,'/freesurferscript1.sh ',subjdirfs,' ',subjectname]);
   
  % At this stage have a look at the wm.mgz in matlab to see whether
  % it is a problematic one. Most problems arise downstream in the analysis
  % pipeline when large slabs of dura have not been removed.
  % If there is a generous amount of dura, and if it is close to the cortex
  % the wm.mgz needs to be manually edited. This can be done in tkmedit,
  % but since 20130125 also in matlab, using mous_volumeedit.
  
  % check wm.mgz
  wm = ft_read_mri(fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'wm.mgz'));
  
  cfg = [];
  cfg.interactive = 'yes';
  figure;ft_sourceplot(cfg, wm);
  
  doedit = 0; % change this to 1 if needed
  if doedit
    wmfilename = fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'wm.mgz');
    wmfilenameold = fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'wm_old.mgz');
    system(['cp ',wmfilename,' ',wmfilenameold]);
    
    % here the editing takes place
    wm = mous_volumeedit(wm);
    
    cfg = [];
    cfg.parameter = 'anatomy';
    cfg.filetype = 'mgz';
    cfg.filename = wmfilename;
    ft_volumewrite(cfg, wm);
  end
  
  % run the second part of the freesurfer pipeline
  system([p,'/freesurferscript2.sh ',subjdirfs,' ',subjectname]);
  
  % mne call to create dipole grid
  system([p,'/mnescript.sh ',subjdirfs,' ',subjectname]);
  
  % create the 2D sourcemodel based on the freesurfer mesh
  % extract the dipole grid from the *.fif-file and coregister it to CTF
  % coordinate system
  mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri2 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
  bnd = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodelfif');
  bnd = mous_anatomy_sourcemodel2D(bnd, mri1, mri2);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel2D', 'bnd');
end

%% create a 3D sourcemodel based on the MNI brain
if dosourcemodel3d
  mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri1.coordsys = 'ctf';
  grid = mous_anatomy_sourcemodel3D(mri1, 8);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm', 'grid'); %creates V1025sourcemodel3Dnonlin8mm.mat
  grid = mous_anatomy_sourcemodel3D(mri1, 10);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin10mm', 'grid'); %creates V1025sourcemodel3Dnonlin8mm.mat
end

%% do quality check
if doqualitycheck
  mous_anatomy_qualitycheck(subjectname);
end
