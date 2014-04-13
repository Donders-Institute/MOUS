% MOUS_MEGMRI_PIPELINE

if ~exist('subjectname', 'var'), error('subjectname should be provided'); end
if ~exist('rootdir',     'var'), rootdir  = '/project/3011020.09/MEG';    end
if ~exist('dointerp',    'var'), dointerp = 0;                            end
if ~exist('dointerp3d',    'var'), dointerp3d = 0;                          end

% HARD CODED, remove!
figpath  = '/project/3011020.09/jansch/results/20140328';  
  
opengl software
if dointerp
  close all;
  mripath  = '/home/language/juludd/MOUS/ffxstats_VIS_102';
  fname    = 'beta_0001.img'; % it would be good to have a lookup table in the script that specifies the meaning of each contrast.
  filename = fullfile(mripath,[subjectname,'-ffxStats'],fname);
  mri      = ft_read_mri(filename);
  [mri,~,h] = mous_fmri_3dto2d(subjectname, mri);
  
  mous_db_makesubjdir(subjectname, rootdir, {'megmri'});
  mous_db_putdata(subjectname, 'meg_megmri_beta0001', 'mri', rootdir);
  
  figname = fullfile(figpath, [subjectname,'_megmri_qc1.png']);
  p = get(h(1), 'position');
  x = getframe(h(1), [1 1 p(3:4)-1]);
  savepng(x.cdata, figname);
  
  %print(h(1), '-dpng', figname);
  
  figname = fullfile(figpath, [subjectname,'_megmri_qc2.png']);
  p = get(h(2), 'position');
  x = getframe(h(2), [1 1 p(3:4)-1]);
  savepng(x.cdata, figname);
 
  %print(h(2), '-dpng', figname);  
end
if dointerp3d
  close all;
  
  mripath  = '/home/language/juludd/MOUS/ffxstats_VIS_102';
  fname    = 'beta_0001.img'; % it would be good to have a lookup table in the script that specifies the meaning of each contrast.
  filename = fullfile(mripath,[subjectname,'-ffxStats'],fname);
  mri      = ft_read_mri(filename);
  
  load('standard_sourcemodel3d8mm');
  template = sourcemodel;
  mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
  [mri,h] = mous_fmri_3dto3d(subjectname, mri, sourcemodel, template);
  
  mous_db_makesubjdir(subjectname, rootdir, {'megmri'});
  mous_db_putdata(subjectname, 'meg_megmri_beta0001_3d', 'mri', rootdir);
  
  figname = fullfile(figpath, [subjectname,'_megmri_qc1.png']);
  p = get(h(1), 'position');
  x = getframe(h(1), [1 1 p(3:4)-1]);
  savepng(x.cdata, figname);
end