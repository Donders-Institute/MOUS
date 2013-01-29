function varargout=mous_restingstate_ccc(subjectname,freq,frequency,removechannel,suff)

if nargin<5 
  suff = 'coh';
end
if nargin<4 || isempty(removechannel)
  removechannel = 0;
end
if nargin<3 || isempty(frequency)
  frequency = 20;
end
if ischar(freq)
  % freq is the rootdir variable
  freq = mous_db_getdata(subjectname, 'mous_restingstate_freq', freq);
end
  
sourcemodel = mous_db_getdata(subjectname, 'meg_bfica_{_bfccc_sourcemodel}', '/home/language/jansch/public/mous');

% cfg         = [];
% cfg.channel = freq.label;
% cfg.vol     = headmodel;
% cfg.grid    = sourcemodel;
% cfg.grad    = freq.grad;
% sourcemodel = ft_prepare_leadfield(cfg);

freqcsd = ft_selectdata(freq, 'foilim', frequency*[1 1]);

if ~isempty(removechannel) && removechannel>0
  freqcsd = ft_selectdata(freqcsd, 'channel', setdiff(1:numel(freqcsd.label),removechannel));
  for k = 1:numel(sourcemodel.inside)
    sourcemodel.leadfield{sourcemodel.inside(k)}(removechannel,:) = [];
  end
end

freqcsd = ft_checkdata(freqcsd, 'cmbrepresentation', 'fullfast');
coh     = estimate_nullcoh3(sourcemodel, freqcsd, 'threshold', 0.3);
%coh.trials     = sel;
%coh.randomseed = randseed;

dcoh = abs(coh.coh)-abs(coh.w12);
%dcoh = dcoh(tril(true(size(dcoh,1)),-1)==1);
filt = coh.filt;'coh'
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

if 0,
  fname = ['/home/language/jansch/public/mous/',subjectname,'/restingstate/',subjectname,suff,num2str(removechannel,'%03d')];
  save(fname,'dcoh','filt','fwhm','insidenew','inside');
else
  if nargout
    varargout{1} = coh;
  end
end