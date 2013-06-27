% this script contains the sequential steps for the anatomical processing pipeline.
% it consists of the following steps:
%
% $Id: mous_anatomy_pipeline.m 31 2012-03-30 18:12:08Z jansch $

global ft_default;
ft_default.checksize = inf;

%% Set subject, input & output dirs
%mous_db_makesubjdir(subjectname);

if ~exist('docoregistration1', 'var'), docoregistration1 = 0; end
if ~exist('docoregistration2', 'var'), docoregistration2 = 0; end
if ~exist('docoregistration3', 'var'), docoregistration3 = 0; end
if ~exist('docoregistration4', 'var'), docoregistration4 = 0; end
if ~exist('doskullstrip',     'var'), doskullstrip     = 0;  end
if ~exist('doheadmodel',      'var'), doheadmodel      = 0;  end
if ~exist('dosourcemodel2d1',  'var'), dosourcemodel2d1  = 0;  end
if ~exist('dosourcemodel2d2',  'var'), dosourcemodel2d2  = 0;  end
if ~exist('dosourcemodel2d_reg', 'var'), dosourcemodel2d_reg = 0; end
if ~exist('dosourcemodel3d',  'var'), dosourcemodel3d  = 0;  end
if ~exist('doqualitycheck',   'var'), doqualitycheck   = 0;  end

if ~exist('thr_headmodel', 'var'), thr_headmodel = 0.5; end % influences behavior of headmodel creation step
if ~exist('refineflag',    'var'), refineflag    = 1; end % influences behavior of coregistration to polhemus point cloud

%% Coregister to MNI coordinate system
if docoregistration1
  % FIXME Subject V1048 has an issue with the FOV, use (hardcoded) another nifti
  if strcmp(subjectname, 'V1048')
    mri = ft_read_mri(fullfile('/home/language/juludd/MOUS/preprocdata/V1048/Structural/old/', 'str-V1048-001.nii'));
  elseif strcmp(subjectname, 'V1096')
  elseif strcmp(subjectname, 'V1097')
    mri = ft_read_mri(fullfile('/home/language/juludd/MOUS/rawdata/V1097/Structural', 'JULUDD_18022013_MOUS_V1097.MR.JULUDD_TRIO.0009.0187.2013.02.18.21.25.43.42912.20537773.IMA'));
  else
    mri = mous_db_getdata(subjectname, 'mri_nifti');
  end

  [mri, T] = mous_anatomy_coregMNI(mri);
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNI', mri); % creates a V1024coregMNI.nii file
end

%% Coregister to CTF coordinate system
if docoregistration2
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
  mous_db_putdata(subjectname, 'meg_anatomy_coregCTF', mri);
end

%% Coregister in a second step to the polhemus point-cloud
if docoregistration3
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  pos = mous_db_getdata(subjectname, 'meg_raw_pos');
  [mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, 0, refineflag);
  %icp = struct(mri.cfg.icp);
  mous_db_putdata(subjectname, 'meg_anatomy_coregCTF', mri);
  mous_db_putdata(subjectname, 'meg_anatomy_coreginfo', 'shape', 'shapemri');%'icp', 0);
end

%% Coregister in a third step to the coils rather than the lpa/rpa
if docoregistration4
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  pos = mous_db_getdata(subjectname, 'meg_raw_pos');
  mous_db_getdata(subjectname, 'meg_anatomy_coreginfo');
  [mri, shape, shapemri] = mous_anatomy_coregCTF(mri, pos, shape, shapemri, 1);
  %icp = struct(mri.cfg.icp);
  mous_db_putdata(subjectname, 'meg_anatomy_coregCTF', mri);
  mous_db_putdata(subjectname, 'meg_anatomy_coreginfo', 'shape', 'shapemri', 0);%'icp', 0);
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
  threshold    = 0.5;
  T            = inv(mri.transform);
  center       = round(T(1:3,4))';
  [seg, mask]  = mous_anatomy_skullstrip(subjectname, threshold, center); % threshold is a configurable parameter that determines the skullstrip behavior
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNIskullstrip',      seg); % creates a V1025coregMNIskullstrip.nii file
  mous_db_putdata(subjectname, 'meg_anatomy_coregMNIskullstripmask', mask);
end

%% Create singleshell volume conductor model of the head
if doheadmodel
  mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri.coordsys = 'ctf';
  vol = mous_anatomy_headmodel(mri, thr_headmodel);
  mous_db_putdata(subjectname, 'meg_anatomy_headmodel', 'vol', 0);
end

%% Freesurfer pipeline
if dosourcemodel2d1
  % create directory that will contain the results
  subjdirfs   = ['/home/language/annhul/MOUS/meg/',subjectname,'/anatomy'];

  str     = which('freesurferscript1.sh');
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
  
  cfg             = [];
  cfg.interactive = 'yes';
  figure;ft_sourceplot(cfg, wm);
  
  doedit = 0; % change this to 1 if needed
  if doedit
    wmfilename    = fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'wm.mgz');
    T1filename    = fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'T1.mgz');
    wmfilenameold = fullfile(subjdirfs,filesep,subjectname,filesep,'mri',filesep,'wm_old.mgz');
    system(['cp ',wmfilename,' ',wmfilenameold]);
    
    % here the editing takes place
    wm = ft_read_mri(wmfilename);
    T1 = ft_read_mri(T1filename);
    wm = mous_volumeedit(wm, T1);
    
    cfg = [];
    cfg.parameter = 'anatomy';
    cfg.filetype  = 'mgz';
    cfg.filename  = wmfilename;
    ft_volumewrite(cfg, wm);
  end
  
  % run the second part of the freesurfer pipeline
  system([p,'/freesurferscript2.sh ',subjdirfs,' ',subjectname]);
  
  % mne call to create dipole grid
  system([p,'/mnescript.sh ',subjdirfs,' ',subjectname]);
end

if dosourcemodel2d2
  % create the 2D sourcemodel based on the freesurfer mesh
  % extract the dipole grid from the *.fif-file and coregister it to CTF
  % coordinate system
  mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri2 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
  bnd  = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodelfif');
  bnd  = mous_anatomy_sourcemodel2D(bnd, mri1, mri2);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel2D', 'bnd', 0);
end

if dosourcemodel2d_reg
  % do the surface-based registration to th fs_average_164k mesh
  % this results in the nodes being 1-to-1 mapped.
  % subsequent downsampling to 8196 nodes keeps the nodes in register
  % this needs an installation of caret and some specific additional scripts

  % create directory that will contain the results
  subjdirfs   = ['/home/language/annhul/MOUS/meg/',subjectname,'/anatomy/',subjectname];
  outputdir   = tempname('/tmp'); 
  mkdir(outputdir);
  targetdir   = '/home/language/jansch/projects/mous/meg/templates/sourcemodel/fsaverage_LR_164k/';  

  str     = which('freesurfer_to_fs_LR.sh');
  [p,f,e] = fileparts(str);
  str     = ([p,'/freesurfer_to_fs_LR.sh ',subjdirfs,' ',targetdir,' ',outputdir]);
  
  % run the registration script 
  system(str);
  
  % save some of the relevant surfaces in freesurfer format to allow Matti's code to work on them
  outputdirsurf = fullfile(outputdir,subjectname,'surf');  
  mkdir(outputdirsurf);
  tmpname = fullfile(outputdir,subjectname,[subjectname,'.L.midthickness_orig.164k_fs_LR.coord.gii']);
  triname = fullfile(outputdir,subjectname,[subjectname,'.L.164k_fs_LR.topo.gii']);
  bnd = ft_read_headshape({tmpname triname});
  ft_write_headshape(fullfile(outputdirsurf,'lh.white'),bnd,'format','freesurfer');
  tmpname = fullfile(outputdir,subjectname,[subjectname,'.L.sphere.164k_fs_LR.coord.gii']);
  bnd = ft_read_headshape({tmpname triname});
  ft_write_headshape(fullfile(outputdirsurf,'lh.sphere'),bnd,'format','freesurfer');
  tmpname = fullfile(outputdir,subjectname,[subjectname,'.R.midthickness_orig.164k_fs_LR.coord.gii']);
  triname = fullfile(outputdir,subjectname,[subjectname,'.R.164k_fs_LR.topo.gii']);
  bnd = ft_read_headshape({tmpname triname});
  ft_write_headshape(fullfile(outputdirsurf,'rh.white'),bnd,'format','freesurfer');
  tmpname = fullfile(outputdir,subjectname,[subjectname,'.R.sphere.164k_fs_LR.coord.gii']);
  bnd = ft_read_headshape({tmpname triname});
  ft_write_headshape(fullfile(outputdirsurf,'rh.sphere'),bnd,'format','freesurfer');
 
  % mne call to create dipole grid
  system([p,'/mnescript.sh ',outputdir,' ',subjectname]);

  % copy the output into the database
  system(['cp ',fullfile(outputdir,subjectname,'bem',[subjectname,'-oct-6-src.fif']),' ',fullfile('/home/language/annhul/MOUS/meg/',subjectname,'anatomy',subjectname,'bem',[subjectname,'-oct-6-src_reg.fif'])]);

  mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri2 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
  
  fifname = fullfile('/home/language/annhul/MOUS/meg/',subjectname,'anatomy',subjectname,'bem',[subjectname,'-oct-6-src_reg.fif']);
  bnd  = ft_read_headshape(fifname,'format','mne_source');
  bnd  = mous_anatomy_sourcemodel2D(bnd, mri1, mri2);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg', 'bnd', 0);
end

%% create a 3D sourcemodel based on the MNI brain
if dosourcemodel3d
  mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
  mri1.coordsys = 'ctf';
  sourcemodel = mous_anatomy_sourcemodel3D(mri1, 8);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm', 'sourcemodel',0); 
  sourcemodel = mous_anatomy_sourcemodel3D(mri1, 10);
  mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin10mm', 'sourcemodel',0);
end

%% do quality check
if doqualitycheck
  mous_anatomy_qualitycheck(subjectname);
end
