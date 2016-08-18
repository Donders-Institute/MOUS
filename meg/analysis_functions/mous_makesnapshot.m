function mous_makesnapshot(datavector, label, atlas, filename, varargin)

% MOUS_MAKESNAPSHOT makes a snapshot of the datavector that maps onto a
% parcellation, using the functionality of mous_makemovie_mne

[p,f,e]  = fileparts(filename);
filename = fullfile(p,f);

tmp       = [];
tmp.avg   = datavector;
tmp.label = label;
tmp.dimord = 'chan_time';
tmp.time   = 1;
tmp.string = {''};
tmp.mask   = clipat(datavector, 10);

mous_makemovie_mne(tmp,filename,'parcellation',atlas,'maskparameter','mask','plotroi',0,'demean','no', 'textstringparameter', 'string', varargin{:});
filenameavi = [filename,'.avi'];
delete(filenameavi);
