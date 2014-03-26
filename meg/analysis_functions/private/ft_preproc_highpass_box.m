function dat = ft_preproc_highpass_box(dat, smooth)

mdat = ft_preproc_smooth(dat, smooth); % local estimate of the mean
dat  = dat-mdat;