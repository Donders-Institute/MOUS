function mous_corrmnebf_grpavg(subjectnames,cfg)

% this function interpolates each subjects correlation matrix from 2D to 3D
% and then calculates an averaged interpolated correlation matrix across
% all subjects

% cfg requires 3 inputs which define the files needed for mous_corrmnebf_interpolate
% MNE source solution, TFR source solution and correlation matrix.
% the data will be saved with the same specifications as the correlation matrix
% 
% for example
% cfg = [];
% cfg.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
% cfg.erf = ['meg_corrmnebf_mnesingletrial_jack_',savemne,'_bf',savebf,'_',suff,'Hz_',cdtn];
% cfg.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
% 

for q = 1:numel(subjectnames)
    % interpolate the correlation matrix to 3d space
    % source   grid
    % [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectnames{q},cfginterp);
    [source3d] = mous_corrmnebf_interpolate(subjectnames{q},cfginterp);

    tmp = isfinite(source3d.corrmat);  % NaNs are due to interpolation where no value of cortical sheet belong to a particular voxel (gridpoint)
    source3d.corrmat(~isfinite(source3d.corrmat))=0;  % keep track of which participants have NaN in correlation matrix
    if q == 1
        dof  = double(tmp);
        data = source3d;
        inside = source3d.inside;
    else
        dof = double(tmp)+dof;
        data.corrmat = data.corrmat + source3d.corrmat;
    end 
end

dataAvg = data;
dataAvg.corrmat = data.corrmat./dof; % divide by number of subjects that contribute data to that voxel (i.e. subject doesn't have a NAN value for that voxel)

mous_db_putdata('groupresults',cfg.cor,'dataAvg','data','dof');

