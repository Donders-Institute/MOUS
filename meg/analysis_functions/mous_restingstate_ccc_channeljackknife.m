function coh = mous_restingstate_ccc_channeljackknife(sourcemodel,freq,frequency,refindx)

if nargin<4 
  refindx = 1;
end
if nargin<3 || isempty(frequency)
  frequency = 20;
end
if ischar(freq)
  % freq is the rootdir variable
  freq = mous_db_getdata(subjectname, 'mous_restingstate_freq', freq);
end
  
freqcsd = ft_selectdata(freq, 'foilim', frequency*[1 1]);
freqcsd = ft_checkdata(freqcsd, 'cmbrepresentation', 'fullfast');
leadf   = cat(2,sourcemodel.leadfield{sourcemodel.inside}); % NOTE: assumes rank 2, 2-columns per location
coh     = zeros(numel(sourcemodel.inside), numel(freqcsd.label));

for m = 1:numel(freqcsd.label)
  m
  tmpcsd        = freqcsd.crsspctrm;
  tmpleadf      = leadf;
  tmpcsd(m,:)   = [];
  tmpcsd(:,m)   = [];
  tmpleadf(m,:) = [];
  coh(:,m)      = spatial_filter_coh(tmpleadf,tmpcsd,0.001,refindx,'1dip_pca');
end

%coh.trials     = sel;
%coh.randomseed = randseed;
% 
% dcoh = abs(coh.coh)-abs(coh.w12);
% %dcoh = dcoh(tril(true(size(dcoh,1)),-1)==1);
% filt = coh.filt;
% ori  = coh.ori;
% 
% fprintf('computing fwhm\n');
% [fwhm, insidenew] = estimate_fwhm(filt, sourcemodel.pos, sourcemodel.inside, sourcemodel.dim, 0);
% inside = sourcemodel.inside;
% 
% [ix,i1,i2] = intersect(inside,insidenew);
% sourcemodel.fwhm   = fwhm;
% sourcemodel.inside = insidenew;
% 
% fprintf('computing smoothing kernel\n');
% krn  = compute_kernel(sourcemodel);
% fprintf('smoothing differential coherence matrix\n');
% dcoh = single(krn'*double(dcoh(i1,i1))*krn); 
% 
% %fname = ['/home/language/jansch/public/mous/',subjectname,'coh',num2str(randseed)];
% %save(fname,'dcoh','filt','randseed','sel','fwhm','insidenew','inside');
% 
% if 0,
%   fname = ['/home/language/jansch/public/mous/',subjectname,'/restingstate/',subjectname,suff,num2str(removechannel,'%03d')];
%   save(fname,'dcoh','filt','fwhm','insidenew','inside');
% else
%   if nargout
%     coh.fwhm = fwhm;
%     coh.dcoh = dcoh;
%     varargout{1} = coh;
%   end
% end