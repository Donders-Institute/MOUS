function varargout = mous_makecontrast(data, contrast, trialinfo, M)

% MOUS_MAKECONTRAST extracts the average across observations for a specific
% set of defined conditions.
%
% Input arguments:
%   data      = data structure, type raw or freq
%   contrast  = string defining the contrast
%   trialinfo = NxM matrix with trial specific information
%   M         = optional matrix, that is left multiplied with the data
%                 matrix, e.g. minimum norm spatial filter
%
% data.trialinfo is assumed to be defined as:
%  column 1: sentence index
%  column 2: word index
%  column 3: condition trigger
%
% if trialinfo is specified, this takes prevalence (first column is
% condition)
%
% supprted contrasts are:
%   sent-seq = sentence versus word list, all words in the data
%   sent-seqTarget = sentence versus word list, target words
%   sent-seqFirstword = sentence versus word list, first word
%   sentMX-sentRC = sentence 'mixed clauses' versus Relative Clauses
%   early-late    = beginning vs. end of sentence (or word list)
%   comb-bsl      = sent+seq vs. baseline
%
%   wordsent_parametric
%   wordsent_parametric_blc
%   wordseq_parametric
%   wordseq_parametric_blc
%   wordsenttar_parametric
%   wordsenttar_parametric_blc
%   wordseqtar_parametric
%   wordseqtar_parametric_blc

% sentence trigger values: 1 2 5 6
% sequence trigger values: 3 4 7 8

switch contrast
  case {'sent-seq', 'sent-seqTarget', 'sentMX-sentRC','sent-seqFirstword','early-late'}
    %if  nargin<3  
    % need extra input arguments to differentiate between VIS and AUD
    % could try to infer from trialinfo i.e. VIS has all words present but
    % AUD doesn't (given triggers). However, we may soon update the
    % trialinfo with info from logfile, so subjectname is most reliable
    if nargin<4
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
    elseif strcmp(contrast, 'sent-seqFirstword')
      sel1 = find(ismember(T,[1 5]) & data.trialinfo(:,2) == 1); 
      sel2 = find(ismember(T,[3 7]) & data.trialinfo(:,2) == 1);   
    elseif strcmp(contrast, 'sentMX-sentRC')
      sel1 = find(ismember(T,[1 2]));  % RC
      sel2 = find(ismember(T,[5 6]));  % MIX
    elseif strcmp(contrast, 'early-late')
      % take words 2 to 4 and n-3 to n-1: NOTE this only works
      % for visual subjects. it assumes the trialinfo field in data to be
      % organized as: sentence, ordinal word, condition, total number of
      % words
      
      % early
      sel1 = find(ismember(data.trialinfo(:,2),[2 3 4]));
      
      % late
      sel2 = find(ismember(data.trialinfo(:,4)-data.trialinfo(:,2),[1 2 3]));
    end
    
    if numel(sel1)~=numel(sel2) % balance numtrials btw sent and seq
      n1=numel(sel1);
      n2=numel(sel2);
      n=min(n1,n2);
      x1=randperm(n1);
      x2=randperm(n2);
      sel1=sel1(sort(x1(1:n)));
      sel2=sel2(sort(x2(1:n)));
    end
    
    switch ft_datatype(data)
      case 'raw'
        cfg.trials = sel1;
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
%           cfg = [];
%           cfg.frequency  = [49 51];
          tmp = ft_selectdata(data,'foilim',[49 51]);
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
    
  case {'wordsent_parametric' 'wordsent_parametric_blc' 'wordseq_parametric' 'wordseq_parametric_blc','wordsenttar_parametric','wordseqtar_parametric','wordsenttar_parametric_blc','wordseqtar_parametric_blc',}
    Xcond = data.trialinfo(:,3);
    if regexp(contrast,    'wordsent_para')  % regexp = parametric(_blc)
      sel   = find(ismember(Xcond,[1 2 5 6]));  
    elseif regexp(contrast,'wordseq_para')   
      sel   = find(ismember(Xcond,[3 4 7 8]));  
    elseif regexp(contrast,'wordsenttar_para')  
      sel   = find(ismember(Xcond,[2 6]));
    elseif regexp(contrast,'wordseqtar_para')
      sel   = find(ismember(Xcond,[4 8]));
    end
    
    data  = ft_selectdata(data, 'rpt', sel);
    Xword = data.trialinfo(:,2);
    
    cfg              = [];
    cfg.vartrllength = 2;
    %if strcmp(contrast, 'wordsent_parametric_blc') || strcmp(contrast, 'wordseq_parametric_blc')
    if regexp(contrast, 'blc')  % generalised for any kind of baseline subtraction
      cfg.preproc.baselinewindow = [-inf 0];
      cfg.preproc.demean         = 'yes';
    end
    
    uXword = unique(Xword);
    for k = 1:numel(uXword)
      sel = find(Xword==uXword(k));
      cfg.trials   = sel;
      tmp          = ft_timelockanalysis(cfg, data);
      if k==1
        tlck = tmp;
        tlck.trial  = shiftdim(tlck.avg,-1);
        tlck.trial2 = shiftdim(tlck.dof(1,:),-1); %!!!! keep track of the dof
      else
        tlck.trial(uXword(k),:,1:size(tmp.avg,2))  = tmp.avg;
        tlck.time(1:size(tmp.avg,2))       = tmp.time;
        tlck.trial2(uXword(k),:,1:size(tmp.avg,2)) = tmp.dof(1,:);
      end
    end
    if k<15, tlck.trial((k+1):15,:,:) = nan; tlck.trial2((k+1):15,:,:) = nan; end
    tlck.dimord = 'rpt_chan_time';
      
    if ft_senstype(tlck, 'ctf275_planar')
      tmp = ft_combineplanar([], tlck);
    else
      tmp = tlck;
    end
    tmp.trial = tmp.trial(2:10,:,:); % use only the first 10 words
    
    if exist('M', 'var')
      % M is assumed to be a projection matrix, e.g. a spatial filter
      selchan = match_str(tmp.label, ft_channelselection('MEG', tmp.label));
      siz     = size(tmp.trial);
      tmpdat  = reshape(permute(tmp.trial, [2 1 3]), [siz(2) siz(1)*siz(3)]);
      tmpdat  = M*tmpdat(selchan,:);
      tmpdat  = ipermute(reshape(tmpdat, [size(M,1) siz(1) siz(3)]), [2 1 3]);
      tmp.trial = abs(tmpdat);
      
      tmp.label = cell(size(M,1),1);
      for k = 1:size(M,1)
        tmp.label{k} = ['chan',num2str(k,'%04d')];
      end
      
      % do a baseline correction (again) if requested
      if regexp(contrast, 'blc')  % generalised for any kind of baseline subtraction
        sel = nearest(tmp.time, 0);
        tmp.trial = tmp.trial - repmat(mean(tmp.trial(:,:,1:sel),3),[1 1 size(tmp.trial,3)]);
      end
    end
    
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
    
    % added 20131122: also output the average across words, this allows to
    % model the word-specific response later on
    mu = squeeze(nanmean(tmp.trial));
    
    tmp.trial = nanmean(tmp.trial,3);
    tmp.time  = nanmean(tmp.time);
    stat2     = ft_timelockstatistics(cfg, tmp);
    
    varargout{1} = tlck;
    varargout{2} = stat;
    varargout{3} = stat2;
    varargout{4} = mu;
  otherwise
end
