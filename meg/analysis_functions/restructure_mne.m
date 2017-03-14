% This function takes a source reconstruction data structure (i.e. output
% of mous_mne_pipeline({'domne_conjunction', 1}, restructures the pow values in structure dat 
% according to dimension dimx and saves to directory dir.
% example use :
% restructure_mne(out,2,'/project/3011020.09/sopara/mne_pervoxel/baseline','usepow',1)

%% 
function restructure_mne(dat,dimx,dir)
newsize = size(dat.pow);
newsize(dimx) = 1;

if isfield(dat, 'pow')
    num = size(dat.pow,dimx);
    data = dat.pow;
else
    warning('data not complete');
end
 
ind = repmat({':'},1,ndims(dat.pow));
%% loop over length of dimx and save
out = zeros(newsize);
ft_progress('init','etf',   'Please wait...');
for i = 1:num
    ft_progress(i/num, 'Processing event %d from %d', i,num);
    ind{dimx} = i;
    out = squeeze(data(ind{:}));
    save(strcat(dir,'v',num2str(i)),'out')
end
ft_progress('close')




