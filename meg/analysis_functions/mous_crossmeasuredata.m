function mous_crossmeasuredata(subjectname, param)


%ffxinput, fmrioutput, outdir)
% 
% if nargin<2 
%   rootdir = '/project/3011020.09/MEG';
% end

% get the functional MRI data
% Julias naming scheme
% file = [param.ffxpath subjectname param.ffxinput]; 
% Huberts naming scheme
% FIXME JM: to keep the code flexible, consider allocating the filename of the
% contrast image outside the function, i.e. rather than coding it in the
% param input argument, just pass a separate argument that provides the
% filename, or alternatively use param.mrifilename and param.megfilename
file = [param.ffxpath  param.ffxinput subjectname '.img']; 

mri        = ft_read_mri(file, 'format', 'analyze_img');
mri.inside = isfinite(mri.anatomy); % ensure that voxels without data will not be used in the interpolation
mri.pow    = mri.anatomy; % for one reason or another it does not work if I keep using anatomy for the correct interpolation of NaNs
mri        = rmfield(mri, 'anatomy');
mri.coordsys = 'mni';

% Load the original mri from which the sourcemodels were computed
mrictf          = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
mrictf.coordsys = 'ctf';

% Normalize the anatomical
cfg           = [];
cfg.nonlinear = 'no';
mrictfn         = ft_volumenormalise(cfg, mrictf);

% Extract the Affine matrix that does an initial alignment
T = mrictfn.initial;

%transfile = ['/home/language/juludd/MOUS/preprocdata/' subjectname '/Structural/' subjectname 'coregMNI_sn.mat'];
%P = load(transfile);

% Load the 3D sourcemodel to get the spatial transformation parameters 
mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
sourcemodel = ft_convert_units(sourcemodel, 'mm');
P           = sourcemodel.params;

% Load the MEG data
mous_db_getdata(subjectname,param.megsheet); %, rootdir);
meg = ft_convert_units(source, 'mm'); clear source;

% Warp the positions in the cortical sheet to the correct starting positions (after converting to mm)
pos2d = ft_warp_apply(T,meg.pos);
pos3d = ft_warp_apply(T,sourcemodel.pos); % for sanity check

% Transform the meg matrix from individual space to nomralized mni space
% then warp from the 'starting positions', using the sn file
pos2d_sn = ft_warp_apply(P, pos2d, 'individual2sn');
pos3d_sn = ft_warp_apply(P, pos3d, 'individual2sn'); % for sanity check

% pos3d_sn can be used as a sanity check, these positions should be on a
% regular grid. pos2d_sn of course will not end up on a regular grid.
meg.pos = pos2d_sn;

% Interpolate the fMRI data onto the MEG cortical sheet, using inverse distance weighting
outname = mous_db_getfilename(subjectname,param.fmrioutput,0,param.outdir);

cfg              = [];
cfg.parameter    = 'pow'; % yes indeed
cfg.interpmethod = 'nearest';
tmp              = ft_sourceinterpolate(cfg, mri, meg); % with the nearest interpolation, we get nans where no fMRI data is available
outside          = ~isfinite(tmp.pow);

cfg.interpmethod =  'sphere_weighteddistance';
cfg.sphereradius = 8; 
cfg.outputfile   = outname{1}; %FIXME do the saving in the caller script, not in the function!
ft_sourceinterpolate(cfg, mri, meg);  
end
