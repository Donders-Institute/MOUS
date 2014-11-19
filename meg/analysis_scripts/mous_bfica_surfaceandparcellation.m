function mous_bfica_surfaceandparcellation

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

subj={'V1001' 'V1002' 'V1003' 'V1004' 'V1005' 'V1006' 'V1007' 'V1008' 'V1009' ...
                 'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                 'V1020' 'V1022' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
                 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1035' 'V1036' 'V1037' 'V1038' 'V1039'...
                 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1048' 'V1049'...
                 'V1050' 'V1052' 'V1053' 'V1054' 'V1055' 'V1057' 'V1058' 'V1059'...
                 'V1061' 'V1062' 'V1063' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                 'V1070' 'V1071' 'V1072' 'V1073' 'V1074' 'V1075' 'V1076' 'V1077' 'V1078' 'V1079'...
                 'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1086' 'V1087' 'V1088' 'V1089'...
                 'V1090' 'V1092' 'V1093' 'V1094' 'V1095' 'V1097' 'V1098' 'V1099'...
                 'V1100' 'V1101' 'V1102' 'V1103' 'V1104' 'V1105' 'V1106' 'V1107' 'V1108' 'V1109'...
                 'V1110' 'V1111' 'V1113' 'V1114' 'V1115' 'V1116' 'V1117'};   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parcellate source data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
freq{1} = 5;
freq{2} = 10;
freq{3} = 16;
freq{4} = 24;
freq{5} = [40 100];
freq{6} = [40 48];  % 32  56  % given 8Hz tapsmofrq
freq{7} = [64 72];  % 56  80
freq{8} = [88 100]; % 80  102

for fcnt = 1:numel(freq)
  frequency = freq{fcnt};
  if ismember(frequency(1),2.5:2.5:12.5)
    suff = '_low';
    toi = [-0.10, 0.25:0.1:0.45];
  elseif ismember(frequency(1),12:4:32)
    suff = '_medium';
    toi = [-0.15, -0.10, 0.25:0.1:0.45];
  elseif ismember(frequency(1),40:4:100)
    suff = '_high';
    toi = [-0.15, -0.10, 0.25:0.1:0.45];
  end
  
  Nsubj = numel(subj);
  
  for k = 1:Nsubj
%     sourcedata = 'meg_bfica_sourcedatasentpar';
    sourcedata = 'meg_bfica_sourcedatasentseq';

    % get the description of the 3D grid in standard space: sourcemodel (struct)
    load ('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm');

    % get the inside vector
    f = mous_db_getfilename(subj{k}, 'meg_bfica_leadfield8mm'); % loading full file will overwrite sourcemodel variable
    load(f{1},'newinside');
    
    % create filename for parcellated output
    f = mous_db_getfilename(subj{k}, [sourcedata,suff]);

    if mod(frequency(1),1)  % isdecimal
      f1 = num2str(frequency(1)*10,'%03d');
    else
      f1 = num2str(frequency(1),'%02d');
    end
    
    if regexp(sourcedata,'sentseq')
      f{1} = strrep(f{1},'seq','');
    end    
    
    if numel(frequency) == 1
      filename = strrep(f{1}, suff, [f1, 'Hz']); 
    elseif numel(frequency) == 2
      if mod(frequency(end),1)  % isdecimal
        f2 = num2str(frequency(2)*10,'%03d');
      else
        f2 = num2str(frequency(2),'%02d');
      end
      filename = strrep(f{1},suff,[f1,'-',f2,'Hz']);
    end
    
    if exist('toi','var')
      % log time points of interest, not prestim time points
      % prestim time pointsi included for baseline subtraction
      tmp = num2str(toi*100,'%03d');
      filename = [filename(1:end-4),'_',tmp(end-8:end-6),'-',tmp(end-2:end),'s','.mat'];
    end
   
    % get sourcedata and parcellate
    % sentences
    mous_db_getdata(subj{k}, [sourcedata,suff]);
    if regexp(sourcedata,'par')
      tlcksent      = statsentpar;
      tlcksent.avg  = statsentpar.stat;
    end
       
    mous_bfica_parcellate(sourcemodel,tlcksent,newinside,'frequency',frequency,'time',toi,'method','surface','filename',filename);
    
    % word lists (sequences)
    filename = strrep(filename, 'sent', 'seq');
    if regexp(sourcedata,'par')
      sourcedata = strrep(sourcedata,'sent','seq');
      mous_db_getdata(subj{k}, [sourcedata,suff]);
      tlckseq     = statseqpar;
      tlckseq.avg = statseqpar.stat;
    end

    mous_bfica_parcellate(sourcemodel,tlckseq,newinside,'frequency',frequency,'time', toi,'method','surface','filename',filename);

  end  % subjloop
end    % freqloop

