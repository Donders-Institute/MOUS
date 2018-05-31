function stat = statfun_sophiessuperstatistic(cfg, dat, design)

% this computes some test statistic
newdesign = design;
newdesign(cfg.ivar,design(cfg.ivar,:)==1) = 1./sum(design(cfg.ivar,:)==1);
newdesign(cfg.ivar,design(cfg.ivar,:)==2) = -1./sum(design(cfg.ivar,:)==2);

stat.stat = dat*newdesign(cfg.ivar,:)';
