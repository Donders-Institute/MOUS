%function [h1] = mous_qualitycheck_artifact(subjectname, artifactType)
function [h1] = mous_qualitycheck_artifact(subjectname)
% MOUS_ARTIFACT_QUALITYCHECK does a quality control check on the
% ouput of the artifact pipeline, relying on visual inspection of a
% number of output figures, generated from the output from the dss artifact identification.
% JM & NL 2012-10-05
%
% Use as
%   mous_qualitycheck_artifact(subjectname)
%
% For example
%   mous_qualitycheck_artifact('V1020')
%
% See also MOUS_ARTIFACT_PIPELINE

%% Setup
% default
doblink = true;
dosacc  = true;
dojump  = true;
domusc  = true; 

% doblink = false;
% dosacc  = false;
% dojump  = false;
% domusc  = true; 

% just for one artifact
% switch artifactType
%     case 'all'
%         % all remain true
%     case 'blink' 
%         dosacc = false; dojump = false; domusc = false;
%     case 'sacc'
%         doblink = false; dojump = false; domusc = false;
%     case 'jump'
%         doblink = false; dosacc = false; domusc = false;
%     case 'musc'
%         doblink = false; dosacc = false; dojump = false;
% end 

%% general data need for all artifacts
% load filename and trial(sent/seq) trl
filename    = mous_db_getfilename(subjectname, 'meg_raw_task'); 
trlDat      = mous_defineTrial(filename{1}, 0.5, 0.5, 'all','visual_sentence');  % entire sentence, with prestim and poststim = 0.5s 
cfgart      = mous_db_getdata(subjectname, 'meg_artifact_cfg');  
% cfg info for preprocessing trial data
    cfg             = [];
    cfg.dataset     = filename{1};
    cfg.continuous  = 'yes';
    
%% artifact specific info     
if doblink 
    artType         = 1;
    cfg.trl         = trlDat;
    cfg.demean      = 'yes';
    cfg.channel     = {'EEG058'};
    plotPerPage     = 60;
    artifactName    = 'blink';
    figH            = 0.9;                  % figure height
    loop            = 1;                    % redundant for blinks and sacc, but necessary for jump/musc to prevent memory error

    [diagnostics]   = getDiagnostics(cfgart, trlDat, artType);
    [dataSen, vlim] = preprocData(cfg);
    superimpose(diagnostics,vlim,dataSen,plotPerPage, artifactName, figH, trlDat, loop);
end %doblink

if dosacc 
    artType         = 2;
    cfg.trl         = trlDat;
    cfg.demean      = 'yes';
    cfg.channel     = {'EEG057'};             
    plotPerPage     = 60;
    artifactName    = 'sacc';
    figH            = 0.9;
    loop            = 1;
    
    [diagnostics]   = getDiagnostics(cfgart, trlDat, artType);
    [dataSen, vlim] = preprocData(cfg);
    superimpose(diagnostics,vlim,dataSen, plotPerPage, artifactName, figH, trlDat, loop);
end % dosacc

if dojump
    artType         = 3;
    cfg.channel     = {'MEG'};
    cfg.hpfilter    = 'yes';
    cfg.hpfreq      = 1;
    cfg.hpfiltord   = 4;
    plotPerPage     = 30;
    artifactName    = 'jump';
    figH            = 1.1;
    
    for i = 1:2
        if i == 1
            cfg.trl = trlDat(1:120,:);
              loop    = i;
        elseif i == 2
            cfg.trl = trlDat(121:240,:);
            loop    = i;
        end 
        [diagnostics]   = getDiagnostics(cfgart, cfg.trl, artType);
        [dataSen, vlim] = preprocData(cfg);
        superimpose(diagnostics, vlim, dataSen, plotPerPage, artifactName, figH, cfg.trl, loop);
    end % loop through first and second half of data set
end % end dojump
    
if domusc
    artType         = 4;
    cfg.channel     = {'MEG'};           
    cfg.bpfilter    = 'no';
    cfg.hilbert     = 'no';
    cfg.hpfilter    = 'yes';
    cfg.hpfreq      = 80;
    cfg.fltpadding  = 0;
    cfg.trlpadding  = 0;
    cfg.artpadding  = 0;
    plotPerPage     = 30;
    artifactName    = 'musc';
    figH            = 1.1;
    
    for i = 1:2
        if i == 1
            cfg.trl = trlDat(1:120,:);
            loop    = i;
        elseif i == 2 
            cfg.trl = trlDat(121:240,:);
            loop    = i;
        end 
        [diagnostics]   = getDiagnostics(cfgart, cfg.trl, artType);
        [dataSen, vlim] = preprocData(cfg);
        superimpose(diagnostics, vlim, dataSen, plotPerPage, artifactName, figH, cfg.trl, loop);
    end
end  % end domusc


%% get diagnostics
%%%%%%%%%% Subfunction %%%%%%%%%%%%%%%%%
function [diagnostics] = getDiagnostics(cfgart, trlSen, artType)

    % trl for artifacts
    trlArt  = cfgart{artType}.artfctdef.zvalue.artifact;
    artvec  = zeros(1,max(trlSen(:,2)));   % zero vector: each element is a sample within trial data

    % artifact specification for each trial
    for n = 1:size(trlArt,1)                   % for each artifact (each row in trlArt)
      artvec(1,trlArt(n,1):trlArt(n,2)) = n;   % mark which trial (number) has the same samples
    end

    % for each trial, tmpartvec stores location of trial in respect to artifact
    for k = 1:size(trlSen,1)  
      tmpartvec                     = artvec(1,trlSen(k,1):trlSen(k,2));          % each element (sample) in artifact vector that overlaps with a trial is marked e.g., [0 0 0 4 4 4 0 0 5 5 ...]
      if any(tmpartvec)                                                           % if there is a value in tmpartvec, it says that the artifact belongs to a trial
            diagnostics(k).okflag       = false;                                        % is an artifact 

            % get the index relating to the original artifact
            diagnostics(k).artifactindx = setdiff(unique(tmpartvec),0);                 % returns values in tmpartvec not in 0 vector 
            uniqueartvec = unique(tmpartvec);                                           % unique values in tmpartvec (there maybe multiples of the same trial number depending on how many samples trial+art extend)

            % get the number of samples in the artifacts
            for kk = 1:numel(uniqueartvec)-1
                diagnostics(k).artifactnsmp(kk) = sum(tmpartvec==uniqueartvec(kk+1));     % sample duration of each artifact (which may span >1 trial) 
            end

            % get the begin and endpoint of the artifact, expressed relative to the trial
            for kk = 1:numel(uniqueartvec)-1
                diagnostics(k).artifact(kk,1) = find(diff([0 tmpartvec==uniqueartvec(kk+1)])==1);   
                diagnostics(k).artifact(kk,2) = find(diff([tmpartvec==uniqueartvec(kk+1) 0])==-1);
            end
      else
            diagnostics(k).okflag       = true;   % is not an artifact
            diagnostics(k).artifactindx = [];
            diagnostics(k).artifactnsmp = [];
            diagnostics(k).artifact     = []; 
      end
    end
end
%% preprocess trial data
%%%%%%%%%% Subfunction %%%%%%%%%%%%%%%
function [dataSen, vertlim] = preprocData(cfg)
        
    dataSen = ft_preprocessing(cfg);
    dataSen = ft_channelnormalise([], dataSen);            % z-values
    
    vertlim = [inf -inf];
        for j = 1:numel(dataSen.trial)
            dataSen.trial{j} = mean(dataSen.trial{j},1);   % single vector; average across channels
            vertlim = [min(vertlim(1),min(dataSen.trial{j})) max(vertlim(2),max(dataSen.trial{j}))]; % smallest, largest amplitude across all trials 
        end
    dataSen.label = {'MEGavg'}; 
end

%% new figure
%%%%%%%%%% Subfunction %%%%%%%%%%%%%%%%%%
function [hdl] = figureParam(currTrial, trialsPerFig, arti,loop)
    hdl = figure;
    % paper config
    hold on;
    set(hdl,'PaperUnits', 'inches');
    set(hdl,'PaperSize', [8.27 11.69]);
    set(hdl, 'PaperPositionMode', 'manual');     % manual = use PaperPosition values below; auto - centered to page
    papersize = get(gcf, 'PaperSize');
    width = 8.27;
    height = 11.69;
    left = (papersize(1)- width)/2;
    bottom = (papersize(2)- height)/2;
    set(hdl, 'PaperPosition', [left bottom width height]);  % middle of page
    set(gca,'LooseInset',get(gca,'TightInset'));            % remove white space
    % figure axis, background, title
    set(hdl,'color','w');
    if loop == 1
        title([subjectname ' - ' arti ': Trials ' num2str(currTrial) ' to ' num2str(currTrial+trialsPerFig-1)]);
    elseif loop == 2
        title([subjectname ' - ' arti ': Trials ' num2str(currTrial+120) ' to ' num2str(currTrial+149)]);
    end 
    axis off
end 

%% plotting trial and superimpose artifacts for blinks and saccades
%%%%%%%%%% Subfunction %%%%%%%%%%%%%%%%%%
function superimpose(diagnostics,vlim,dataSen,trialsPerPage, artif, h, trlSen, loop)
    for q = 1:size(trlSen,1)
    %for q = 1:120
        if mod(q,trialsPerPage) == 1                        
           figureParam(q, trialsPerPage, artif,loop) % create new figure after X number of trials
        end

        hpos        = mod(q-1,5)*0.3;
        vpos        = 0.8 - floor((q-1)/5)*0.35;  
        hlim        = dataSen.time{q}([1 end]); 
        height      = h; 
        width       = 0.25;
        
        % plot single trial
        if strcmp(artif, 'blink') > 0 || strcmp(artif, 'sacc') > 0
            ft_plot_vector(dataSen.time{q},dataSen.trial{q},'height', height ,'width', width, 'hpos', hpos, 'vpos', vpos ,'color','k','hlim',hlim,'vlim',vlim);  % plot the trial
        elseif strcmp(artif, 'jump') > 0 
            ft_plot_vector(dataSen.time{q},ft_preproc_smooth(dataSen.trial{q},20),'height', height ,'width', width, 'hpos', hpos, 'vpos', vpos ,'color','k','hlim',hlim,'vlim',vlim);  % plot the trial
        elseif strcmp(artif,'musc') > 0
            ft_plot_vector(dataSen.time{q},ft_preproc_smooth(dataSen.trial{q},5),'height', height ,'width', width, 'hpos', hpos, 'vpos', vpos ,'color','k','hlim',hlim,'vlim',vlim);  % plot the trial
        end 
        
        % plot box with labels for min/max of signal
        if mod(q,trialsPerPage) == 11   
            ft_plot_box([hlim(1) hlim(2) vlim(1) vlim(2)],'height', height ,'width', width, 'hlim',hlim,'vlim',vlim,'hpos',hpos, 'vpos', vpos,'color','b');
            ft_plot_text(hlim(1)-1, 0, '0', 'height', height ,'width', width, 'hlim',hlim,'vlim',vlim,'hpos',hpos, 'vpos', vpos, 'fontsize', 10, 'color', 'b'); 
            if strcmp(artif, 'blink') > 0 || strcmp(artif, 'sacc') > 0          
                ft_plot_text(hlim(1)-.2, vlim(2), ['max: ' num2str(vlim(2))],'height', height ,'width', width, 'hlim',hlim,'vlim',vlim-1.5,'hpos',hpos, 'vpos', vpos, 'fontsize', 10, 'color','b'); 
                ft_plot_text(hlim(1)-.2, vlim(1), ['min: ' num2str(vlim(1))],'height', height ,'width', width, 'hlim',hlim,'vlim',vlim+1.5,'hpos',hpos, 'vpos', vpos, 'fontsize', 10, 'color','b');
            elseif strcmp(artif,'jump') > 0 || strcmp(artif, 'musc') > 0
                ft_plot_text(hlim(1), vlim(2), ['max: ' num2str(vlim(2))],'height', height ,'width', width, 'hlim',hlim,'vlim',vlim,'hpos',hpos, 'vpos', vpos, 'fontsize', 10, 'color','b'); 
                ft_plot_text(hlim(1), vlim(1), ['min: ' num2str(vlim(1))],'height', height ,'width', width, 'hlim',hlim,'vlim',vlim,'hpos',hpos, 'vpos', vpos, 'fontsize', 10, 'color','b');
            end
        end 
        
        
        % number the trials
        if loop == 1
            ft_plot_text(hpos+0.09, vpos, num2str(q), 'color','b');  
        elseif loop == 2
            newq = q+120;
            ft_plot_text(hpos+0.09, vpos, num2str(newq), 'color','b');
        end 
        artindx     = diagnostics(q).artifact;
        
        % superimpose the artifact(s)
        for qq = 1:size(artindx,1)
            ft_plot_vector(dataSen.time{q}(artindx(qq,1):artindx(qq,2)), dataSen.trial{q}(:,artindx(qq,1):artindx(qq,2)),'color','r','hpos',hpos,'vpos',vpos,'height',height,'width',width,'hlim',hlim,'vlim',vlim);
        end
 
        % save file into .eps
        fpath = '/home/language/annhul/MOUS/meg/';
        if strcmp(artif, 'blink') > 0 || strcmp(artif, 'sacc') > 0
            if q == 60
                page = 1;
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');
                close gcf
            elseif q == 120
                page = 2;
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');
                close gcf
            elseif q == 180 
                page = 3;
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');
                close gcf
            elseif q == 240 
                page = 4;
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');
                close gcf
            end    
            
        elseif strcmp(artif, 'jump') > 0 || strcmp(artif,'musc') > 0
            if q == 30
                page = 1;
                if loop == 2
                    page = page+4;
                end 
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc'); 
                %close gcf;   
            elseif q == 60
                page = 2;
                if loop  == 2
                    page = page+4;
                end 
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');                
                %close gcf;
            elseif q == 90 
                page = 3;
                if loop == 2
                    page = page+4;
                end 
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');                
                %close gcf ;
            elseif q == 120 
                page = 4;
                if loop  == 2
                    page = page+4;
                end 
                saveas(gcf,[fpath, subjectname, filesep, 'qualitycheck', filesep, subjectname, '_qc_art', artif, num2str(page)], 'epsc');                
                %close gcf;
            end 
        end 

    end  % of loop for figures
     
end  % of plotting subfunction
end  % of main function
 
%     cfg.trl = trlSen4;
%     trlDat  = trlSen4;
%     loop    = 2; 
%     [diagnostics]   = getDiagnostics(cfgart, trlDat, artType);
%     [dataSen, vlim] = preprocData(cfg);
%     superimpose(diagnostics,vlim,dataSen, plotPerPage, artifactName, figH, trlDat, loop);
%     
