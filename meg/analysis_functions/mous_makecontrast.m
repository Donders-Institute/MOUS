function varargout = mous_makecontrast(data, contrast)

% data.trialinfo:
%  column 1: sentence index
%  column 2: word index
%  column 3: condition trigger

% sentence trigger values: 1 2 5 6
% sequence trigger values: 3 4 7 8

switch contrast
  case 'sent-seq'
    T = data.trialinfo(:,3);
    
    cfg              = [];
    cfg.vartrllength = 2;

    sel1 = find(ismember(T,[1 2 5 6]));
    sel2 = find(ismember(T,[3 4 7 8]));
    
%     n1 = numel(sel1);
%     n2 = numel(sel2);
%     
%     if n1>n2
%       tmp = randperm(n1);
%       sel1 = sort(tmp(1:n2));
%     else
%       tmp = randperm(n2);
%       sel2 = sort(tmp(1:n1));
%     end
    
    cfg.trials = sel1
    tlck1      = ft_timelockanalysis(cfg, data);
    cfg.trials = sel2;
    tlck2      = ft_timelockanalysis(cfg, data);
    
    varargout{1} = tlck1;
    varargout{2} = tlck2;
  case 'wordsent_parametric'
    Xcond = data.trialinfo(:,3);
    sel   = find(ismember(Xcond,[1 2 5 6]));
  
    data  = ft_selectdata(data, 'rpt', sel);
    Xword = data.trialinfo(:,2);
    
    cfg              = [];
    cfg.vartrllength = 2;
    
    uXword = unique(Xword);
    for k = 1:numel(uXword)
      sel = find(Xword==uXword(k));
      cfg.trials   = sel;
      tmp          = ft_timelockanalysis(cfg, data);
      if k==1
        tlck = tmp;
        tlck.trial  = shiftdim(tlck.avg,-1);
        tlck.trial2 = shiftdim(tlck.dof,-1); %!!!! keep track of the dof
      else
        tlck.trial(k,:,1:size(tmp.avg,2))  = tmp.avg;
        tlck.time(1:size(tmp.avg,2))       = tmp.time;
        tlck.trial2(k,:,1:size(tmp.avg,2)) = tmp.dof;
      end
    end
    tlck.dimord = 'rpt_chan_time';
      
    tmp       = tlck;
    tmp.trial = tmp.trial(2:10,:,:); % use only the first 10 words
      
    % fit glm
    cfg                 = [];
    cfg.design          = -4:4; % zero mean
    cfg.statistic       = 'glm';
    cfg.glm.statistic   = 'beta';
    cfg.glm.standardise = 0;
    cfg.glm.demean      = 1;
    cfg.method          = 'montecarlo';
    cfg.numrandomization = 0;
    stat                = ft_timelockstatistics(cfg, tmp);
    
    tmp.trial = nanmean(tmp.trial,3);
    tmp.time  = mean(tmp.time);
    stat2     = ft_timelockstatistics(cfg, tmp);
    
    varargout{1} = tlck;
    varargout{2} = stat;
    varargout{3} = stat2;

  case 'wordseq_parametric'
    Xcond = data.trialinfo(:,3);
    sel   = find(ismember(Xcond,[3 4 7 8]));
  
    data  = ft_selectdata(data, 'rpt', sel);
    Xword = data.trialinfo(:,2);
    
    cfg              = [];
    cfg.vartrllength = 2;
    
    uXword = unique(Xword);
    for k = 1:numel(uXword)
      sel = find(Xword==uXword(k));
      cfg.trials   = sel;
      tmp          = ft_timelockanalysis(cfg, data);
      if k==1
        tlck = tmp;
        tlck.trial  = shiftdim(tlck.avg,-1);
        tlck.trial2 = shiftdim(tlck.dof,-1); %!!!! keep track of the dof
      else
        tlck.trial(k,:,1:size(tmp.avg,2))  = tmp.avg;
        tlck.time(1:size(tmp.avg,2))       = tmp.time;
        tlck.trial2(k,:,1:size(tmp.avg,2)) = tmp.dof;
      end
    end
    tlck.dimord = 'rpt_chan_time';
      
    tmp       = tlck;
    tmp.trial = tmp.trial(2:10,:,:); % use only the first 10 words
      
    % fit glm
    cfg                 = [];
    cfg.design          = 2:10;
    cfg.statistic       = 'glm';
    cfg.glm.statistic   = 'beta';
    cfg.glm.standardise = 0;
    cfg.glm.demean      = 1;
    cfg.method          = 'montecarlo';
    cfg.numrandomization = 0;
    stat                = ft_timelockstatistics(cfg, tmp);
    
    tmp.trial = nanmean(tmp.trial,3);
    tmp.time  = mean(tmp.time);
    stat2     = ft_timelockstatistics(cfg, tmp);
    
    varargout{1} = tlck;
    varargout{2} = stat;
    varargout{3} = stat2;
    
  otherwise
end
