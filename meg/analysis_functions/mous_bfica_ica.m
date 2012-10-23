function [comp] = mous_bfica_ica(subjectnames, n)

if nargin==1
  n = [];
end

if ~iscell(subjectnames), subjectnames = {subjectnames}; end

for k = 1:numel(subjectnames)
  tmp = mous_db_getdata(subjectnames{k}, 'meg_processed_{bfICA_sourcedata}');
  if ~isempty(n)
    if size(tmp.trial{1},2)<n
      % don't select
    else
      fprintf('selecting %d samples from dataset %s\n', n, subjectnames{k});
      sel = randperm(size(tmp.trial{1},2));
      sel = sel(1:n);
      tmp.trial{1} = tmp.trial{1}(:,sort(sel));
    end
  end
  
  if k==1
    data = tmp;
  end
  sel = isfinite(tmp.trial{1}(1,:));
  data.trial{k} = tmp.trial{1}(:,sel)-nanmean(tmp.trial{1},2)*ones(1,sum(sel));
  data.time{k}  = tmp.time{1}(sel);
%   tmp = mous_db_getdata(subjectnames{k}, 'meg_processed_{bfICA_sourcedata475}');
%   data.trial{k} = cat(1, data.trial{k}, tmp.trial{1}-nanmean(tmp.trial{1},2)*ones(1,numel(tmp.time{1})));
end

source = mous_db_getdata(subjectnames{end}, 'meg_processed_{bfICA_source}');

Ncomp = 15;
Niter = 25;

cfg               = [];
cfg.method        = 'icasso';
cfg.icasso.method = 'fastica';
cfg.icasso.mode   = 'both';
cfg.icasso.Niter  = Niter;

cfg.fastica.lastEig       = Ncomp;
cfg.fastica.stabilization = 'on';
cfg.fastica.finetune      = 'tanh';
cfg.fastica.g             = 'tanh';
cfg.fastica.maxNumIterations = 2000;
cfg.fastica.approach      = 'defl';

comp = ft_componentanalysis(cfg, data);


% demean
dat  = cat(2,data.trial{:});
mdat = mean(dat,2);
for k = 1:size(dat,2)
  dat(:,k) = dat(:,k) - mdat;
end
vdat = sum(dat.^2,2);

% create correlation maps
C = zeros(size(comp.topo));
for k = 1:Ncomp
  cdat = comp.unmixing(k,:)*dat;
  cdat = cdat - mean(cdat);
  cdat = cdat./norm(cdat);
  C(:,k) = (dat*cdat')./sqrt(vdat);
end

% create output
comp.dim     = source.dim;
comp.inside  = source.inside;
comp.outside = source.outside;
comp.corrmap = C;

%X = icassoEst('both', dat, Niter, 'lastEig', Ncomp, 'stabilization', 'on', ...
%	      'finetune', 'tanh', 'g', 'tanh', 'maxNumIterations', 2000, 'approach', 'defl');
%X        = icassoExp(X);
%[Iq,A,W] = icassoShow(X);


%load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');
%
%cfgi = [];
%cfgi.parameter  = 'avg.pow';
%cfgi.downsample = 2;
%
%grid.avg.pow = zeros(prod(grid.dim),1);
%mri          = ft_read_mri('/home/language/jansch/matlab/mri/templateMRI.nii');
%for k = 1:size(a,2)
%  grid.avg.pow(grid.inside) = a(:,k);
%  i1(k) = ft_sourceinterpolate(cfgi, grid, mri);
%end
%
%
