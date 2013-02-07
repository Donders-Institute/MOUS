function [cohsent, cohseq] = mous_bfica_ccc(source, freq, varargin)

addpath('/home/language/jansch/projects/ccc_new');

refindx = ft_getopt(varargin, 'refindx', 1:numel(source.inside));
if isfield(freq, 'time') && numel(freq.time)>1
  freq    = mtmconvol2mtmfft(freq, []);
end

% orient the leadfields
if isfield(source,'avg') && isfield(source.avg,'ori')
for k = 1:numel(source.inside)
  indx = source.inside(k);
  source.leadfield{indx} = source.leadfield{indx}*source.avg.ori{indx};
end
end

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

cohseq.inside  = source.inside;
cohseq.outside = source.outside;
cohseq.dim     = source.dim;

if isfield(source, 'fwhm')
  cohsent.fwhm   = source.fwhm;
  cohseq.fwhm    = source.fwhm;
end

krn = compute_kernel(source);
cohsent.coh = single(krn'*double(abs(cohsent.coh)));%*krn);
cohsent.w12 = single(krn'*double(abs(cohsent.w12)));%*krn);
%cohsent     = rmfield(cohsent, 'w12');

cohseq.coh = single(krn'*double(abs(cohseq.coh)));%*krn);
cohseq.w12 = single(krn'*double(abs(cohseq.w12)));%*krn);
%cohseq     = rmfield(cohseq, 'w12');

