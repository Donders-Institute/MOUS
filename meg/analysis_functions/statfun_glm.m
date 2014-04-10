function [stat, cfg, dat] = statfun_glm(cfg, dat, design)

%this statfun does a regression of the design matrix on the data
%the design matrix/data are assumed to be well behaved, i.e. either
%the design contains a constant term, or the data is de-meaned

cfg.glm.contrast    = ft_getopt(cfg.glm, 'contrast',    []);
cfg.glm.statistic   = ft_getopt(cfg.glm, 'statistic',   'F');
cfg.glm.ivar0       = ft_getopt(cfg.glm, 'ivar0',       []);
cfg.glm.standardise = ft_getopt(cfg.glm, 'standardise', 1);
cfg.glm.demean      = ft_getopt(cfg.glm, 'demean',      0);
cfg.uvar            = ft_getopt(cfg.glm, 'uvar', []);
%FIXME why?

if ~isfield(cfg, 'preconditionflag'), cfg.preconditionflag = 0;          end

if cfg.preconditionflag,
  fprintf('removing the model from the data, updated data will be used for further computations\n');
  tmpcfg = cfg;
  tmpcfg.preconditionflag = 0;
  tmpcfg.glm.statistic    = 'beta';
  tmpcfg.glm.standardise  = 0;
  tmpstat = statfun_glm(tmpcfg, dat, design);
  
  dat = dat - tmpstat.stat*design;
end

[nvox, nobs] = size(dat);

%FIXME do preconditioning on this to speed up randomizations
if cfg.glm.standardise,
  %fprintf('standardising dependent variable to facilitate computations\n');
  dat = nanstandardise(dat,2);
%   for k = 1:size(design,1)
%     if ~all(design(k,:)==design(k,1))
%       design(k,:) = nanstandardise(design(k,:),2);
%     end
%   end
end
if cfg.glm.demean
  %fprintf('removing grand mean\n');
  mu  = nanmean(dat,2);
  dat = dat - mu*ones(1,nobs);
end
dat     = dat./sqrt(nobs);
design  = design./sqrt(nobs);

if strcmp(cfg.glm.statistic, 'T') && ~isempty(cfg.glm.contrast),
  doTval    = 1;
  doF    = 0;
  dobeta = 0;
  lambda = cfg.glm.contrast;
elseif strcmp(cfg.glm.statistic, 'F'), 
  doTval    = 0;
  doF    = 1;
  dobeta = 0;
  ivar0  = cfg.glm.ivar0;
elseif strcmp(cfg.glm.statistic,'beta'),
  doTval    = 0;
  doF    = 0;
  dobeta = 1;
  lambda = cfg.glm.contrast;
end


%core business
cdx     = design*design';
condcdx = cond(cdx);

tmpdot = design*dat'; %dot product of full model
if condcdx>1e8
  invcdx = pinv(cdx);
  beta   = invcdx*tmpdot; %betas for full model
else
  beta   = cdx\tmpdot;
end
R      = 1-sum((beta'*design).^2,2)'; % this only works if the dependent variable has been standardised

if doTval,
  if condcdx>1e8
    denom = lambda*invcdx*lambda';
  else
    denom = lambda/cdx*lambda';
  end
  T     = (lambda*beta)./sqrt(denom.*R./(nobs-2));
  stat.stat = T(:);
end

if doF,
  if ~isempty(cfg.glm.ivar0),
    dx = design(cfg.glm.ivar0,:);

    nx = size(dx,1);
    invcdxR = inv(dx*dx'); %inverse covariance of design of reduced model
    tmpdotR = dx*dat';     %dot product of reduced model
    betaR   = invcdxR*tmpdotR; %betas of reduced model
    Rred    = 1-sum([betaR'*dx].^2,2)';
    F       = ((Rred-R)./nx)./(R./(nobs-nx-2));
  else
    error('don''t know what to do ... yet');
  end
  stat.stat = F(:);
end

if dobeta,
  if isempty(lambda)
    b = beta;
  else
    b = lambda*beta;
  end
  stat.stat = b(:);
end
