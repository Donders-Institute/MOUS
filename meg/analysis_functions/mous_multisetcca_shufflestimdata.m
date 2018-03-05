function stimdata = mous_multisetcca_shufflestimdata(data, allshufvec)

% create a a series of shuffled stimdata structures, that reflect the
% stimulus onsets for the shuffled data

tmp = addstimchan(data,'vis',0);

cfg = [];
cfg.channel = tmp.label(end);
tmp = ft_selectdata(cfg, tmp);

tmp = {tmp};
tmp = repmat(tmp, [1 size(allshufvec,1)]);
stimdata = shuffletrials(tmp, allshufvec, 2);


