% this script contains the sequential steps for the anatomical processing pipeline.
% it consists of the following steps:
%
% $Id: mous_anatomy_pipeline.m 31 2012-03-30 18:12:08Z jansch $

% create directory that will contain the results
subjectname = 'V1024';

mous_db_makesubjdir(subjectname);

% directory that will hold freeurfer results
subjdirfs   = ['/home/language/annhul/MOUS/Processed/',subjectname,'/meg_anatomy'];

% coregister to MNI coordinate system
mri      = mous_db_getdata(subjectname, 'mri_nifti');
[mri, T] = mous_anatomy_coregMNI(mri);
% mous_db_putdata(subjectname, 'mri_coregMNI', mri); % this one points to Julia's homedir but does not work due to privileges
mous_db_putdata(subjectname, 'meg_anatomy_coregMNI', mri); % this one points to Annika's homedir

% next step is not necessary anymore when using the converted nifties
%
% % reslice
% mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
% mri.coordsys = 'mni';
% mri = mous_anatomy_reslice(mri);
% mous_db_putdata(subjectname, 'meg_anatomy_coregMNIresliced', mri);

% skull strip
mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
mri.coordsys = 'mni';
seg = mous_anatomy_skullstrip(mri);
mous_db_putdata(subjectname, 'meg_anatomy_coregMNIskullstrip', seg);

% coregister to CTF coordinate system
% display the pictures
filename3 = mous_db_getfilename(subjectname, 'meg_fidpic');
% read in the picture(s)
if numel(filename3)>0
  for k = 1:numel(filename3)
    picture = imread(filename3{k});
    figure;image(picture);
    title(filename3{k});
  end
end
mri = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
pos = mous_db_getdata(subjectname, 'meg_pos');
mri = mous_anatomy_coregCTF(mri, pos);
mous_db_putdata(subjectname, 'meg_anatomy_coregCTF', mri);

% create singleshell volume conductor model of the head
mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
mri.coordsys = 'ctf';
vol = mous_anatomy_headmodel(mri);
mous_db_putdata(subjectname, 'meg_anatomy_headmodel', vol);

% freesurfer pipeline
str     = which('freesurferscript1.sh');
[p,f,e] = fileparts(str);
system([p,'/freesurferscript1.sh ',subjdirfs,' ',subjectname]);

% create proper brainmask that works within freesurfer
p2   = [subjdirfs, '/',subjectname,'/mri/'];
mri1 = ft_read_mri([p2 'T1.mgz']);
mri2 = ft_read_mri([p2 'brainmask.mgz']);
mri1.anatomy(mri2.anatomy==0) = 0;

cfg = [];
cfg.filename  = [p2 'brainmask.mgz'];
cfg.filetype  = 'mgz';
cfg.parameter = 'anatomy';
cfg.datatype  = 'uint8';
ft_volumewrite(cfg, mri1);

cfg = [];
cfg.interactive = 'yes';
figure; ft_sourceplot(cfg, mri1);

% at this point it is wise to check the brainmask in tkmedit, and edit if
% necessary. first you can have a look at the brainmasked anatomy in matlab
% to see whether it is a problematic one

system([p,'/freesurferscript2.sh ',subjdirfs,' ',subjectname]);

% mne call to create dipole grid
system([p,'/mnescript.sh ',subjdirfs,' ',subjectname]);
cd(pwdir);

% create the 2D sourcemodel based on the freesurfer mesh
% extract the dipole grid from the *.fif-file and coregister it to CTF
% coordinate system
mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
mri2 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
vol  = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
bnd  = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodelfif');
[bnd, h] = mous_anatomy_sourcemodel2D(bnd, mri1, mri2, vol);
mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel2D', bnd);
mous_db_putdata(subjectname, 'meg_anatomy_figure_coreg', h);

% create a 3D sourcemodel based on the MNI brain
mri1.coordsys = 'ctf';
grid = mous_anatomy_sourcemodel3D(mri1, 8);
mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm', grid);
