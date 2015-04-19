function mous_bfica_surfaceandparcellation(subj,sourcedata,freq)

% .mat  = output from mous_bfica_pipeline dosource (using ft_sourceinterpolate)
% nii   = volumetric nifti file (4D:  3D pos x time)
%       ft_sourcewrite is called to place .mat output of 5782 sources into a 11000 source space
% gii   = surface representation (also a volumetric representation)
%       mous_mne_3dto2d turns the .nii to .gii (for Left and Right hemisphere separately
% cifti files produced from workbench are used for visualisation
%       dtseries: 'd' = dense, i.e. a data is available for each vertex
%       ptseries: 'p' = parcellate, parcel time series 

% Things to consider:
% Selecting single or more frequencies
%   5 Hz, 16 Hz reflect a 2.5 hz 
%   previously looked at 16 vs. 24  vs.  16 - 28 Hz, similar spatial
%   distribution and statistical output
% selecting time points
%   400ms and 250ms sliding time window
%   to avoid overlap we should use only 350ms instead of mean(300, 350 and 400 ms)
%   because 350ms time point reflect  75ms - 475ms

% sourcedata = 'meg_bfica_sourcedatasentpar';
%              'meg_bfica_sourcedatasentseq';
%              'meg_bfica_sourcedataearlylateRC_matched';
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parcellate source data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ori = sourcedata;

if ismember(freq(1),2.5:2.5:12.5)
  suff = '_low';
  toi = [-0.10, 0.25:0.1:0.45];   % timepoint selection for statistics are done in mous_bfica_parcellate_statistics.m
 elseif ismember(freq(1),12:4:32)
  suff = '_medium';
  toi = [-0.15, -0.10, 0.25:0.1:0.45];
elseif ismember(freq(1),40:4:100)
  suff = '_high';
  toi = [-0.15, -0.10, 0.25:0.1:0.45];
end

Nsubj = numel(subj);

for k = 1:Nsubj
%     sourcedata = ori; % change seq back to sent
  % get the description of the 3D grid in standard space: sourcemodel (struct)
  load ('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm');

  % get the inside vector
  f = mous_db_getfilename(subj{k}, 'meg_bfica_leadfield8mm'); % loading full file will overwrite sourcemodel variable
  load(f{1},'newinside');

  % create filename for parcellated output
  f = mous_db_getfilename(subj{k}, [sourcedata,suff]);
  if mod(freq(1),1)  % isdecimal
    f1 = num2str(freq(1)*10,'%03d');
  else
    f1 = num2str(freq(1),'%02d');
  end
  if regexp(sourcedata,'sentseq')
    f{1} = strrep(f{1},'seq','');
  end    

  if numel(freq) == 1
    savename = strrep(f{1}, suff, ['_',f1, 'Hz']); 
  elseif numel(freq) == 2
    if mod(freq(end),1)  % isdecimal
      f2 = num2str(freq(2)*10,'%03d');
    else
      f2 = num2str(freq(2),'%02d');
    end
    savename = strrep(f{1},suff,['_',f1,'-',f2,'Hz']);
  end

  if exist('toi','var')
    % log time points of interest, not prestim time points
    % prestim time pointsi included for baseline subtraction
    tmp = num2str(toi*100,'%03d');   
    if regexp(sourcedata,'sentseqpar')
      savename1 = [savename,'_',tmp(end-8:end-6),'-',tmp(end-2:end),'s','.mat'];
    else
      savename1 = [savename(1:end-4),'_',tmp(end-8:end-6),'-',tmp(end-2:end),'s','.mat'];
    end
  end



  %% update these to have separate sections for each type of sourcecontrast: senseq, parametric, complexity

  % get sourcedata     
  switch sourcedata
      case {'meg_bfica_sourcedatasentseq'}
          mous_db_getdata(subj{k}, [sourcedata,suff]);
          tlck1 = tlcksent;
          tlck2 = tlckseq;
          savename2 = strrep(savename1,'sent','seq');
          
      case {'meg_bfica_sourcedatasentseqpar'}
          mous_db_getdata(subj{k},['meg_bfica_sourcedatasentpar',suff]);
          tlck1     = statsentpar;
          tlck1.avg = statsentpar.stat;
          
          mous_db_getdata(subj{k},['meg_bfica_sourcedataseqpar',suff]);
          tlck2     = statseqpar;
          tlck2.avg = statseqpar.stat;
          savename2 = strrep(savename1,'sent','seq'); 
          
      case {'meg_bfica_sourcedata_sent_earlylateRC_matched','meg_bfica_sourcedata_wl_earlylateRC_matched'} 
          % earlylateRC is loaded here;  earlylateMX is loaded below
          mous_db_getdata(subj{k}, [sourcedata,suff]);
          tlck1     = tlckearly;
          tlck2     = tlcklate;
          savename1 = strrep(savename1,'earlylate','early');
          savename2 = strrep(savename1,'early','late');
          
    case {'meg_bfica_sourcedata_earlylateSEN_matched','meg_bfica_sourcedata_earlylateWL_matched'}
          mous_db_getdata(subj{k}, [sourcedata,suff]);
          tlck1     = tlckearly;
          tlck2     = tlcklate;
          savename1  = strrep(savename1,'earlylate','early');
          savename2 = strrep(savename1,'early','late');
          
      otherwise
          error('check under line 89 for possible datasets that can be surfaced and parcellated');
  end

  % parcellation 
  switch sourcedata
      case {'meg_bfica_sourcedatasentseq' 'meg_bfica_sourcedatasentseqpar'}
           mous_bfica_parcellate(sourcemodel,tlck1,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename1);
           mous_bfica_parcellate(sourcemodel,tlck2,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename2);

      case {'meg_bfica_sourcedata_sent_earlylateRC_matched','meg_bfica_sourcedata_wl_earlylateRC_matched'}
           mous_bfica_parcellate(sourcemodel,tlck1,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename1);
           mous_bfica_parcellate(sourcemodel,tlck2,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename2);
           clear tlck*

           % RC/MX data saved with inconsistent format compared to
           % sentseq(all) and sentseqpar; therefore additional code is
           % needed
           sourcedata2 = strrep(sourcedata, 'RC', 'MX');
           mous_db_getdata(subj{k}, [sourcedata2, suff]);
           tlck1  = tlckearly;
           tlck2  = tlcklate;
           savename1  = strrep(savename1,'RC','MX');
           savename2 = strrep(savename2,'RC','MX');
           mous_bfica_parcellate(sourcemodel,tlck1,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename1);
           mous_bfica_parcellate(sourcemodel,tlck2,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename2);
           
      case {'meg_bfica_sourcedata_earlylateSEN_matched','meg_bfica_sourcedata_earlylateWL_matched'}
           % for earlySEN, lateSEN
           mous_bfica_parcellate(sourcemodel,tlck1,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename1);
           mous_bfica_parcellate(sourcemodel,tlck2,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename2);
           clear tlck*
           
           % for earlyWL, lateWL
           sourcedata2 = strrep(sourcedata,'SEN','WL');
           mous_db_getdata(subj{k},[sourcedata2,suff]);
           tlck1 = tlckearly;
           tlck2 = tlcklate;
           savename1 = strrep(savename1,'SEN','WL');
           savename2 = strrep(savename2,'SEN','WL');
           
           mous_bfica_parcellate(sourcemodel,tlck1,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename1);
           mous_bfica_parcellate(sourcemodel,tlck2,newinside,'frequency',freq,'time',toi,'method','surface','filename',savename2);
  end

end  % subjloop


