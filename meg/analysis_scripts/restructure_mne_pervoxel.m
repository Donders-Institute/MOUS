% This function takes a source reconstruction data structure (i.e. output
% of mous_mne_pipeline({'domne_conjunction', 1}, restructures the data dat of
% parameter para according to dimension dimx and saves to directory dir.
% example use :
% restructure_mne(out,'pow',2,'project/3011020.09/sopara/mne_pervoxel/baseline')

%% 
function restructure_mne(dat,para,dimx,dir)


%% save for each voxel
nVtx = size(out.pow,2);
for i 1:nVtx
    






