function mous_crossmeasuredata(subjectname, param)


%ffxinput, fmrioutput, outdir)
% 
% if nargin<2 
%   rootdir = '/project/3011020.09/MEG';
% end

% get the functional MRI data
file = [param.ffxpath subjectname param.ffxinput]; 


mri  = ft_read_mri(file, 'format', 'analyze_img');
mri.inside = isfinite(mri.anatomy); % ensure that voxels without data will not be used in the interpolation

% Load the original mri from which the sourcemodels were computed
mri1=mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');

cfg           = [];
cfg.nonlinear = 'no';
cfg.coordsys  = 'ctf';
mri1n         = ft_volumenormalise(cfg, mri1);

T = mri1n.initial;

%transfile = ['/home/language/juludd/MOUS/preprocdata/' subjectname '/Structural/' subjectname 'coregMNI_sn.mat'];
%P = load(transfile);

% Load meg data
mous_db_getdata(subjectname,'meg_mne_allwords_01-10-sent_currentdensity_weighted'); %, rootdir);
meg = ft_convert_units(source, 'mm'); clear source;

% Load a 3D sourcemodel for a sanity check
mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
sourcemodel = ft_convert_units(sourcemodel, 'mm');
P = sourcemodel.params;

% first warp the positions in the cortical sheet to the correct starting positions (after converting to mm)
pos2d = ft_warp_apply(T,meg.pos);
pos3d = ft_warp_apply(T,sourcemodel.pos);

% Transform the meg matrix from individual space to nomralized mni space
% then warp from the 'starting positions', using the sn file
pos2d_sn = ft_warp_apply(P, pos2d, 'individual2sn');
pos3d_sn = ft_warp_apply(P, pos3d, 'individual2sn');

% pos3d_sn can be used as a sanity check, these positions should be on a
% regular grid. pos2d_sn of course will not end up on a regular grid.
meg.pos = pos2d_sn;

% Interpolate the fMRI data onto the MEG cortical sheet, using inverse distance weighting
outname = mous_db_getfilename(subjectname,param.fmrioutput,0,param.outdir);
cfg = [];
cfg.parameter    = 'anatomy'; % ?
cfg.interpmethod =  'sphere_weighteddistance';
cfg.sphereradius = 20; 
cfg.outputfile =  outname{1}; 
ft_sourceinterpolate(cfg, mri, meg);  %change to pos2 when the ft_warp_apply is fixed

end
