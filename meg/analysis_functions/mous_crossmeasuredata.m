function mous_crossmeasuredata(subjectname, param)

% parameters needed 

% 
% param.ffxinput  % name of the fmri contrast to be interpolated e.g.
                  % 'con_ZinnenLTIBI_LinearIncrease_V1001' N.b. must include subject number% 
% param.ffxpath   % path for the fmri data
% param.megsheet  % name of meg mne data file computed on cortical sheet.
%                 % desired for the interpollation e.g. 'meg_processed_{_mne_allwords_02-nextword_sent}';
%
% param.fmrioutput  % name of output file e.g. 'meg_megmri_{sentLTibi_LinInce_interpol}'; 
% param.outdir      % path for output e.g. '/project/3011020.09/annhul'; 


file = [param.ffxpath  param.ffxinput '.img']; 

mri        = ft_read_mri(file, 'dataformat', 'analyze_img');
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
    if ~exist('source', 'var')
        if strcmp(param.osc, 'sent')
                  source = tlcksent;
        elseif strcmp(param.osc , 'seq')
            source = tlckseq;
        else
             error('specify the condition for the oscillation in the parameters');
        end
    end

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
cfg              = [];
cfg.parameter    = 'pow'; % yes indeed
cfg.interpmethod = 'nearest';
tmp              = ft_sourceinterpolate(cfg, mri, meg); % with the nearest interpolation, we get nans where no fMRI data is available
outside          = ~isfinite(tmp.pow);

cfg.interpmethod =  'sphere_weighteddistance';
cfg.sphereradius = 8; 
cfg.outputfile   = param.fmrioutput{1}; % param,fmrioutput = mous_db_getfilename(subjectname,'meg_megmri_{sentLTibsln_interpol}',0,param.outdir);
ft_sourceinterpolate(cfg, mri, meg);  
end
