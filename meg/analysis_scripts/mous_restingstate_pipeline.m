if ~exist('dopreproc', 'var'), dopreproc = 0; end
if ~exist('dofreq',    'var'), dofreq    = 0; end
if ~exist('dodss',     'var'), dodss     = 0; end
if ~exist('doccc',     'var'), doccc     = 0; end
if ~exist('dogranger1', 'var'), dogranger1 = 0; end
if ~exist('dogranger2', 'var'), dogranger2 = 0; end
if ~exist('domim', 'var'),      domim = 0; end
if ~exist('domim_freq_type1', 'var'), domim_freq_type1 = 0; end
if ~exist('dodss_osc', 'var'), dodss_osc = 0; end
if ~exist('dodss_F', 'var'), dodss_F = 0; end
if ~exist('dodss_osc_source', 'var'), dodss_osc_source = 0; end

if ~exist('rootdir', 'var'), rootdir = '/project/3011020.09'; end

global ft_default;
ft_default.checksize = inf;

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
  options.pad        = 4;
  [tlck, data_cut]   = mous_restingstate_tlck(data, options);
  options.foilim     = [0 100];
  options.tapsmofrq  = 2;
  [~, freq]   = mous_restingstate_freq(data, options); % use the ensemble mean subtracted version
  

  sourcemodel = mous_anatomy_sourcemodelparcellate_combined(subjectname, 4);
  sourcemodel = ft_convert_units(sourcemodel, 'm');
  sourcemodelorig = sourcemodel;
  
  mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
  headmodel   = ft_convert_units(vol,         'm');
  tlck.grad   = ft_convert_units(tlck.grad,   'm');
  
  % reject cardiac components
  v = var(avgcomp,[],2);
  v = v./v(1);
  kappa = numel(tlck.label) - sum(v>0.1);
  
  % compute the leadfields
  cfg             = [];
  cfg.headmodel   = headmodel;
  cfg.grad        = tlck.grad;
  cfg.sourcemodel = sourcemodelorig;
  cfg.channel     = 'MEG';
  cfg.backproject = 'no'; % stick to the plane-projected leadfields
  cfg.singleshell.batchsize = 2000;
  sourcemodel = ft_prepare_leadfield(cfg);
   
  % compute the lcmv spatial filters
  cfg                 = [];
  cfg.method          = 'lcmv';
  cfg.lcmv.keepfilter = 'yes';
  cfg.lcmv.fixedori   = 'no';
  cfg.lcmv.kappa      = kappa;
  cfg.lcmv.projectnoise = 'yes';
  cfg.sourcemodel     = sourcemodel;
  cfg.headmodel       = headmodel;
  source              = ft_sourceanalysis(cfg, tlck);
  
 [s,p] = mous_lcmv_parcellate(source, data_cut, 'parcellationparam', 'tissue', ...
          'parcellation', sourcemodelorig, ...
          'parcel_indx',  {'Cerebellum Left VIIb' 'Cerebellum Right VIIb' 'Thalamus Left Primary_motor' 'Thalamus Right Primary_motor' 'L_4_B05_01' 'L_4_B05_02' 'R_4_B05_01' 'R_4_B05_02'}, ...
          'method',       'parcellation_dss');
  
 [s_pca,p_pca] = mous_lcmv_parcellate(source, data_cut, 'parcellationparam', 'tissue', ...
          'parcellation', sourcemodelorig, ...
          'parcel_indx',  {'Cerebellum Left VIIb' 'Cerebellum Right VIIb' 'Thalamus Left Primary_motor' 'Thalamus Right Primary_motor' 'L_4_B05_01' 'L_4_B05_02' 'R_4_B05_01' 'R_4_B05_02'}, ...
          'method',       'parcellation');       
  %%
  % does the spatially filtered time domain data yield the same spectral
  % representation as the directly spatially filtered spectral data?
  cfg = removefields(freq.cfg, {'channel' 'previous'});
  
  data_p = mous_restingstate_data2parcel(data_cut, p, 1:8, 2);
  freq_p = ft_freqanalysis(cfg, data_p);
  data_pca = mous_restingstate_data2parcel(data_cut, p_pca, 1:8, 2);
  freq_pca = ft_freqanalysis(cfg, data_pca);
  
  ixf = 1:(nearest(freq_p.freq, 98)-1);
  foi = freq_p.freq(ixf);
  
  for i = 1:20
    selvec = 0:(2*numel(p.freq)):(numel(freq_p.label)-1);
    selvec = reshape([selvec; selvec+1],[],1);
    offset = 4*i; % in steps of 1 Hz
    
    this = freq_p;
    this.fourierspctrm = freq_p.fourierspctrm(:, selvec+offset, :);
    this.label         = freq_p.label(selvec+offset);
    
    csd_p = ft_checkdata(this, 'cmbrepresentation', 'fullfast');
    [g_p{i}] = do_granger4x4(csd_p.crsspctrm(:,:,ixf), foi, [], csd_p.label, 'struct');
    [g_prev{i}] = do_granger4x4(conj(csd_p.crsspctrm(:,:,ixf)), foi, [], csd_p.label, 'struct');
  end
  
  csd_pca = ft_checkdata(freq_pca, 'cmbrepresentation', 'fullfast');
  [g_pca] = do_granger4x4(csd_pca.crsspctrm(:,:,ixf), foi, [], csd_pca.label, 'struct');
  
  % this one is slightly different, probably due to some leakage of the DC
  % component through the projection -> thus work with the computationally
  % slightly less efficient steps above
  %freq_p2 = mous_restingstate_data2parcel(freq, p, 1);
  
  
 
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

if dodss_osc
  mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
  mous_db_getdata(subjectname, 'meg_restingstate_dss',  rootdir);
  
  v = var(avgcomp,[],2);
  v = v./v(1);

  % NOTE: this avoids a crash later on, but not sure which grad structure is
  % used in ft_rejectcomponent.
  if isfield(comp,'grad')
    comp = rmfield(comp, 'grad');
  end 
  dataorig = data;
  
  cfg           = [];
  cfg.component = find(v>0.1);
  data          = ft_rejectcomponent(cfg, comp, data);
  clear comp;
  
  nsmp     = cellfun('size',data.trial,2);
  nsmp     = nsmp(:)';
  
  cfg = [];
  cfg.trials = find(nsmp>5*data.fsample);
  data     = ft_selectdata(cfg, data);
  dataorig = ft_selectdata(cfg, dataorig);
  
  cfgr         = [];
  cfgr.length  = 2;
  cfgr.overlap = 0.5;
  data         = ft_redefinetrial(cfgr, data);
  
  cfgpp             = [];
  %cfg.polyremoval = 'yes';
  %cfg.polyorder   = 2;
  cfgpp.hpfilter   ='yes';
  cfgpp.hpfreq     = 1;
  cfgpp.hpfilttype = 'firws';
  
  nsmp     = cellfun('size',data.trial,2);
  nsmp     = nsmp(:)';
  tr_begin = cumsum([0 nsmp(1:end-1)])+1;
  tr_end   = cumsum(nsmp);
  
  cfg               = [];
  cfg.channel       = 'MEG';
  %cfg.numcomponent  = 40;
  cfg.cellmode      = 'yes';
  cfg.method        = 'dss';
  %cfg.dss.algorithm = 'defl';
  cfg.dss.algorithm = 'pca';
  cfg.dss.denf.function = 'denoise_filter2';
  cfg.dss.denf.params.filter_filtfilt.A = [];
  cfg.dss.denf.params.filter_filtfilt.B = [];
  cfg.dss.denf.params.tr_begin = tr_begin(:);
  cfg.dss.denf.params.tr_end   = tr_end(:);
  
  cfgf = [];
  cfgf.output = 'pow';
  cfgf.method = 'mtmfft';
  cfgf.taper  = 'dpss';
  cfgf.tapsmofrq = 1;
  cfgf.foilim    = [0 40];
  
  if ~exist('freqs','var')  
    freqs = (2:0.5:30);
  end
  
  for k = 1:numel(freqs)
    fprintf('processing frequency %d Hz\n',freqs(k));
    [filt, B, A] = ft_preproc_bandpassfilter(data.trial{1},data.fsample,freqs(k)+[-1 1].*freqs(k)./8,[],'firws');
    cfg.dss.denf.params.filter_filtfilt.A = A;
    cfg.dss.denf.params.filter_filtfilt.B = B;
    cfg.dss.denf.params.filter_filtfilt.function = 'fir_filterdcpadded';
    
    cfgpp.hpfreq = freqs(k)./1.5;
    comp = ft_componentanalysis(cfg, ft_preprocessing(cfgpp, data));
    T(:,:,k) = comp.topo;
    freq = ft_freqanalysis(cfgf, comp);
    
    if k==1
      powspctrm = freq.powspctrm;
      powspctrm(:,:,numel(freqs)) = 0;
    end
    powspctrm(:,:,k) = freq.powspctrm;
    allcomp(k,1) = removefields(comp, {'trial','grad','time'});
    
  end
  
  mous_db_putdata(subjectname, 'meg_restingstate_dssosc', 'allcomp', 'freqs', 'powspctrm');
end

if dodss_osc_source 
  
  mous_db_getdata(subjectname, 'meg_restingstate_data', rootdir);
  mous_db_getdata(subjectname, 'meg_restingstate_dss',  rootdir);
  mous_db_getdata(subjectname, 'meg_restingstate_dssosc',  rootdir);
  
  v = var(avgcomp,[],2);
  v = v./v(1);

  % NOTE: this avoids a crash later on, but not sure which grad structure is
  % used in ft_rejectcomponent.
  if isfield(comp,'grad')
    comp = rmfield(comp, 'grad');
  end 
  dataorig = data;
  
  cfg           = [];
  cfg.component = find(v>0.1);
  data          = ft_rejectcomponent(cfg, comp, data);
  clear comp;
  
  % get the leadfields
  % get the necessary geometric objects
  mous_db_getdata(subjectname,'meg_anatomy_headmodel');
  mous_db_getdata(subjectname,'meg_anatomy_sourcemodel3D_nonlin8mm');
  
  % source reconstruction with beamformer
  cfg = [];
  cfg.headmodel   = vol;
  cfg.grid        = sourcemodel;
  cfg.channel     = 'MEG';
  cfg.backproject = 'no';
  cfg.singleshell.batchsize = 2000;
  leadfield       = ft_prepare_leadfield(cfg, data);

  weightlim = 5;
  weightexp = .8;%0.5;
  
  % this part computes the sum of squares of the leadfields, and uses the
  % inverse of it for depth weighting.
  Lss = zeros(prod(leadfield.dim),1)+nan;
  if islogical(leadfield.inside)
    inside = find(leadfield.inside);
  else
    inside = leadfield.inside;
  end
  for k = 1:numel(inside)
    indx = inside(k);
    lf   = leadfield.leadfield{indx};
    Lss(indx,:) = sum(sum(lf.^2));
  end
  Lss    = (1./Lss)';
  minLss = min(Lss(leadfield.inside));
  Lss(Lss>minLss.*weightlim.^2) = minLss.*weightlim.^2;
  
  A = Lss(:).^weightexp;
  A = repmat(A(inside),[1 2])';
  
  % create a source covariance matrix that is equivalent to the area(^2)
  % times the 1./leadfield-sum-of-square to the power of weightexp
  % weighting in bst_wmne
  S = spdiags(A(:),0,speye(numel(A)));


  % prepare some cfgs
  nsmp     = cellfun('size',data.trial,2);
  nsmp     = nsmp(:)';
  
  cfg = [];
  cfg.trials = find(nsmp>5*data.fsample);
  data     = ft_selectdata(cfg, data);
  dataorig = ft_selectdata(cfg, dataorig);
  
  cfgf = [];
  cfgf.output = 'fourier';
  cfgf.method = 'mtmfft';
  cfgf.taper  = 'dpss';
  cfgf.tapsmofrq = 1;
  cfgf.foilim    = [0 40];
  
  cfgr         = [];
  cfgr.length  = 2;
  cfgr.overlap = 0.5;
  data = ft_redefinetrial(cfgr, data);
  
  cfg = [];
  cfg.hpfilter = 'yes';
  cfg.hpfreq   = 1;
  cfg.hpfilttype = 'firws';
  %cfg.lpfilter = 'yes';
  %cfg.lpfreq   = 40;
  %cfg.lpfilttype = 'firws';
  cfg.polyremoval = 'yes';
  cfg.polyorder   = 2;
  data = ft_preprocessing(cfg, data);
  freq = ft_freqanalysis(cfgf, data);
  
  cfgpp             = [];
  %cfg.polyremoval = 'yes';
  %cfg.polyorder   = 2;
  cfgpp.hpfilter   ='yes';
  cfgpp.hpfreq     = 1;
  cfgpp.hpfilttype = 'firws';
  
  cfgs             = [];
  cfgs.method      = 'lcmv';
  cfgs.grid        = leadfield;
  cfgs.headmodel   = vol;
  cfgs.lcmv.keepfilter = 'yes';
  cfgs.lcmv.fixedori = 'no';
  cfgs.lcmv.weightnorm= 'unitnoisegain';
  cfgs.lcmv.projectnoise = 'yes';
  
%   cfgs                 = [];
%   cfgs.method          = 'mne';
%   cfgs.headmodel       = vol;
%   cfgs.mne.prewhiten   = 'yes';
%   cfgs.mne.snr         = 2; % used to be 2
%   cfgs.mne.scalesourcecov  = 'yes';
%   cfgs.mne.keepfilter  = 'yes';
%   cfgs.mne.sourcecov   = S;
  if ~exist('freqs','var')
    freqs = (2:0.5:30);
  end
  
  data.time(:) = data.time(1);
  
  cfgt = [];
  cfgt.covariance = 'yes';
  tlckdata = ft_timelockanalysis(cfgt, data);
  
  pow  = zeros(sum(leadfield.inside),81,numel(freqs));
  
  ncomp = 40;
  for k = 1:numel(allcomp)
    cfgpp.hpfreq = freqs(k)./1.5;
    tmpdata      = ft_preprocessing(cfgpp, data);
    tlckdata     = ft_timelockanalysis(cfgt, tmpdata);
    tmpfreq      = ft_freqanalysis(cfgf, tmpdata);
%     %tlck = ft_timelockanalysis(cfgt, comp);   
%     
%     %tlckdata.cov = comp.topo*tlck.cov*comp.topo';
%     tlck       = tlckdata;
%     tlck.cov   = eye(ncomp);
%     tlck.label = allcomp(k).label(1:ncomp);
%     
%     tmpleadfield = leadfield;
%     tmpleadfield.leadfield(inside) = allcomp(k).unmixing(1:ncomp,:)*tmpleadfield.leadfield(inside);
%     tmpleadfield.label = allcomp(k).label(1:ncomp);
%     
%     % call the low level function directly, because the bookkeeping in
%     % ft_sourceanalysis requires a consistent grad structure
%     source = minimumnormestimate(leadfield,[],vol,allcomp(k).topo(:,1:ncomp),'noisecov',eye(size(allcomp(k).topo,1))./100,'snr',8,'prewhiten','yes','scalesourcecov','yes','keepfilter','yes','sourcecov',S);
%     
%     %cfgs.grid = tmpleadfield;
    
    cfgs.lcmv.subspace = allcomp(k).unmixing(1:ncomp,:);
    source = ft_sourceanalysis(cfgs, tlckdata);
    %filt   = cat(1,source.avg.filter{:});%*comp.topo;
    filt = cat(1,source.avg.filter{:}); 
    
    if k==1
      % projection matrix to collapse across dipole components
      n = sum(source.inside);
      x = repmat(1:n,[2,1]);
      y = 1:(2*n);
      z = ones(2*n,1)./2;
      P = sparse(x(:),y(:),z(:),n,2*n);
    end
    
    F = permute(tmpfreq.fourierspctrm, [2 1 3]);
    tmp = zeros(2*n,numel(freq.freq));
    for m = 1:numel(freq.freq)
      %fprintf('computing power for frequency %f\n',freq.freq(m));
      tmp(:,m) = mean(abs(filt*F(:,:,m)).^2,2);
    end
    pow(:,:,k) = P*tmp;
  end
  
  pow2 = pow;
  pow2 = pow2./sum(pow2,2);
  for k = 1:numel(freqs)
    ix           = nearest(freq.freq,freqs(k));
    pow2(:,ix,k) = mean(pow2(:,[ix-1 ix+1],k),2);
  end
  

end
