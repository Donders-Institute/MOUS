function [h1,h2] = mous_artifact_qualitycheck(subjectname, artifact)
% MOUS_ARTIFACT_QUALITYCHECK does a quality control check on the
% ouput of the artifact pipeline, relying on visual inspection of a
% number of output figures, generated from the output from the dss artifact identification.
% JM & NL 2012-10-05
%
% Use as
%   mous_artifact_qualitycheck(subjectname)
%
% For example
%   mous_artifact_qualitycheck('V1020')
%
% See also MOUS_ARTIFACT_PIPELINE

% trl for trials (sent/seq)
filename    = mous_db_getfilename(subjectname, 'meg_raw_task'); 
trlSen      = mous_defineTrial(filename{1}, 0.5, 0.5, 'all','visual_sentence');  % entire sentence, with prestim and poststim = 0.5s 

%%%  Artifact info  %%%
cfgart      = mous_db_getdata(subjectname, 'meg_artifactcfg');

for m = 1:numel(cfgart)
    % trl for artifacts
    trlArt  = cfgart{m}.artfctdef.zvalue.artifact;
    artvec  = zeros(1,max(trlSen(:,2)));   % zero vector: each element is a sample within trial data

    % artifact specification for each trial
    for n = 1:size(trlArt,1)                   % for each artifact (each row in trlArt)
      artvec(1,trlArt(n,1):trlArt(n,2)) = n;   % mark which trial (number) has the same samples
    end

    % for each trial, tmpartvec stores location of trial in respect to artifact
    for k = 1:size(trlSen,1)  
      tmpartvec                     = artvec(1,trlSen(k,1):trlSen(k,2));          % each element (sample) in artifact vector that overlaps with a trial is marked e.g., [0 0 0 4 4 4 0 0 5 5 ...]
      % any()  % returns logical 1 if elements are nonzero / logical 1 (true), else returns logical 0.
      if any(tmpartvec)             % if there is a value in tmpartvec, it says that the artifact belongs to a trial
        diagnostics(k).okflag       = false;                                        % is an artifact 
        
        % get the index relating to the original artifact
        diagnostics(k).artifactindx = setdiff(unique(tmpartvec),0);                 % returns values in tmpartvec not in 0 vector 
        uniqueartvec = unique(tmpartvec);                                           % unique values in tmpartvec (there maybe multiples of the same trial number depending on how many samples trial+art extend)
        
        % get the number of samples in the artifacts
        for kk = 1:numel(uniqueartvec)-1
            diagnostics(k).artifactnsmp(kk) = sum(tmpartvec==uniqueartvec(kk+1));     % sample duration of each artifact (which may span >1 trial) 
        end
        
        % get the begin and endpoint of the artifact, expressed relative to
        % the trial
        for kk = 1:numel(uniqueartvec)-1
            diagnostics(k).artifact(kk,1) = find(diff([0 tmpartvec==uniqueartvec(kk+1)])==1);   
            diagnostics(k).artifact(kk,2) = find(diff([tmpartvec==uniqueartvec(kk+1) 0])==-1);
            % first value in uniqueartvec is always 1, there only need n-1 of the values 
            % tmpartvec gets the current artifact number e.g., 30
            % diff() calculates difference between consecutive elements where the former is subtracted from the latter 
            % [0 1] = 1 vs. [1 0] = -1          
            % find() gets index of first element in tmpartvec that is "1" (onset) or "-1" (offset)
        end
        
      else
        diagnostics(k).okflag       = true;   % is not an artifact
        diagnostics(k).artifactindx = [];
        diagnostics(k).artifactnsmp = [];
      end
    end
    
    % load relevant trial data for each type of artifact  
    cfg             = [];
    cfg.dataset     = filename{1};
    cfg.trl         = trlSen;
    cfg.continuous  = 'yes';
    
    if strcmp(cfgart{m}.varname, 'cfgeog1') > 0        % for blinks
        cfg.demean = 'yes';
        cfg.channel     = {'EEG058'};           
    elseif strcmp(cfgart{m}.varname, 'cfgeog2') > 0    % for saccades, maybe informative to include blink channel (sometimes affect saccades, and saccade detection doesn't seem that informative)
        cfg.demean = 'yes';
        cfg.channel     = {'EEG057'}; 
        % filter out blinks: bandstop filter [1 10]? Would this also removing saccades?
    else                                               % squid jumps or muscles
        cfg.channel     = {'MEG'};           
        if strcmp(cfgart{m}.varname, 'cfgmuscle') > 0  
            cfg.bpfilter = 'no';
            cfg.hilbert  = 'no';
            %cfg.rectify  = 'yes';
            cfg.hpfilter = 'yes';
            cfg.hpfreq   = 80;
            %cfg.demean     = 'yes';
            %cfg.boxcar     = 0.5;
            cfg.fltpadding = 0;
            cfg.trlpadding = 0;
            cfg.artpadding = 0;
        end 
    end 
    dataSen = ft_preprocessing(cfg);
    dataSen = ft_channelnormalise([], dataSen);                 % z-values
    
    vlim = [inf -inf];
        for k = 1:numel(dataSen.trial)
            dataSen.trial{k} = mean(dataSen.trial{k},1);        % single vector; average across channels

            vlim = [min(vlim(1),min(dataSen.trial{k})) max(vlim(2),max(dataSen.trial{k}))]; % min and max value 
            % get smallest and largest value across trials (compare newest min/max value with current min/max value
        end
    dataSen.label = {'MEGavg'};
  
    
    % plot trials and superimpose artifact           
    %for j = 1:size(diagnostics,2)
     for j = 1:25
        if mod(j,25) == 1                           % new figure for each set of 10 trials
            figure;
            hold on
            title([subjectname ': Trials ' num2str(j) ' to ' num2str(j+24)])
            axis on
        end
        hpos        = mod(j-1,5)*0.2;
        vpos        = 0.8 - floor((j-1)/5)*0.2;
        hlim        = dataSen.time{j}([1 end]);
        %vlim        = [min(dataSen.trial{j}(:)) max(dataSen.trial{j}(:))];
        trialFig    = ft_plot_vector(dataSen.time{j},dataSen.trial{j},'height', 0.18 ,'width', 0.18, 'hpos', hpos, 'vpos', vpos ,'color','k','hlim',hlim,'vlim',vlim);  % plot the trial
        if mod(j,25) == 1 
            hold on
            ft_plot_box([-0.08 -0.08 vlim(1) vlim(2)],'height', 0.18 ,'width', 0.18,'hlim',hlim,'vlim',vlim,'color','g');
        end
        ft_plot_text(hpos, vpos+0.07, num2str(j));
        artindx     = diagnostics(j).artifact;
        for jj = 1:size(artindx,1)
            ft_plot_vector(dataSen.time{j}(artindx(jj,1):artindx(jj,2)), dataSen.trial{j}(:,artindx(jj,1):artindx(jj,2)),'color','r','hpos',hpos,'vpos',vpos,'height',0.18,'width',0.18,'hlim',hlim,'vlim',vlim);
        end
     end
end 
saveas(gca,strcat('ArtQC',title.eps),'epsc2'); % convert into pdf
 % set size of figure to fit paper: http://www.parl.clemson.edu/~ahoover/Matlab-figures.txt
