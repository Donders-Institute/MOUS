% get the data
mous_db_getdata(subjectname, 'meg_erf_allwords_02-nextword');
n    = cellfun('size', data.trial, 2);
data = ft_selectdata(data, 'rpt', n>=120);

% do a highpassfilter
% cfg          = [];
% cfg.hpfilter = 'yes';
% cfg.hpfreq   = 1;
% cfg.hpfilttype = 'firws';
% data         = ft_preprocessing(cfg, data);

% do a bsfilter
cfg          = [];
cfg.bsfilter = 'yes';
cfg.bsfreq   = [49 51];
cfg.bsfilttype = 'firws';
data           = ft_preprocessing(cfg, data);

cfg          = [];
cfg.bsfilter = 'yes';
cfg.bsfreq   = [99 101];
cfg.bsfilttype = 'firws';
data           = ft_preprocessing(cfg, data);

% constrain the time axis
data           = ft_selectdata(data, 'toilim', [-0.1 0.6-1./300]);

% compute the baseline covariance
cfg                = [];
cfg.channel        = 'MEG';
cfg.preproc.demean = 'yes';
cfg.preproc.baselinewindow = [-0.1 0];
cfg.covariance     = 'yes';
cfg.covariancewindow = [-0.1 0];
cfg.vartrllength   = 2;
tlckbas            = ft_timelockanalysis(cfg, data);

% compute the post stimulus onset covariance
cfg                = [];
cfg.channel        = 'MEG';
cfg.preproc.demean = 'yes';
%cfg.preproc.baselinewindow = [-inf 0];
cfg.covariance     = 'yes';
cfg.vartrllength   = 2;
tlck               = ft_timelockanalysis(cfg, data);

% get the volume conduction model
mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

% create a high-spatial resolution grid
% mri = mous_db_getdata(subjectname, 'meg_anatomy_coregCTF');
% mri.coordsys = 'ctf';
% sourcemodel = mous_anatomy_sourcemodel3D(mri, 4);
sourcemodel = mous_db_getdata(subjectname, 'meg_anatomy_sourcemodel2D_surfreg');
sourcemodel.inside = 1:8196;
sourcemodel.outside = [];

% compute the forward solution
cfg         = [];
cfg.vol     = vol;
cfg.grad    = tlck.grad;
cfg.channel = 'MEG';
cfg.backproject = 'no';
cfg.grid    = sourcemodel;
sourcemodel = ft_prepare_leadfield(cfg);
try, sourcemodel.cfg = rmfield(sourcemodel.cfg,'mri'); end

% compute the inverse solution
cfg         = [];
cfg.method  = 'lcmv';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.lambda     = '0.5%';
cfg.lcmv.fixedori   = 'yes';
cfg.lcmv.projectnoise = 'yes';
cfg.keepleadfield = 'yes';
cfg.vol     = vol;
cfg.grid    = sourcemodel;
source      = ft_sourceanalysis(cfg, tlck);

% compute the projected noise
C  = tlckbas.cov;
[u,s,v] = svd(C);
s(31:end,31:end)=0;
C  = u*s*v';
w  = cat(1,source.avg.filter{source.inside});
wC = w*C;
N  = sum(w.*wC,2);
noise       = zeros(size(source.pos,1),1);
noise(source.inside) = N;

mom    = cat(1,source.avg.mom{source.inside});
ix     = nearest(source.time,0);
mom    = mom-repmat(mean(mom(:,1:ix),2),[1 size(mom,2)]);
snoise = spdiags(1./noise,0,numel(noise),numel(noise));
mom    = sqrt(snoise)*mom;

for k = 1:size(mom,1)
  [pindx{k},pval{k}] = peakdetect2(abs(mom(k,:)),0.4);
end
Pindx = cat(2,pindx{:});
Pval  = cat(2,pval{:});

edges   = 0.5:5:210.5;
[n,bin] = histc(Pindx, edges);
time    = (tlck.time(edges(1:end-2))+tlck.time(edges(2:end-1)))./2;
n       = n(1:numel(time));

source = rmfield(source, {'leadfield'});
mous_db_putdata(subjectname, 'meg_other_lcmv_peaks', 'mom', 'time', 'n', 'source', '/project/3011020.09/jansch',0);



% load atlas_conte69_8196reg_LR_brodmann_subparc
% [source2, parcellation] = mous_lcmv_parcellate(source, tlck, 'method', 'parcellation', 'parcellation', atlas);
% 
% sel = ~strncmp(parcellation.label,'R_??',4)&~strncmp(parcellation.label,'L_??',4)&~strncmp(parcellation.label,'R_M',3)&~strncmp(parcellation.label,'L_M',3);
% parcellation.label  = parcellation.label(sel);
% parcellation.filter = parcellation.filter(sel);
% parcellation.u      = parcellation.u(sel);
% parcellation.s      = parcellation.s(sel);
% sel                 = find(sel);
% 
% % remap the parcellation
% tmp = zeros(size(source2.parcellation));
% for k = 1:numel(sel)
%   tmp(source2.parcellation==sel(k)) = k;
% end
% source2.parcellation = tmp;
% source2.parcellationlabel = parcellation.label;
% 
% clear w;
% for k = 1:numel(parcellation.label)
%   F = cat(1,source.avg.filter{find(source2.parcellation==k)});
%   
%   % prewhitening matrix
%   P    = sqrtm(F*tlckbas.cov*F');
%   
%   F    = P\F;
%   w{k} = F;
% end
% 
% % prepare the data and cfg for the dss-analysis
% data = ft_selectdata(data, 'channel', data.label(1:273));
% tr   = cell(numel(data.trial),1);
% for k = 1:numel(data.trial)
%   indx = nearest(data.time{k},0);
%   if indx>30
%     tr{k} = indx;
%   end
% end
% params.tr  = tr;
% params.pre = 30;
% params.pst = 210;
% params.demean = 'prezero';
% 
% % run dss per parcel
% cfg          = []; 
% cfg.method   = 'dss';
% cfg.cellmode = 'yes';
% cfg.dss.denf.function = 'denoise_avg2';
% cfg.dss.denf.params   = params;
% for k = 1:numel(w)
%   cfg.numcomponent = min(size(w{k},1),5);
%   tmpdata       = data;
%   tmpdata.trial = w{k}*data.trial;
%   tmpdata.label = data.label(1:size(tmpdata.trial{1},1));
%   tmpcomp       = ft_componentanalysis(cfg,tmpdata);
%   
%   params.computenew = 0;
%   s.X               = 1;
%   [~,~,avgcomp]     = denoise_avg2(params,tmpcomp.trial,s);
%   tmpcomp           = rmfield(tmpcomp, {'cfg' 'grad' 'trial' 'time'});
%   
%   dssdata(k).comp  = tmpcomp;
%   dssdata(k).w     = w{k};
%   dssdata(k).label = parcellation.label{k};
%   dssdata(k).avg   = avgcomp;
% end
