function [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectname)

mous_db_getdata(subjectname, 'meg_corrmnebf_corVoxvert8mm');
mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_02-06');
source2 = source; clear source;
%FIXME the above is not needed yet, think of using the sourcemodel3d
%directly in mous_mne_2dto3d rather than doing the warp on the fly
mous_db_getdata(subjectname, 'meg_corrmnebf_mnesingletrial_02-06');

source.avg.pow = cor';
source.time    = 1:size(cor,1);

source3d = mous_mne_2dto3d(subjectname, source, 'resolution', 8);
source3d.inside  = source2.inside;
source3d.outside = source2.outside; % assuming they are the same as the interpolation target

sourcemodel = rmfield(source2, 'avg');
clear source source2;

source3d.corrmat = source3d.avg.pow(source3d.inside,:); % interpolated vertices X voxels
source3d.pos     = source3d.pos(source3d.inside,:);
source3d.inside  = 1:numel(source3d.inside);
source3d.outside = [];
source3d         = rmfield(source3d, 'avg');

