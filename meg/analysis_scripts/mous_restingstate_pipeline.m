if ~exist('dopreproc', 'var'), dopreproc = 0; end
if ~exist('dofreq',    'var'), dofreq    = 0; end
if ~exist('dodss',     'var'), dodss     = 0; end
if ~exist('doccc',     'var'), doccc     = 0; end
if ~exist('dogranger1', 'var'), dogranger1 = 0; end
if ~exist('dogranger2', 'var'), dogranger2 = 0; end
if ~exist('domim', 'var'),      domim = 0; end
if ~exist('domim_freq_type1', 'var'), domim_freq_type1 = 0; end

collectresults = false;
docardiacconfound = 0;

if dopreproc
  [data, ecg] = mous_restingstate_preprocessing(subjectname, rootdir, options);
  if exist('savedir','var')
    % Get artifact data from /project/3011020.09./MEG, save data to diff directory
    mous_db_putdata(subjectname, 'meg_restingstate_data', 'data', 'ecg', savedir);
  else
    mous_db_putdata(subjectname, 'meg_restingstate_data', 'data', 'ecg', rootdir);
  end 
end

if dodss
  mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
  data = ft_appenddata([], data, ecg);
  [comp, avgpre, avgcomp] = mous_restingstate_dss(data);
  mous_db_putdata(subjectname, 'meg_restingstate_dss', 'comp', 'avgpre', 'avgcomp', rootdir);
end

if dofreq
  mous_db_getdata(subjectname, 'meg_restingstate_dss', '/project/3011020.09/jansch');
  
  % do the sensor level processing
  options            = [];
  options.resamplefs = 600;
  data               = mous_restingstate_preprocessing(subjectname, '', options);
  
  options            = [];
  options.length     = 4;
  options.overlap    = 0.5;
  options.avgcomp    = avgcomp;
  options.comp       = comp;
  options.tapsmofrq  = 2;
  freq               = mous_restingstate_freq(data, options);
  %mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
  %data = ft_appenddata([], data, ecg);
  %freq = mous_restingstate_freq(data);
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

if dogranger1
  mous_db_getdata(subjectname, 'meg_restingstate_dss', '/project/3011020.09/jansch');
  
%   % do the sensor level processing
%   options            = [];
%   options.resamplefs = 600;
%   data               = mous_restingstate_preprocessing(subjectname, '', options);

  mous_db_getdata(subjectname, 'meg_restingstate_data', '/project/3011020.09/jansch');
  
  options            = [];
  options.length     = 4;
  options.overlap    = 0.5;
  options.avgcomp    = avgcomp;
  options.comp       = comp;
  options.foilim     = [0 100];
  options.pad        = 4;
  [tlck, data_cut]   = mous_restingstate_tlck(data, options);
  options.tapsmofrq  = 2;
  %[freq, freq_ems]   = mous_restingstate_freq(data, options);
  [~, freq]   = mous_restingstate_freq(data, options); % use the ensemble mean subtracted version
  
  % compute the leadfields
%   mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
%   mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
%   sourcemodel = ft_convert_units(bnd,         'm');
%   sourcemodel.inside = 1:8196;
%   sourcemodel.outside = [];

  sourcemodel = mous_anatomy_sourcemodelparcellate_combined(subjectname, 4);
  sourcemodel = ft_convert_units(sourcemodel, 'm');
  sourcemodelorig = sourcemodel;
  
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  headmodel   = ft_convert_units(vol,         'm');
  tlck.grad   = ft_convert_units(tlck.grad,   'm');
  
  cfg      = [];
  cfg.vol  = headmodel;
  cfg.grad = tlck.grad;
  cfg.grid = sourcemodel;
  cfg.channel = 'MEG';
  sourcemodel = ft_prepare_leadfield(cfg);
  sourcemodel = mous_parcellate_leadfield(sourcemodel, sourcemodelorig);
  
  
  % compute the lcmv spatial filters
  cfg                 = [];
  cfg.method          = 'lcmv';
  cfg.lcmv.keepfilter = 'yes';
  cfg.lcmv.fixedori   = 'yes';%'no';
  cfg.lcmv.lambda     = '5%';
  cfg.lcmv.projectnoise = 'yes';
  cfg.grid            = sourcemodel;
  cfg.vol             = headmodel;
  source              = ft_sourceanalysis(cfg, tlck);
  
  %% do a parcellation based on the correlation structure in the data +
  %% spatial distance
  %addpath ~/matlab/toolboxes/Ncut_9
  %[sourceparc, parcellation] = mous_lcmv_parcellate(source, tlck);
 
  %%load atlas_conte69_8196reg_LR
  %%[sourceparc, parcellation]=mous_lcmv_parcellate(source,tlck,'method','parcellation','parcellation',atlas,'parcellationparam','parcellation4')
  %[sourceparc, parcellation]=mous_lcmv_parcellate(source,tlck,'method','parcellation','parcellation',sourcemodelorig,'parcellationparam','tissue')
  %
  %% create sensor cross-spectral density and project the cross-spectral density into parcel space
  %sel = find(~cellfun(@isempty, parcellation.filter));
  %F   = cat(1, parcellation.filter{sel});
  
  F = zeros(numel(sourcemodelorig.tissuelabel),273);
  for k = 1:size(F,1)
    tmp     = source.avg.filter{k};
  %  [u,s,v] = svd(tmp*tlck.cov*tmp');
  %  F(k,:)  = u(:,1)'*tmp;
    F(k,:) = tmp;
  end
  %noise = abs(diag(F*F'));
  
  freq      = ft_checkdata(freq, 'cmbrepresentation', 'fullfast');
  crsspctrm = zeros(size(F,1),size(F,1),256);%512); % anecdotally this speeds up the fft
  pow       = zeros(size(F,1),256);%,512);
  noise     = pow;
  for k = 1:size(crsspctrm,3)
%     for m = 1:size(F,1)
%       tmp     = source.avg.filter{m};
%       [u,s,v] = svd(real(tmp*freq.crsspctrm(:,:,k)*tmp'));
%       F(m,:)  = u(:,1)'*tmp;
%     end
%     k
    crsspctrm(:,:,k) = F*freq.crsspctrm(:,:,k)*F';
    pow(:,k)         = abs(diag(crsspctrm(:,:,k)));
    noise(:,k)       = abs(diag(F*F'));
  end
%   allori = cell(size(source.avg.filter));
%   for m = 1:size(source.avg.filter,1)
%     f = source.avg.filter{m};
%     ori = zeros(size(f,1), size(crsspctrm,3));
%     for k = 1:size(crsspctrm,3)
%       [u,s,v]  = svd(real(f*freq.crsspctrm(:,:,k)*f'));
%       ori(:,k) = u(:,1);
%     end
%     tmp = ori(:,1)'*ori;
%     sel = tmp<0;
%     ori(:,sel) = -ori(:,sel);
%     allori{m}  = ori;
%   end
  
%   for k = 1:size(crsspctrm,3)
%     F = zeros(size(source.avg.filter,1), size(source.avg.filter{1},2));
%     for m = 1:size(source.avg.filter,1)
%       F(m,:) = allori{m}(:,k)'*source.avg.filter{m};
%     end
%     crsspctrm(:,:,k) = F*freq.crsspctrm(:,:,k)*F';
%     pow(:,k)         = abs(diag(crsspctrm(:,:,k)));
%     noise(:,k)       = abs(diag(F*F'));
%   end
  freq.crsspctrm = crsspctrm;
  freq.label     = sourcemodel.label;
  freq.freq      = freq.freq(1:256);%512);
  %freq.label     = parcellation.label(sel);
  %mous_db_putdata(subjectname, 'meg_restingstate_csd_etc', 'tlck', 'freq', 'pow', 'noise', 'sourceparc', 'parcellation', '/project/3011020.09/jansch');
  mous_db_putdata(subjectname, 'meg_restingstate_csd_etc', 'tlck', 'freq', 'pow', 'noise', 'sourcemodelorig', 'source', '/project/3011020.09/jansch');
end
if dogranger2
  mous_db_getdata(subjectname, 'meg_restingstate_csd_etc', '/project/3011020.09/jansch');
  % compute Granger causality
  freq = ft_connectivity_csd2transfer(freq, 'sfmethod', 'bivariate', 'checkconvergence', 0);
  dat1 = ft_connectivity_granger(shiftdim(freq.transfer,-1),shiftdim(freq.noisecov,-1),shiftdim(freq.crsspctrm,-1),'dimord',freq.dimord,'method','granger');
  dat2 = ft_connectivity_granger(shiftdim(freq.transfer,-1),shiftdim(freq.noisecov,-1),shiftdim(freq.crsspctrm,-1),'dimord',freq.dimord,'method','total');
  
  g = rmfield(freq, {'crsspctrm', 'transfer', 'noisecov', 'label'});
  g.grangerspctrm = dat1;
  g.totispctrm    = dat2;
  
%   cfg          = [];
%   cfg.method   = 'granger';
%   cfg.granger.sfmethod = 'bivariate';
%   cfg.granger.checkconvergence = 0;
%   g            = ft_connectivityanalysis(cfg, freq);
  g            = ft_checkdata(g, 'cmbrepresentation', 'full');
  warning off;
  g            = ft_struct2single(g);
  warning on;
  mous_db_putdata(subjectname, 'meg_restingstate_granger', 'g', 'pow', 'noise', '/project/3011020.09/jansch');%, 0);
end

if domim
  
  % do the sensor level processing
  %options            = [];
  %options.resamplefs = 600;
  %data               = mous_restingstate_preprocessing(subjectname, '', options);
  
  mous_db_getdata(subjectname, 'meg_restingstate_data', '/project/3011020.09/jansch');
  mous_db_getdata(subjectname, 'meg_restingstate_dss',  '/project/3011020.09/jansch');
  
  v = var(avgcomp,[],2);
  v = v./v(1);

  % dummy trial to fool ft_rejectcomponent
  comp.trial = comp.time;

  % NOTE: this avoids a crash later on, but not sure which grad structure is
  % used in ft_rejectcomponent.
  if isfield(comp,'grad')
    comp = rmfield(comp, 'grad');
  end 

  cfg           = [];
  cfg.component = find(v>0.1);
  data          = ft_rejectcomponent(cfg, comp, data);

  
  options            = [];
  options.length     = 4;
  options.overlap    = 0.5;
  %options.avgcomp    = avgcomp;
  %options.comp       = comp;
  options.tapsmofrq  = 2;
  %[freq, freq_ems]   = mous_restingstate_freq(data, options);
  freq               = mous_restingstate_freq(data, options);
  
  % compute the leadfields
  mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
  sourcemodel = ft_convert_units(bnd,         'm');
  sourcemodel.inside = 1:8196;
  sourcemodel.outside = [];
  sourcemodelorig     = sourcemodel;
  
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  headmodel   = ft_convert_units(vol,         'm');
  freq.grad   = ft_convert_units(freq.grad,   'm');
  
  cfg = [];
  %cfg.frequency = 10;
  cfg.frequency = 22;
  cfg.channel   = 'MEG';
  freq = ft_selectdata(cfg, freq);
  
  cfg      = [];
  cfg.vol  = headmodel;
  cfg.grad = freq.grad;
  cfg.grid = sourcemodel;
  cfg.channel = 'MEG';
  cfg.backproject = 'no'; % create 2-column leadfield
  sourcemodel = ft_prepare_leadfield(cfg);
  
  load atlas_conte69_8196reg_LR_brodmann_subparc;
  
  addpath ~/Dropbox/utilities
  mim1 = estimate_mim4x4_1dip(sourcemodel, freq, 'lambda', 0.001, 'memory', 'low');
  P    = zeros(max(atlas.parcellation), double(size(mim1.mim,1)));
  for k = 1:max(atlas.parcellation)
    P(k,atlas.parcellation==k) = 1./sum(atlas.parcellation==k);
  end
  mim1.mim = P*double(mim1.mim)*P';
  mim2 = estimate_mimPxP_1dip(sourcemodel, freq, 'lambda', 0.001, 'parcellation', atlas, 'memory', 'low');
  mim3 = estimate_mimPxP_parcel(sourcemodel, freq, 'lambda', 0.001, 'parcellation', atlas);
  
  K = 2*sum(freq.cumtapcnt);
  %mous_db_putdata(subjectname, 'meg_restingstate_mim', 'freq', 'sourcemodel', 'mim1', 'mim2', 'mim3', '/project/3011020.09/jansch');
  mous_db_putdata(subjectname, 'meg_restingstate_mim22', 'freq', 'sourcemodel', 'mim1', 'mim2', 'mim3', 'K', '/project/3011020.09/jansch',0);

end

if domim_freq_type1
  if ~exist('frequency', 'var'), frequency = 10; end
  
  mous_db_getdata(subjectname, 'meg_restingstate_data', '/project/3011020.09/jansch');
  mous_db_getdata(subjectname, 'meg_restingstate_dss',  '/project/3011020.09/jansch');
  
%   v = var(avgcomp,[],2);
%   v = v./v(1);
% 
%   % dummy trial to fool ft_rejectcomponent
%   comp.trial = comp.time;
% 
%   % NOTE: this avoids a crash later on, but not sure which grad structure is
%   % used in ft_rejectcomponent.
%   if isfield(comp,'grad')
%     comp = rmfield(comp, 'grad');
%   end 
% 
%   cfg           = [];
%   cfg.component = find(v>0.1);
%   data          = ft_rejectcomponent(cfg, comp, data);

  
  options            = [];
  options.length     = 4;
  options.overlap    = 0.5;
  %options.avgcomp    = avgcomp;
  %options.comp       = comp;
  options.tapsmofrq  = 2;
  options.foilim     = [0 100];
  %[freq, freq_ems]   = mous_restingstate_freq(data, options);
  freq               = mous_restingstate_freq(data, options);
  
  % compute the leadfields
  mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
  sourcemodel = ft_convert_units(bnd,         'm');
  sourcemodel.inside = 1:8196;
  sourcemodel.outside = [];
  sourcemodelorig     = sourcemodel;
  
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  headmodel   = ft_convert_units(vol,         'm');
  freq.grad   = ft_convert_units(freq.grad,   'm');
  
  cfg = [];
  cfg.frequency = frequency;
  cfg.channel   = 'MEG';
  freq = ft_selectdata(cfg, freq);
  
  cfg      = [];
  cfg.vol  = headmodel;
  cfg.grad = freq.grad;
  cfg.grid = sourcemodel;
  cfg.channel = 'MEG';
  cfg.backproject = 'no'; % create 2-column leadfield
  sourcemodel = ft_prepare_leadfield(cfg);
  
  load atlas_conte69_8196reg_LR_brodmann_subparc;
  
  addpath ~/Dropbox/utilities
  mim = estimate_mim4x4_1dip(sourcemodel, freq, 'lambda', 0.001, 'memory', 'low');
  P   = zeros(max(atlas.parcellation), double(size(mim.mim,1)));
  for k = 1:max(atlas.parcellation)
    P(k,atlas.parcellation==k) = 1./sum(atlas.parcellation==k);
  end
  mim.mim = P*double(mim.mim)*P';

  mim     = rmfield(mim, {'w', 'lf'}); % remove to save memory;
  K       = 2*sum(freq.cumtapcnt);
  suffix  = ['meg_restingstate_mim',num2str(frequency),'Hz'];
  mous_db_putdata(subjectname, suffix, 'freq', 'mim', 'K', '/project/3011020.09/jansch');

end

