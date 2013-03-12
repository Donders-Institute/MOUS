dopreproc = 0;
dofreq    = 0;
doccc     = 0;
collectresults = false;
docardiacconfound = 1;
rootdir = '/home/language/jansch/public/mous';
if dopreproc
  [data, ecg] = mous_restingstate_preprocessing(subjectname);
  mous_db_putdata(subjectname, 'meg_restingstate_data', 'data', 'ecg', rootdir);
end

if dofreq
  mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
  data = ft_appenddata([], data, ecg);
  freq = mous_restingstate_freq(data);
  fd   = ft_freqdescriptives([], freq);
  freq = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
  mous_db_putdata(subjectname, 'meg_restingstate_freq', 'freq', 'fd', rootdir);
end

if doccc
  addpath /home/language/jansch/projects/ccc_new
  addpath /home/language/jansch/matlab/fieldtrip/qsub
  addpath /home/language/jansch/matlab/misc

  subj = repmat({subjectname},[274 1]);
  n    = mat2cell(0:273, 1, ones(1,274));
  f    = repmat({rootdir}, [274 1]);
  frequency = repmat({20}, [274 1]);
  qsubcellfun('mous_restingstate_ccc', subj, f, frequency, n, 'memreq', 8*1024^3, 'timreq', 15*60);
end

if collectresults
  addpath /home/language/jansch/projects/ccc_new
  addpath /home/language/jansch/matlab/fieldtrip/qsub
  addpath /home/language/jansch/matlab/misc

  sourcemodel = mous_db_getdata(subjectname, 'meg_bfica_{_bfccc_sourcemodel}', '/home/language/jansch/public/mous');
  rsdir       = ['/home/language/jansch/public/mous/',subjectname,'/restingstate/'];
  files       = dir([rsdir, subjectname, 'coh*']);

  load(files(1).name, 'fwhm', 'insidenew', 'inside');
  sourcemodel.fwhm = fwhm;
  sourcemodel.inside = insidenew;
  krn = compute_kernel(sourcemodel, 'truncate', 1e-6);
  
  files = files(2:end);
  for k = 1:numel(files)
    load(files(k).name, 'dcoh');
    k
    if k==1
      d = dcoh;
      dsq = dcoh.^2;
    else
      d = d+dcoh;
      dsq = dsq+dcoh.^2;
    end
  end
  n  = 273;
  mx = d./n; %mean
  sx = sqrt(n.*(dsq - (d.^2)./n)./(n-1)); %SEM
  
  dcoh = mx./sx;
  dcoh = (dcoh+dcoh')./2;
  dcoh(~isfinite(dcoh)) = 0;
  
  [int,i1,i2] = intersect(inside, insidenew);
  dcoh = krn'*double(dcoh(i1,i1))*krn;
  
  cfg        = [];
  cfg.inside = insidenew;
  cfg.threshold = 1.5;
  cfg.dim  = sourcemodel.dim;
  cfg.indx = [1 2];
  cfg.tail = 1;
  clus     = cluster6D(cfg, dcoh);
  
  
  
end

if docardiacconfound
  [comp, comp2, avgpre, avgcomp, avgpst, sel1, sel2, compsel, fdlow, fdhigh, cohlow, cohhigh, icohlow, icohhigh] = mous_restingstate_cardiacconfound(subjectname);
  mous_db_putdata(subjectname, 'mous_restingstate_cardiacconfound', 'comp', 'comp2', 'avgpre', 'avgcomp', 'avgpst', 'sel1', 'sel2', 'compsel', 'fdlow', 'fdhigh', 'cohlow', 'cohhigh', 'icohlow', 'icohhigh', rootdir);
end
