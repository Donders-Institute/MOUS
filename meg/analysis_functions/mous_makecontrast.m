function varargout = mous_makecontrast(data, contrast, trialinfo)

% data.trialinfo:
%  column 1: sentence index
%  column 2: word index
%  column 3: condition trigger
%
% if trialinfo is specified, this takes prevalence (first column is
% condition)


% sentence trigger values: 1 2 5 6
% sequence trigger values: 3 4 7 8

switch contrast
  case {'sent-seq', 'sent-seqTarget', 'sent1-sent2'}
    if nargin<3
      T = data.trialinfo(:,3);
    else 
      T = trialinfo(:,1);
    end
    
    cfg              = [];
    cfg.vartrllength = 2;

    if strcmp(contrast, 'sent-seq')
      sel1 = find(ismember(T,[1 2 5 6]));
      sel2 = find(ismember(T,[3 4 7 8]));
    elseif strcmp(contrast, 'sent-seqTarget')
      sel1 = find(ismember(T,[2 6]));
      sel2 = find(ismember(T,[4 8]));      
    elseif strcmp(contrast, 'sent1-sent2')
      sel1 = find(ismember(T,[1 2]));
      sel2 = find(ismember(T,[5 6]));
    end
    
    if numel(sel1)~=numel(sel2)
      n1=numel(sel1);
      n2=numel(sel2);
      n=min(n1,n2);
      x1=randperm(n1);
      x2=randperm(n2);
      sel1=sel1(sort(x1(1:n)));
      sel2=sel2(sort(x2(1:n)));
    end
    
    
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
    switch ft_datatype(data)
      case 'raw'
        cfg.trials = sel1
        tlck1      = ft_timelockanalysis(cfg, data);
        cfg.trials = sel2;
        tlck2      = ft_timelockanalysis(cfg, data);
        
        varargout{1} = tlck1;
        varargout{2} = tlck2;
        
        if all(cellfun('size',data.time,2)==1)
          % compute T contrast, too
          dat1 = cat(2,data.trial{sel1});
          dat2 = cat(2,data.trial{sel2});
          Tstat = yuent(dat1,dat2,0.2,2);
          varargout{3} = Tstat;
        end
      case 'freq'
        % convert to planar
        cfg = [];
        cfg.method = 'distance';
        neighbours = ft_prepare_neighbours(cfg, data);
        cfg = [];
        cfg.planarmethod = 'sincos';
        cfg.neighbours   = neighbours;
        data             = ft_megplanar(cfg, data);
        
        if any(data.freq>=50)
          cfg = [];
          cfg.frequency  = [49 51];
          tmp = ft_selectdata(cfg, data);
          cfg = [];
          cfg.keeptrials = 'yes';
          tmp = ft_freqdescriptives(cfg, tmp);
          tmp = ft_combineplanar([], tmp);
          tmp = standardise(max(tmp.powspctrm,[],2));
          exclude = find(tmp>3); % more than 3 std bigger than average
          sel1    = setdiff(sel1,exclude);
          sel2    = setdiff(sel2,exclude);
        end
        
        cfg = [];
        cfg.trials = sel1;
        freq1      = ft_freqdescriptives(cfg, data);
        cfg.trials = sel2;
        freq2      = ft_freqdescriptives(cfg, data);
        
        % combine planar
        freq1 = ft_combineplanar([],freq1);
        freq2 = ft_combineplanar([],freq2);
        
        varargout{1} = freq1;
        varargout{2} = freq2;
      otherwise
    end
    
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
