function [datgrp] = mous_neuralspeechcoherence_grpavg(subj, data, rootdir)

dat = cell(1,numel(subj));
for k = 1:numel(subj)
  mous_db_getdata(subj{k},data,rootdir);
  sentcoh.label = sentcoh.labelcmb(:,1);
  dat{k} = sentcoh;
end

 % append data
cfg           = [];
cfg.parameter = 'cohspctrm';
cfg.appenddim = 'rpt';      % fool ft_app
datgrp  = ft_appendfreq(cfg,dat{:});

% average data
cfg            = [];
cfg.avgoverrpt = 'yes';
datgrp         = ft_selectdata(cfg,datgrp);


%% old code
%   if k == 1
%     datgrp = dat;
%   else
%     cfg           = [];
%     cfg.parameter = 'cohspctrm';
%     cfg.appenddim = 'rpt';      % fool ft_appendfreq, need to fix checkchan
%     datgrp        = ft_appendfreq(cfg,dat,datgrp);
%   end
      
% datgrp.cohspctrm = datgrp.cohspctrm./numel(subj);
% notavg  = cell(1,102);
% numchan = zeros(1,102);
% label   = cell(1,102);

%   if size(dat.cohspctrm,1) == 273
%   else
%     notavg{k}  = subj{k};
%     numchan(k) = size(dat.cohspctrm,1);
%     label{k}   = setdiff(dat.labelcmb(:,1),datgrp.labelcmb(:,1));
%   end