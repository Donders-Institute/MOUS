function [] = mous_Xlog()
%--------------------------------------------------------------------------
% mous_Xlog.m 
%--------------------------------------------------------------------------
% Author(s): Julia Uddén
% Updated:      
% Date:      07-04-2012  
% © Julia Uddén
%--------------------------------------------------------------------------
% The program generates standard analysis output of a logfile generated
% with presentation. The output includes TR, number of volumes crucially 
% onsets and durations of conditions of a single FMRI-session/experiment.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Read in folder structure
%--------------------------------------------------------------------------

InfoXlog    
Files = struct2cell(dir);

%--------------------------------------------------------------------------
% Loop over subject, create one output logfile analysis for each loop
%--------------------------------------------------------------------------

    for subnr=1:length(info.logNames);         %subnr is the index over subject
    
    disp('---------------------------------------------');
        
    %----------------------------------------------------------------------
    % Find logfile in folder structure
    %----------------------------------------------------------------------        
    
    logfileName = info.logNames(subnr);
    [R,C] = find(strncmp(logfileName,Files,21));
    logfile = char(Files(1,C));

    %----------------------------------------------------------------------
    % Read in logfile
    %----------------------------------------------------------------------
    
    [subject, trial_number, event_type, code, time] = textread(logfile, ...
    '%s %d %s %s %d %*s %*d %*d %*d %*s %*s %*s %*s', 'delimiter', '\t', ...
    'headerlines', 5);

    %----------------------------------------------------------------------
    % Calculate mean and standard deviation of the observed TR
    %----------------------------------------------------------------------
    
    pulse_index=find(strcmp(event_type,'Pulse')); 
    pulse_onsets=time(pulse_index);
    pulse_times=time(pulse_index);
    meanTR=mean(diff(pulse_onsets))/10000; 
    stdTR=std(diff(pulse_onsets))/10000;
    
    %----------------------------------------------------------------------
    % SPM time zero
    %----------------------------------------------------------------------
    
    timeZero=pulse_times(info.nrDummyPulses);
    originalTime=time; time=time-timeZero;
    
    %---Number of volumes to include in the SPM analysis-------------------
    %----------------------------------------------------------------------
    % additional volumes will be recorded in the subject folder, but only
    % the ones logged by the presentation script will go into the analysis 
    %----------------------------------------------------------------------

    nrVolumes=sum(strcmp(event_type,'Pulse'))-info.nrDummyPulses;
    
    %---Indexing Conditions------------------------------------------------

    %'size' is built into cellfun - checks for the size of each element in 
    % the next agrument (the cell), along dimension 1
    
    code2ZinnenCell=regexp(code,'ZINNEN');
    ZinnenIndex=find(strcmp(event_type,'Picture') & ...
    cellfun('size',code2ZinnenCell,1));
    
    code2WoordenCell=regexp(code,'WOORDEN');
    WoordenIndex=find(strcmp(event_type,'Picture') & ...
    cellfun('size',code2WoordenCell,1));
    
    code2QuestionCell=regexp(code,'QUESTION');
    QuestionIndex=find(strcmp(event_type,'Picture') & ...
    cellfun('size',code2QuestionCell,1));
    
    code2ITICell=regexp(code,'blank');
    ITIIndex=find(strcmp(event_type,'Picture') & ...
    cellfun('size',code2ITICell,1));
    
    %---Find Onsets and Durations of ITI-----------------------------------
    % ITI Duration is from blank screen, over fixation to the next Picture
    %     V1001	1504	Picture	blank	16408061	
    %     V1001	1504	Pulse	50	16420596	
    %     V1001	1504	Picture	FIX 3963	
    %     V1001	1504	Pulse	50	
    %     V1001	1505	Picture	1 De 194
     
    %Create a matrix with the same size
    ITIOffsetIndex=ITIIndex;
   
    % Loop that finds next Picture 
    for outer=1:length(ITIIndex)
        a=ITIIndex(outer);
        for b=1:7
        if strcmp(event_type(a+b),'Picture') & ~strncmp(code(a+b),'FIX',3)
            ITIOffsetIndex(outer)=a+b;
            break
        end
        
        if b==7; disp('Warning, long ITI'); end
        
        end
    end
    
    ITIOnsets=time(ITIIndex);
    ITIOffsets=time(ITIOffsetIndex);
    ITIDurations=ITIOffsets-ITIOnsets;
    ITIDurationsInIndex=ITIOffsetIndex-ITIIndex;
    
    %---Find Onsets and Durations for Questions---------------------------- 
    %   Question Duration is from Questions screen to the response
    %     V1001	94	Picture	QUESTION 075	1104801	
    %     V1001	94	Pulse	50	1120466	20665	
    %     V1001	94	Response	2	1130776	30975	
    %     V1001	95	Picture	blank	1131146		
    %     V1001	95	Pulse	50	1140467	9321	
    %     V1001	95	Picture	FIX 3938	1151321	
    %     V1001	95	Pulse	50	1160466	29320	
    %     V1001	96	Picture	5 Tijdens 560	
     
    %Create a matrix with the same size
    QuestionOffsetIndex=QuestionIndex;
   
    % Loop that finds next Picture 
    for outer=1:length(QuestionIndex)
        a=QuestionIndex(outer);
        for b=1:20
        if strcmp(event_type(a+b),'Response')
            QuestionOffsetIndex(outer)=a+b;
            break
        end
        if b==20; disp('Warning, long Question'); end       
        end
    end
    
    QuestionOnsets=time(QuestionIndex);    
    QuestionOffsets=time(QuestionOffsetIndex);
    QuestionDurations=QuestionOffsets-QuestionOnsets;
    QuestionDurationsInIndex=QuestionOffsetIndex-QuestionIndex;
    
    %---Group the two conditions into a condition with all "events"--------

    EventIndex=sort([ZinnenIndex;WoordenIndex]);
   
    %---Find Onsets and Durations of Events--------------------------------
    
    EventOnsets=time(EventIndex);  
    EventDurations=[diff(EventOnsets);(time(end)-EventOnsets(end))];    
    EventDurationsInIndex=[diff(EventIndex);length(code)-EventIndex(end)];
    
   [foo,ZinnenIndexRows] = intersect(EventIndex,ZinnenIndex,'rows');
   [foo,WoordenIndexRows] = intersect(EventIndex,WoordenIndex,'rows'); 
   
   ZinnenDurationsInIndex=EventDurationsInIndex(ZinnenIndexRows);
   WoordenDurationsInIndex=EventDurationsInIndex(WoordenIndexRows);  

    %---Erase ITIs and Questions from Events-------------------------------
    
    %---Group ITIs and Questions to "NoEvents"-----------------------------
    
    NoEventsIndex=sort([QuestionIndex;ITIIndex]);
    NoEventsOffsetIndex=sort([QuestionOffsetIndex;ITIOffsetIndex]);
    NoEventsDurationsInIndex=NoEventsOffsetIndex-NoEventsIndex;
    
    %---Zinnen-------------------------------------------------------------
    
    OriginialZinnenIndex=ZinnenIndex;
    
   % Make more start indices, one for each NoEvent within a zinnen block
    for k=1:length(NoEventsOffsetIndex)
        for n=1:length(OriginialZinnenIndex)
            if OriginialZinnenIndex(n) < NoEventsOffsetIndex(k) & ...
                NoEventsOffsetIndex(k) < ...
                    (OriginialZinnenIndex(n)+ZinnenDurationsInIndex(n))
               
                ZinnenIndex=[ZinnenIndex;(NoEventsOffsetIndex(k))];
            end        
        end
    end
    
    ZinnenIndex=sort(ZinnenIndex);
    
    %---Woorden-------------------------------------------------------------
    
    OriginialWoordenIndex=WoordenIndex;
    
   % Make more start indices, one for each NoEvent within a Woorden block
    for k=1:length(NoEventsOffsetIndex)
        for n=1:length(OriginialWoordenIndex)
            if OriginialWoordenIndex(n) < NoEventsOffsetIndex(k) & ...
                NoEventsOffsetIndex(k) < ...
                    (OriginialWoordenIndex(n)+WoordenDurationsInIndex(n))
               
                WoordenIndex=[WoordenIndex;(NoEventsOffsetIndex(k))];
            end        
        end
    end
    
    WoordenIndex=sort(WoordenIndex);
    
    %---Update Events------------------------------------------------------
    
    EventIndex=sort([ZinnenIndex;WoordenIndex]);
    EventOnsets=time(EventIndex);  
    EventDurations=[diff(EventOnsets);(time(end)-EventOnsets(end))];    
    EventDurationsInIndex=[diff(EventIndex);length(code)-EventIndex(end)];
    
   [foo,ZinnenIndexRows] = intersect(EventIndex,ZinnenIndex,'rows');
   [foo,WoordenIndexRows] = intersect(EventIndex,WoordenIndex,'rows'); 
   
   ZinnenDurationsInIndex=EventDurationsInIndex(ZinnenIndexRows);
   WoordenDurationsInIndex=EventDurationsInIndex(WoordenIndexRows);  
    
    %---Find Onsets and Durations for Conditions---------------------------
    
    ZinnenOnsets=time(ZinnenIndex);
    ZinnenDurations=time(ZinnenIndex+ZinnenDurationsInIndex)-time(ZinnenIndex);
    
    WoordenOnsets=time(WoordenIndex);
    WoordenDurations=time(WoordenIndex+WoordenDurationsInIndex)-time(WoordenIndex);  

%     [ZinnenDurations,ZinnenOnsets] = onsetsANDdurations(ZinnenIndex, ...
%          EventDurations, EventIndex, time);
%
%     [WoordenDurations,WoordenOnsets] = onsetsANDdurations(WoordenIndex, ...
%          EventDurations, EventIndex, time);
    
%   Section used for debugging  
%   [EventIndex(1:20),WoordenIndex(1:20),ZinnenIndex(1:20)]

    %----------------------------------------------------------------------
    % Find responses
    %----------------------------------------------------------------------

    response_index=find(strcmp(event_type,'Response'));
    response_code=code(response_index); 
    response_times=time(response_index);

    %--------------------------------------------------------------------------
    % OUTPUT SECTION
    %--------------------------------------------------------------------------

    behav_dir=char(strcat(info.rootdir,filesep, ...
        'logfileProcessing',filesep,'OutputBehavdata',filesep, ...
        info.subjects(subnr),filesep));
    if exist(behav_dir,'dir')~=7; mkdir(behav_dir); end

    %----------------------------------------------------------------------
    % fnew is used to create OUTPUT FILENAMES related to the INPUT FILE.
    % The OUTPUT FILE fnew-Xlog-date.doc is formated for MS-Word.
    %----------------------------------------------------------------------

    logfileName=logfile;
    k = 1; while ~strcmp(logfileName(k),'.'); fnew(k)=logfileName(k); k = k+1; end
    fullpath=behav_dir;%strcat(info.rootdir,'\');
    fnew0=[fnew,'-Xlog-',date,'.doc']; fnew1=char(strcat(fullpath,fnew,'-Xlog-',date,'.doc'));
    fid = fopen(fnew1,'w'); fprintf(fid,'\n\n');
    fprintf(fid,fnew0);
    %--------------------------------------------------------------------------
    % PRINTOUT OF THE DESCRIPTIVE STATISTICS
    %--------------------------------------------------------------------------
    fprintf(fid,'\n\nDESCRIPTIVE STATISTICS\n\n');
    fprintf(fid,'mean(TR)\t\t\t\t\t\t\t= %-1.5f%s\n',meanTR,' [s]');
    fprintf(fid,'mean(TA)\t\t\t\t\t\t\t= %-1.5f%s\n',meanTR*32/33,' [s]');  %NR slices is hardcoded here
    fprintf(fid,'std(TR)\t\t\t\t\t\t\t= %-1.5f%s\n\n',stdTR,' [s]');
    %fprintf(fid,'mean(ITI)\t\t\t\t\t\t\t= %-1.5f%s\n',meanITI,' [s]');
    %fprintf(fid,'std(ITI)\t\t\t\t\t\t\t= %-1.5f%s\n\n\n',stdITI,' [s]');
    fprintf(fid,'Total number of pulses\t\t\t\t\t= %d\n', ...
      length(find(strcmp(event_type,'Pulse')))-info.nrDummyPulses);
    fprintf(fid,'= #volumes to include in the SPM analysis of this session.\n\n');
    fprintf(fid,'SPM Time Zero\t\t\t\t\t\t= %-7d%s\n',timeZero,'[10^-4s]');
    fprintf(fid,'= time of the 4th EPI volume.\n\n\n');
    fprintf(fid,'Total number of trials\t\t\t\t\t= %d\n', ...
      length(ZinnenIndex)+length(WoordenIndex));
    fprintf(fid,'Total number of responses (=? #trials)\t\t= %d\n\n\n', ...
      length(response_index));

    condition_cell={'Zinnen','Woorden','ITI','Question'};

    for index=1:length(condition_cell)
        cond_string=char(strcat('Number of_',condition_cell(index)));
        cond=char(condition_cell(index));
        eval(strcat('fprintf(fid,',char(39),cond_string, '_items\t\t\t\t\t= %d\n',char(39),',length(',cond,'Onsets));'))
    end    

    %--------------------------------------------------------------------------
    % PRINTOUT OF THE RESPONSE WINDOWS
    %--------------------------------------------------------------------------
    %if ~flax; printResponses(fid,PostResponsePre_code, ...
    %    PostResponsePre_trialNumber,check_index,flax); end
    %--- regressors -----------------------------------------------------------
    %fprintf(fid,'\fREGRESSORS\n\n');

    % for index=1:size(condition_cell,2)
    %   cond=condition_cell(index);  
    %   eval(char(strcat('fprintf(fid,',char(39),'\n',cond,'-c-onsets:\t\t',cond,'-c-durations\n',char(39),');')))
    %   eval(char(strcat('for k=1:length(h',cond,'on); fprintf(fid,',char(39),'%8d\t\t\t%8d\n',char(39),',h',cond,'on(k),h',cond,'dur(k)); end')))
    %   eval(char(strcat('fprintf(fid,',char(39),'\n',cond,'-nc-onsets:\t\t',cond,'-nc-durations\n',char(39),');')))
    %   eval(char(strcat('for k=1:length(m',cond,'on); fprintf(fid,',char(39),'%8d\t\t\t%8d\n',char(39),',m',cond,'on(k),m',cond,'dur(k)); end')))
    % end 

    % fprintf(fid,'\nControl-onsets:\t\tControl-durations\n');
    % for k=1:length(control_onsets); fprintf(fid,'%8d\t\t\t%8d\n',control_onsets(k), ...
    %       control_durations(k));end

    %--------------------------------------------------------------------------
    % PRINTOUT OF THE Xlog PARSE
    % FORMAT: trial_number, event_type, code, time
    %--------------------------------------------------------------------------

    fprintf(fid,'\f%s\t%s\t%s\t%s\t\t\t\t\t%s\n','#','Trial','EventType', ...
      'Code','     Time in 10^-4s');
    for k=1:length(trial_number);
      fprintf(fid,'\n%-3d\t%-3d\t%-8s\t%-30s\t%8d',...
        k, trial_number(k), event_type{k}, code{k}, originalTime(k));
    end
    fclose(fid);

    %--------------------------------------------------------------------------
    %if strcmp(saveMatfiles,'y');
    %--------------------------------------------------------------------------
    % The OUTPUT FILE fnew-allXlog-date.mat saves all variable values,i.e., the
    % whole workspace, generated by Xlog.
    %--------------------------------------------------------------------------

    fnew2=char(strcat(fullpath,fnew,'-allXlog-',date));
    save(fnew2);
    %--------------------------------------------------------------------------
    % The OUTPUT FILE cond.mat saves a cell-array with the condition names as 
    % well as the onsets and durations for each condition.
    %--------------------------------------------------------------------------
    
    %Copy
    fnew3=char(strcat(info.rootdir,filesep,'OutputBehavdata',filesep,info.subjects(subnr),filesep,info.subjects(subnr)));
    %ProcessingLocation
    fnew4=char(fullfile(info.ffxdatadir, ...
        filesep,char(info.subjects(subnr)),filesep,'NamesOnsDur'));
    if exist(fnew4,'dir')~=7; mkdir(fnew4); end

    m=1; names={}; onsets={}; durations={};
    for n=1:size(condition_cell,2);
      names{m}=condition_cell{n};
      eval(strcat('onsets{m}=',condition_cell{n},'Onsets','/10000;'))
      eval(strcat('durations{m}=',condition_cell{n},'Durations','/10000;'))
      m=m+1;
    end

    if length(names)==length(onsets) & length(names)==length(durations);
        %save(fnew3,'names','onsets','durations');
        save(char(strcat(fnew4,filesep,info.subjects(subnr))),'names','onsets','durations');
    else
    error('Warning: The number of names, onsets, and durations not same!');
    end

    %--------------------------------------------------------------------------
    %end %if strcmp(saveMatfiles,'y');
    %--------------------------------------------------------------------------

    end
    clear all;
end
