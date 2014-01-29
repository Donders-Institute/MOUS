function xpanded_jobs = xpandjobs(jobs,info,sbjnr)
%==========================================================================
% Author(s):    kmp
% Updated:      13/12/2008
% Date:         09/11/2006
% © Karl Magnus Petersson
%--------------------------------------------------------------------------
% SELECT FUNCTIONAL IMAGES SESSIONWISE
%--------------------------------------------------------------------------
[subjectPath,sessionPaths,fct_images]=selectimages(info,sbjnr);
% [subjectPath,sessionPaths,fct_images,structPath,struct_image]= ...
%   selectimages(info,sbjnr);
%--------------------------------------------------------------------------
% prefix=info.prefix;
%--------------------------------------------------------------------------
% LOOP OVER PREPROCESSING TASKS
%--------------------------------------------------------------------------
for jobnr=1:length(jobs)
  %------------------------------------------------------------------------
  % IDENTIFY JOB-TYPE: SPATIAL OR TEMPORAL
  %------------------------------------------------------------------------
  if strcmp(fieldnames(jobs{jobnr}),'stats')
    %----------------------------------------------------------------------
    % STATISTICS (SESSIONWISE - FLAX = 1)
    %----------------------------------------------------------------------
    flax=1; if info.prefixstatus; prefix=info.prefix; end
    for statnr=1:length(jobs{jobnr}.stats)
      ffxStatdir=fullfile(info.ffxstatsdir,strcat(info.subjects{sbjnr}, ...
        info.ffxresultsdir));
      if exist(ffxStatdir,'dir')~=7; mkdir(ffxStatdir); end
      spmmatFile=fullfile(ffxStatdir,'SPM.mat');
      regressorPath=fullfile(subjectPath,info.namesonsdurdir);
      %--------------------------------------------------------------------
      % MODEL SPECIFICATION
      %--------------------------------------------------------------------
      if strcmp(fieldnames(jobs{jobnr}.stats{statnr}),'fmri_spec')
        scans=take5(prefix,sessionPaths,fct_images,flax);
        regressorFile=spm_select('List',regressorPath,info.nameonsdur);
        regressorFile=cellstr(regressorFile);
        for sesnr=1%:length(sessionPaths)
          jobs{jobnr}.stats{statnr}.fmri_spec.sess(sesnr).scans = ...
            scans{sesnr};
          jobs{jobnr}.stats{statnr}.fmri_spec.sess(sesnr).multi = ...
            {fullfile(regressorPath,regressorFile{sesnr})};
          rpPath=sessionPaths{sesnr}; rpFile=fullfile(rpPath, ...
            spm_select('List',rpPath,info.rpfile));
          jobs{jobnr}.stats{statnr}.fmri_spec.sess(sesnr).multi_reg= ...
            {rpFile};
        end
        jobs{jobnr}.stats{statnr}.fmri_spec.dir={ffxStatdir};
        %------------------------------------------------------------------
        % MODEL ESTIMATION
        %------------------------------------------------------------------
      elseif strcmp(fieldnames(jobs{jobnr}.stats{statnr}),'fmri_est')
        jobs{jobnr}.stats{statnr}.fmri_est.spmmat={spmmatFile};
        %------------------------------------------------------------------
        % CONTRAST GENERATION AND ESTIMATION
        %------------------------------------------------------------------
      elseif strcmp(fieldnames(jobs{jobnr}.stats{statnr}),'con')
        jobs{jobnr}.stats{statnr}.con.spmmat={spmmatFile};
        cntrNames=info.cntrNames;
        contrastMatrix=info.contrastMatrix;
        %------------------------------------------------------------------
        % INCLUDE CONTRASTS
        %------------------------------------------------------------------
        if length(cntrNames)==size(contrastMatrix,1)
          for k=1:length(cntrNames)
            jobs{jobnr}.stats{statnr}.con.consess{k}.tcon.name= ...
              cntrNames{k};
            jobs{jobnr}.stats{statnr}.con.consess{k}.tcon.convec= ...
              contrastMatrix(k,:)';
          end
        else
          fprintf('Number of contrast names and contrasts mismatch\n');
          error('xpandjobs con-section stops processing');
        end
        %------------------------------------------------------------------
        % INCLUDE CONTRASTS AND TEMPORAL DERIVATIVE CONTRASTS
        %------------------------------------------------------------------
        %         for k=1:length(contrastInfo.accntr);
        %           jobs{jobnr}.stats{statnr}.con.consess{k}.tcon.name= ...
        %             contrastInfo.accntr{k};
        %           jobs{jobnr}.stats{statnr}.con.consess{k}.tcon.convec= ...
        %             contrastInfo.cntrV(k,:);
        %         end
        %         jobs{jobnr}.stats{statnr}.con.consess{...
        %           length(contrastInfo.accntr)+1}.tcon.name = ...
        %           strcat('dt',contrastInfo.accntr{1});
        %         jobs{jobnr}.stats{statnr}.con.consess{...
        %           length(contrastInfo.accntr)+1}.tcon.convec = ...
        %           contrastInfo.dtcntrV(1,:);
        %         jobs{jobnr}.stats{statnr}.con.consess{...
        %           length(contrastInfo.accntr)+2}.tcon.name = ...
        %           strcat('negative_dt',contrastInfo.accntr{1});
        %         jobs{jobnr}.stats{statnr}.con.consess{...
        %           length(contrastInfo.accntr)+2}.tcon.convec = ...
        %           contrastInfo.dtcntrV(2,:);
      else
        fprintf('Ignoring whatever is not fmri_spec, fmri_est, or con\n');
      end
    end
  else
    error('Unrecognized spatial/temporal/stats/util job');
  end
end
%--------------------------------------------------------------------------
% OUTPUT - EXPANDED JOB-STRUCTURE
%--------------------------------------------------------------------------
xpanded_jobs = jobs;