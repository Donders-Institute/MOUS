function [cohsent, cohseq] = mous_bfica_ccc(source, freq, varargin)

refindx = ft_getopt(varargin, 'refindx', 1:numel(source.inside));
freq    = mtmconvol2mtmfft(freq, []);

sel1    = find(ismember(freq.trialinfo(:,2), [1 2 5 6]));
sel2    = find(ismember(freq.trialinfo(:,2), [3 4 7 8]));

n = min(numel(sel1), numel(sel2));
tmp1 = randperm(numel(sel1));
tmp2 = randperm(numel(sel2));
sel1 = sort(tmp1(1:n));
sel2 = sort(tmp2(1:n));

tmp     = ft_selectdata(freq, 'rpt', sel1);
tmp     = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
cohsent = estimate_nullcoh3(source, tmp, 'refindx', refindx);

tmp     = ft_selectdata(freq, 'rpt', sel2);
tmp     = ft_checkdata(tmp, 'cmbrepresentation', 'fullfast');
cohseq  = estimate_nullcoh3(source, tmp, 'refindx', refindx);

cohsent.inside  = source.inside;
cohsent.outside = source.outside;
cohsent.dim     = source.dim;
cohsent.fwhm    = source.fwhm;

cohseq.inside  = source.inside;
cohseq.outside = source.outside;
cohseq.dim     = source.dim;
cohseq.fwhm    = source.fwhm;
