function varargout = mous_makecontrast(data, contrast, trialinfo, M, rseed, condition)

% MOUS_MAKECONTRAST extracts the average across observations for a specific
% set of defined conditions, or computes the slope parameter of the linear
% fit across words
%
% Input arguments:
%   data      = data structure, type raw or freq
%   contrast  = string defining the contrast
%   trialinfo = NxM matrix with trial specific information
%   M         = optional matrix, that is left multiplied with the data
%                 matrix, e.g. minimum norm spatial filter
%   rseed     = options value: seed that defines the randomly selected trials per subject 
%
% data.trialinfo is assumed to be defined as:
%  column 1: sentence index
%  column 2: word index
%  column 3: condition trigger
%
% if trialinfo is specified, this takes prevalence (first column is
% condition)
%
% defined contrasts are:
%   sent-seq          = sentence versus word list, all words in the data
%   sent-seqTarget    = sentence versus word list, target words
%   sent-seqFirstword = sentence versus word list, first word
%   sentMX-sentRC     = sentence 'mixed clauses' versus Relative Clauses
%   early-late        = beginning vs. end of sentence (or word list)
%   deplong-depshort  = verb in RC with a long dependency to subject in  main clause vs.  verb with short dependency
%   RCearlylate-MXearlylate = Word position by Complexity

% defined slope parameter estimates are
%   wordsent_parametric     = sentence 
%   wordsent_parametric_blc = sentence, with subtraction of slope in baseline
%   wordseq_parametric
%   wordseq_parametric_blc
%   wordsenttar_parametric
%   wordsenttar_parametric_blc
%   wordseqtar_parametric
%   wordseqtar_parametric_blc

% sentence trigger values: 1 2 5 6
% sequence trigger values: 3 4 7 8

%%%%%%%%%%%%
% CONTRASTS 
%%%%%%%%%%%%
switch contrast
  case {'sent-seq', 'sent-seqTarget', 'sentMX-sentRC','sent-seqFirstword','early-late',...
        'RCend-RCafter', 'RCearlylate-MXearlylate','RConset-RCoffset', 'subjMC-verbRC','RC_deplong-depshort'}
    
    %if  nargin<3  
        % need extra input arguments to differentiate between VIS and AUD
        % could try to infer from trialinfo i.e. VIS has all words present but
        % AUD doesn't (given triggers). However, we may soon update the
        % trialinfo with info from logfile, so subjectname is most reliable
     
    if nargin<4 || (nargin>4 && isempty(trialinfo)) % only applies contrast specified in first line
      T = data.trialinfo(:,3);
    else
      T = trialinfo(:,1); 
    end
    
    % decode the trialinfo field to make a selection of trials per 
    % sub condition
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CONTRASTS THAT REQUIRE MATCHING 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch contrast
      case 'sent-seq'
        sel1 = find(ismember(T,[1 2 5 6]));
        sel2 = find(ismember(T,[3 4 7 8]));
      case 'sent-seqTarget'
        sel1 = find(ismember(T,[2 6]));
        sel2 = find(ismember(T,[4 8]));      
      case 'sent-seqFirstword'    
        sel1 = find(ismember(T,[1 5]) & data.trialinfo(:,2) == 1); 
        sel2 = find(ismember(T,[3 7]) & data.trialinfo(:,2) == 1);   
      case 'sentMX-sentRC'
        sel1 = find(ismember(T,[5 6]));  % MIX
        sel2 = find(ismember(T,[1 2]));  % RC
      case 'early-late' 
        % take words 2 to 4 and n-3 to n-1: NOTE this only works
        % for visual subjects. Assume trialinfo organized as:
        % sentence, ordinal word, condition, total number of words
        sel1 = find(ismember(data.trialinfo(:,2),[2 3 4]));                     % early
        sel2 = find(ismember(data.trialinfo(:,4)-data.trialinfo(:,2),[1 2 3])); % late
    end
    
    % balance trials if not involving a contrast between RC/MX
    % if <numel(...)> goes first, then this statement cannot be executed
    if ((strcmp(contrast,'sent-seq')) || (strcmp(contrast,'sent-seqTarget')) ||...
       (strcmp(contrast,'sent-seqFirstword')) || (strcmp(contrast,'sentMX-sentRC')) ||...
       (strcmp(contrast,'early-late'))) && numel(sel1)~=numel(sel2);                           
        n1   = numel(sel1);
        n2   = numel(sel2);
        n    = min(n1,n2);
        x1   = randperm(n1);

        x2   = randperm(n2);
        sel1 = sel1(sort(x1(1:n)));
        sel2 = sel2(sort(x2(1:n)));    
    end 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
    % CONTRASTS MATCHED INSIDE SPECIFIC FUNCTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch contrast
      case 'RCearlylate-MXearlylate'
        if isempty(rseed), error('you must have a randomseed');  end
        trialinfo = data.trialinfo;
        [sel1, sel2, sel3, sel4]  =mous_wrdpstncomplexity(trialinfo,condition, rseed); % condition = 'sent' or 'wl'
      case 'subjMC-verbRC'
        if isempty(rseed), error('you must have a randomseed');  end
        %subjMC, verbRC in RC+ sentences (sel1 sel2)
        %               in RC- sentences (sel3 sel4)
        %               in RC+ word list (sel5 sel6)
        [sel1, sel2, sel3, sel4, sel5, sel6] = mous_subjMCvsverbRC(data,rseed);  
        
%       case 'RC_deplong-depshort'
%         [sel1, sel2]  = mous_dependencyshortvslong(data);        
%       case 'RConset-RCoffset'
%         if isempty(rseed), error('you must have a randomseed');  end
%         [sel1, sel2]  = mous_RCMXbalanced_RConoffset(data, toilop, 'RConoff');
%       case 'RCend-RCafter'
%         if isempty(rseed), error('you must have a randomseed');  end
%         % use another function for the definition of trials
%         [sel1, sel2, sel3, sel4] = mous_RCendvsafter(data, T);
    end 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % select and average for contrasts
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    switch ft_datatype(data)
      case 'raw'
        cfg              = [];
        cfg.vartrllength = 2;
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

          if strcmp(contrast,'RCend-RCafter') || strcmp(contrast,'RCearlylate-MXearlylate') ||...
             strcmp(contrast,'RConset-RCoffset') || strcmp(contrast,'subjMC-verbRC')
            cfg.trials = sel3;
            tlck3      = ft_timelockanalysis(cfg,data);
            cfg.trials = sel4;
            tlck4      = ft_timelockanalysis(cfg,data);
            varargout{3} = tlck3;  % overwrite initial varargout{3} value
            varargout{4} = tlck4;   

            varargout{5} = Tstat;
            dat1 = cat(2,data.trial{sel3});
            dat2 = cat(2,data.trial{sel4});
            Tstat = yuent(dat1,dat2,0.2,2);
            varargout{6} = Tstat;
            
            if strcmp(contrast,'subjMC-verbRC')
              % N.B. not calculating Tstat
              cfg.trials = sel5;
              tlck5      = ft_timelockanalysis(cfg,data);
              cfg.trials = sel6;
              tlck6      = ft_timelockanalysis(cfg,data);
              varargout{5} = tlck5;
              varargout{6} = tlck6;
            end 
          end
        end

      case 'freq'

        % convert to planar gradient representation
        cfg        = [];
        cfg.method = 'distance';
        neighbours = ft_prepare_neighbours(cfg, data);

        cfg              = [];
        cfg.planarmethod = 'sincos';
        cfg.neighbours   = neighbours;
        data             = ft_megplanar(cfg, data);

        % I understand the rationale for the below snippet
        % of code, but I wonder about it's necessity 
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

        cfg        = [];
        cfg.trials = sel1;
        freq1      = ft_freqdescriptives(cfg, data);
        cfg.trials = sel2;
        freq2      = ft_freqdescriptives(cfg, data);

        % combine planar gradients
        freq1 = ft_combineplanar([],freq1);
        freq2 = ft_combineplanar([],freq2);

        varargout{1} = freq1;
        varargout{2} = freq2;
      otherwise
    end  % calculation for contrasts

  case {'wordsent_parametric', 'wordsent_parametric_blc', 'wordseq_parametric', 'wordseq_parametric_blc',...
      'wordsent_rc_parametric_blc', 'wordsent_mix_parametric_blc', 'wordseq_rc_parametric_blc', 'wordseq_mix_parametric_blc',...
      'wordsent_rc_parametric', 'wordsent_mix_parametric', 'wordseq_rc_parametric', 'wordseq_mix_parametric',...
      'wordsenttar_parametric', 'wordseqtar_parametric', 'wordsenttar_parametric_blc', 'wordseqtar_parametric_blc'};

    switch ft_datatype(data)
      case 'timelock'
        % assume that the input data has a field, called trial, that
        % contains the averages per word
        tlck = data;
        tmp  = tlck;
        
      otherwise
        % assume single 'trial' data, i.e. an estimate per word
        Xcond = data.trialinfo(:,3);
        switch contrast
          case {'wordsent_parametric' 'wordsent_parametric_blc'}
            sel   = find(ismember(Xcond,[1 2 5 6]));
          case {'wordseq_parametric' 'wordseq_parametric_blc'}
            sel   = find(ismember(Xcond,[3 4 7 8]));
          case {'wordsenttar_parametric' 'wordsenttar_parametric_blc'}
            sel   = find(ismember(Xcond,[2 6]));
          case {'wordseqtar_parametric' 'wordseqtar_parametric_blc'}
            sel   = find(ismember(Xcond,[4 8]));
          case {'wordsent_rc_parametric' 'wordsent_rc_parametric_blc'}
            sel   = find(ismember(Xcond,[5 6]));
          case {'wordseq_rc_parametric' 'wordseq_rc_parametric_blc'}
            sel   = find(ismember(Xcond,[7 8]));    
          case {'wordsent_mix_parametric' 'wordsent_mix_parametric_blc'}
            sel   = find(ismember(Xcond,[1 2]));
          case {'wordseq_mix_parametric' 'wordseq_mix_parametric_blc'}
            sel   = find(ismember(Xcond,[3 4]));
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
          elseif uXword(k)<13
            tlck.trial(uXword(k),:,1:size(tmp.avg,2))  = tmp.avg;
            tlck.time(1:size(tmp.avg,2))       = tmp.time;
            tlck.trial2(uXword(k),:,1:size(tmp.avg,2)) = tmp.dof(1,:);
          end
        end
        if size(tlck.trial,1)<15, tlck.trial((end+1):15,:,:) = nan; tlck.trial2((end+1):15,:,:) = nan; end
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
    end
    
    % fit glm (for parametric contrasts)
    cfg                 = [];
    cfg.design          = (1:size(tmp.trial,1))-mean(1:size(tmp.trial,1)); % zero mean
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
