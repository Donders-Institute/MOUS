function mous_bf_ccc(subjectname,removechannel)

freq        = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_freq}', '/home/language/jansch/public/mous');
%headmodel   = mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
%sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel3D_nonlin8mm');
sourcemodel = mous_db_getdata(subjectname, 'meg_bfica_{_bfccc_sourcemodel}', '/home/language/jansch/public/mous');

freq      = ft_struct2double(freq);

% cfg         = [];
% cfg.channel = freq.label;
% cfg.vol     = headmodel;
% cfg.grid    = sourcemodel;
% cfg.grad    = freq.grad;
% sourcemodel = ft_prepare_leadfield(cfg);

freqcsd = ft_selectdata(freq, 'toilim', -0.1+[-0.01 0.01]);

% cfg            = [];
% randseed       = round(sum(10000*clock));
% cfg.randomseed = randseed;
% ft_preamble randomseed
% sel     = randperm(size(freqcsd.fourierspctrm,1));
% sel     = sort(sel(1:round(0.9*numel(sel))));
% freqcsd = ft_selectdata(freqcsd, 'rpt', sel);
if ~isempty(removechannel) && removechannel>0
  freqcsd = ft_selectdata(freqcsd, 'channel', setdiff(1:numel(freqcsd.label),removechannel));
  for k = 1:numel(sourcemodel.inside)
    sourcemodel.leadfield{sourcemodel.inside(k)}(removechannel,:) = [];
  end
end

freqcsd = ft_checkdata(freqcsd, 'cmbrepresentation', 'fullfast');
coh     = estimate_nullcoh3(sourcemodel, freqcsd, 'threshold', 0.4);
%coh.trials     = sel;
%coh.randomseed = randseed;

dcoh = abs(coh.coh)-abs(coh.w12);
%dcoh = dcoh(tril(true(size(dcoh,1)),-1)==1);
filt = coh.filt;
ori  = coh.ori;

fprintf('computing fwhm\n');
[fwhm, insidenew] = estimate_fwhm(filt, sourcemodel.pos, sourcemodel.inside, sourcemodel.dim, 0);
inside = sourcemodel.inside;

[ix,i1,i2] = intersect(inside,insidenew);
sourcemodel.fwhm   = fwhm;
sourcemodel.inside = insidenew;
%fprintf('computing smoothing kernel\n');
%krn  = compute_kernel(sourcemodel);
%fprintf('smoothing differential coherence matrix\n');
%dcoh = single(krn'*double(dcoh(i1,i1))*krn); 

%fname = ['/home/language/jansch/public/mous/',subjectname,'coh',num2str(randseed)];
%save(fname,'dcoh','filt','randseed','sel','fwhm','insidenew','inside');
fname = ['/home/language/jansch/public/mous/',subjectname,'coh',num2str(removechannel,'%03d')];
save(fname,'dcoh','filt','fwhm','insidenew','inside');


if nargout
  varargout{1} = coh;
end
