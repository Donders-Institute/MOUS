% this script contains the sequential steps for the anatomical processing pipeline.
% it consists of the following steps:
%
% $Id: mous_anatomy_pipeline.m 31 2012-03-30 18:12:08Z jansch $

% create directory that will contain the results
mous_db_makesubjdir(subjectname);

subjdirfs   = ['/home/language/annhul/MOUS/Processed/',subjectname,'/meg_anatomy']; %directory that will hold freeurfer results

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

% cd into directory that holds freesurferscript.sh
pwdir = pwd;
cd('/home/language/jansch/projects/mous/matlab/analysis_functions');
system(['./freesurferscript.sh ',subjdirfs,' ',subjectname]);
system(['./mnescript.sh ',subjdirfs,' ',subjectname]);
cd(pwdir);

% extract the dipole grid from the *.fif-file and coregister it to CTF
% coordinate system
mri1 = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
mri2 = mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
vol  = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
bnd  = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodelfif');
[bnd, h] = mous_anatomy_sourcemodel2D(bnd, mri1, mri2, vol);
mous_db_putdata(subjectname, 'meg_anatomy_sourcemodel2D', bnd);
