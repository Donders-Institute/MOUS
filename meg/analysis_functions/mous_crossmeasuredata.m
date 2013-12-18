function mous_crossmeasuredata(subjectname, rootdir)

%load mri
%/home/language/juludd/MOUS/RFX_VIS_102_Ttests/SentVsIBI


file = ['/home/language/juludd/MOUS/ffxstats/' subjectname '-ffxStats/beta_0001.img'];
mri = ft_read_mri(file);

% Load the tranfomation matricies 
 mri1=mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
 mri2=mous_db_getdata(subjectname, 'meg_anatomy_coregMNI');
 
T1 = mri1.transform; % from voxels indices to CTF coordinates
T2 = mri2.transform; % from voxels indices to MNI coordinates
% we want to go from CTF to MNI 
% this one transform from CTF to MNI
T = T2/T1;


cfg = [];
cfg.nonlinear='no';
cfg.coordsys = 'ctf';
mri = ft_volumenormalise(cfg, mri);

T = mri.initial;

transfile = ['/home/language/juludd/MOUS/preprocdata/' subjectname '/Structural/' subjectname 'coregMNI_sn.mat'];
P = load(transfile);

% Load meg data
file = 'meg_mne_{_mne_allwords_01-10-sent_currentdensity_weighted}';
meg = mous_db_getdata(subjectname,file, rootdir);

% first warp the positions in the cortical sheet to the correct starting positions (after converting to mm)
meg = ft_convert_units(meg, 'mm');
pos = ft_warp_apply(T,meg.pos);

% Transform the meg matrix from individual space to nomralized mni space
% then warp from the 'starting positions', using the sn file
pos2 = ft_warp_apply(P, pos, 'individual2sn');


% Do inverse distance weighting of the mri anatomy to get the mri and meg
% grids to the same space

outname = mous_db_getfilename(subjectname,'meg_mne_{_mri_sentVSibi_interpol}',0,'/project/3011020.09/annhul');
cfg = [];
cfg.parameter = 'anatomy'; % ?
cfg.interpmethod =  'sphere_weighteddistance';
cfg.sphereradius = 20; 
cfg.outputfile =  outname{1}; 
ft_sourceinterpolate(cfg, mri, meg);  %change to pos2 when the ft_warp_apply is fixed

end
