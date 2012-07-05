function xpanded_jobs = mous_xpandjobs(jobs,info,sbjnr);
%==========================================================================
% FORMAT: xpanded_jobs = xpandjob_spm5(jobs,info,sbjnr);
% INPUT: jobs - skeleton batch structure generated in SPM5 outlining the
% tasks included in the job (e.g., realignment, acquisition (slice) time
% correction, coregistration, normalization, segmentation, smoothing, and
% single subject statistics); info - cell array with information relating
% to subjects, directories etc.; sbjnr - the number of the subject for
% which the jobs structure is expanded;
% OUTPUT: jobs structure expanded to include the fullpaths of the relevant
% imagefiles etc.
%--------------------------------------------------------------------------
% Author(s):    kmp
% Updated:      09/07/2008, 19/10/2008
% Date:         09/11/2006
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
% SELECT FUNCTIONAL IMAGES SESSIONWISE
%--------------------------------------------------------------------------
% infoSubjects;	% cf., infoSubjects.m
[subjectPath,fctPath, ...
  fct_images,structPath,struct_image]= mous_selectimages(info,sbjnr);
%--------------------------------------------------------------------------
% prefix=info.prefix;
%--------------------------------------------------------------------------
% LOOP OVER PREPROCESSING TASKS
%--------------------------------------------------------------------------
fctPath=fctPath;
str_image=struct_image;
strPath=structPath;
for jobnr=1:length(jobs);
  %------------------------------------------------------------------------
  % IDENTIFY JOB-TYPE: SPATIAL OR TEMPORAL
  %------------------------------------------------------------------------
  if strcmp(fieldnames(jobs{jobnr}.spm),'temporal');
    %----------------------------------------------------------------------
    % ACQUISITION (SLICE) TIME CORRECTION (SESSIONWISE - FLAX = 1)
    %----------------------------------------------------------------------
    scans=take5('r',fctPath,fct_images);
    scans=scans{1};
    jobs{jobnr}.temporal{1}.st.scans=scans;
  elseif strcmp(fieldnames(jobs{jobnr}.spm),'spatial');
    for spatnr=1:length(jobs{jobnr}.spm.spatial);
      %--------------------------------------------------------------------
      % IDENTIFY SPATIAL JOB-TYPE
      %--------------------------------------------------------------------
      spatialFieldnames=fieldnames(jobs{jobnr}.spm.spatial);
      if strcmp(spatialFieldnames(spatnr),'realign');
         
        %------------------------------------------------------------------
        % REALIGNMENT (SESSIONWISE - FLAX = 1)
        %------------------------------------------------------------------
        data=mous_take5('',fctPath,fct_images);
        jobs{jobnr}.spm.spatial.realign.estwrite.data=data;
        %jobs{jobnr}.spatial{spatnr}.realign{1}.estwrite.data=data;
        %elseif strcmp(fieldnames(jobs{jobnr}.spm.spatial),'coreg');
    
       elseif strcmp(spatialFieldnames(spatnr),'coreg'); 
        %------------------------------------------------------------------
        % COREGISTRATION
        %------------------------------------------------------------------
        reference=cellstr(str_image);
        source=cellstr(fullfile(fctPath, ...
          strcat('amean',fct_images{1})));
        jobs{jobnr}.spm.spatial.coreg.estimate.ref=reference;  
        jobs{jobnr}.spm.spatial.coreg.estimate.source=source;
     % elseif strcmp(spatialFieldnames(spatnr),'coreg');
        %------------------------------------------------------------------
        % SEGMENTATION
        %------------------------------------------------------------------
     %   data=cellstr(fullfile(strPath,str_image));
     %   jobs{jobnr}.spm.spatial.preproc.data=data;
%         jobs{jobnr}.spatial{spatnr}.preproc.output.GM=info.GM;
%         jobs{jobnr}.spatial{spatnr}.preproc.output.WM=info.WM;
%         jobs{jobnr}.spatial{spatnr}.preproc.output.CSF=info.CSF;
%         jobs{jobnr}.spatial{spatnr}.preproc.output.biascor= ...
%           info.biascorrection;
%         jobs{jobnr}.spatial{spatnr}.preproc.output.cleanup= ...
%           info.cleanup;
      elseif strcmp(spatialFieldnames(spatnr),'normalise');
        %------------------------------------------------------------------
        % NORMALIZATION (NON-SESSIONWISE - FLAX = 0)
        %------------------------------------------------------------------
        
        source=cellstr(str_image);
        jobs{jobnr}.spm.spatial.normalise.estwrite.subj.source= ...
          source;
        
        % Functional as source
        % source=cellstr(fullfile(fctPath, ...
        %  strcat('mean',fct_images{1})));
        % jobs{jobnr}.spm.spatial.normalise.estwrite.subj.source= ...
        %  source;
        normfiles=mous_take5('ar',fctPath,fct_images);
        %------------------------------------------------------------------
        % ADD SEGMENTS C1, C2, AND MODULATED STRUCTURAL IMAGE FOR
        % NORMALIZATION
        %------------------------------------------------------------------
        normfiles=cellstr(normfiles{1});
         normfiles=[normfiles; {[str_image]}];
         %{[strPath,filesep,'c1',str_image]}; ...
         %{[strPath,filesep,'c2',str_image]}; ...
         %{[strPath,filesep,'m',str_image]}];
     jobs{jobnr}.spm.spatial.normalise.estwrite.subj.resample=...
     normfiles;   
    %jobs{jobnr}.spatial{spatnr}.normalise{1}.estwrite.subj.resample=...
     % normfiles;  
     %jobs{jobnr}.spatial{spatnr}.normalise{1}.estwrite.subj.resample=...
        %  normfiles;
        %jobs{jobnr}.spatial{spatnr}.normalise{1}.estwrite.eoptions.template=...
        %  info.template;
     if jobnr==5;
      if strcmp(fieldnames(jobs{jobnr}.spm.spatial),'smooth');
        %------------------------------------------------------------------
        % SPATIAL FILTERING (NON-SESSIONWISE - FLAX = 0)
        %------------------------------------------------------------------
        data=mous_take5('war',fctPath,fct_images);
        %------------------------------------------------------------------
        % ADD SEGMENTS WC1, WC2 AND MODULATED STRUCTURAL IMAGE WM
        % FOR SMOOTHING
        %------------------------------------------------------------------
        data=cellstr(data{1});
        data=[data; {[strPath,filesep,'w',str_image]}];...
        %  {[strPath,filesep,'wc1',str_image]}; ...
        %  {[strPath,filesep,'wc2',str_image]}; ...
        %  {[strPath,filesep,'wm',str_image]}];
       jobs{jobnr}.spm.spatial.smooth.data=data;
       jobs{jobnr}.spatial{spatnr}.smooth.fwhm=info.fwhm;
      end
     end
     end
    end
  %check nr of ends
elseif strcmp(fieldnames(jobs{jobnr}.spm),'stats');
    %----------------------------------------------------------------------
    % STATISTICS (SESSIONWISE - FLAX = 1)
    %----------------------------------------------------------------------
    for statnr=1:length(jobs{jobnr}.spm.stats)
      ffxStatdir=fullfile(subjectPath,info.statdir);
      if exist(ffxStatdir) ~= 7
        mkdir(subjectPath,info.statdir);
      end
      spmmatFile=fullfile(ffxStatdir,'SPM.mat');
      regressorPath=fullfile(subjectPath,info.conddir);
      if strcmp(fieldnames(jobs{jobnr}.spm.stats{statnr}),'fmri_spec')
        scans=mous_take5('swar',sessionPath,fct_images,1);
        regressorFile=spm_select('List',regressorPath,info.regressor);
        for sesnr=1:length(sessionPath)
          jobs{jobnr}.spm.stats{statnr}.fmri_spec.sess(sesnr).scans = ...
            scans{sesnr};
          jobs{jobnr}.spm.stats{statnr}.fmri_spec.sess(sesnr).multi = ...
            {fullfile(regressorPath,regressorFile(sesnr,:))};
          rpPath=sessionPath{sesnr}; rpFile=fullfile(rpPath, ...
            spm_select('List',rpPath,'^rp.*\.txt'));
          jobs{jobnr}.spm.stats{statnr}.fmri_spec.sess(sesnr).multi_reg= ...
            {rpFile};
        end 

        jobs{jobnr}.spm.stats{statnr}.fmri_spec.dir={ffxStatdir};
      elseif strcmp(fieldnames(jobs{jobnr}.spm.stats{statnr}),'fmri_est')
        jobs{jobnr}.spm.stats{statnr}.fmri_est.spmmat={spmmatFile};
      elseif strcmp(fieldnames(jobs{jobnr}.spm.stats{statnr}),'con')
        jobs{jobnr}.spm.stats{statnr}.con.spmmat={spmmatFile};
        presentwd=pwd; cd(subjectPath);
        cntrInfo=[info.subjects{sbjnr,1},'_cntr'];
        [cntrnames,cntrvectors]=feval(cntrInfo);
        cd(presentwd);
        for k=1:length(cntrnames)
          jobs{jobnr}.spm.stats{statnr}.con.consess{k}.tcon.name= ...
            cntrnames{k};
          jobs{jobnr}.spm.stats{statnr}.con.consess{k}.tcon.convec= ...
            cntrvectors{k};
        end
      else
        disp('Ignoring whatever is not fmri_spec, fmri_est, or con');
      end
    end
  else
    error('Unrecognized spatial/temporal/stats/util job.');
  end
end


%--------------------------------------------------------------------------
% OUTPUT - EXPANDED JOB-STRUCTURE
%--------------------------------------------------------------------------
xpanded_jobs = jobs;
%End of xpandjobs----------------------------------------------------------
