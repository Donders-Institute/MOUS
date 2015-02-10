function [datgrp] = mous_neuralspeechcoherence_grpavg(subj, data, rootdir)

dat = cell(1,numel(subj));
for k = 1:numel(subj)
  mous_db_getdata(subj{k},data,rootdir);
  sentcoh.label = sentcoh.labelcmb(:,1);
  dat{k} = sentcoh;
end

% append data
% each additional subject is added as a new 'rpt'
% rpt is a dimension in the data
cfg           = [];
cfg.parameter = 'cohspctrm';
cfg.appenddim = 'rpt';      % fool ft_app
datgrp  = ft_appendfreq(cfg,dat{:});

% average data using ft_selectdata
cfg            = [];
cfg.avgoverrpt = 'yes';
datgrp         = ft_selectdata(cfg,datgrp);

