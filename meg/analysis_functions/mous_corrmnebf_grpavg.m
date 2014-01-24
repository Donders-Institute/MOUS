function mous_corrmnebf_grpavg(param,cfginterp)

% this function interpolates each subjects correlation matrix from 2D to 3D
% and then calculates an averaged interpolated correlation matrix across
% all subjects

% cfg requires 3 inputs which define the files needed for mous_corrmnebf_interpolate
% MNE source solution, TFR source solution and correlation matrix.
% the data will be saved with the same specifications as the correlation matrix
% 
% for example
% param.range       = 'medium';
% param.foi         = 16;        
% param.toie        = [0.35 0.45];  % toi for ERFs
% param.selfq       = [-0.12 -0.08];
% param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
% param.suff        = num2str(param.foi);   
% param.savebf      = regexprep(num2str(mean(param.selfq)),'[.]','');
% param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 
% param.cdtn        = 'sen'; % 'seq'
% param.savegrpavg  = 'name of averaged correlation matrix'
% 
% cfginterp = [];
% cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
% cfginterp.erf = 'meg_anatomy_sourcemodel2D';
% cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];

subjectnames =  {'V1001' 'V1002' 'V1003' 'V1004' 'V1005' 'V1006' 'V1007' 'V1008' 'V1009' ...
                 'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                 'V1020' 'V1021' 'V1022' 'V1023' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
                 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1035' 'V1036' 'V1037' 'V1038' 'V1039'...
                 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1048' 'V1049'...
                 'V1050' 'V1052' 'V1053' 'V1054' 'V1055' 'V1057' 'V1058' 'V1059'...
                 'V1061' 'V1062' 'V1063' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                 'V1070' 'V1071' 'V1072' 'V1073' 'V1074' 'V1075' 'V1076' 'V1077' 'V1078' 'V1079'...
                 'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1086' 'V1087' 'V1088' 'V1089'...
                 'V1090' 'V1092' 'V1093' 'V1094' 'V1095' 'V1097' 'V1098' 'V1099'...
                 'V1100' 'V1101' 'V1102' 'V1103' 'V1104' 'V1105' 'V1106' 'V1107' 'V1108' 'V1109'...
                 'V1110' 'V1111' 'V1113' 'V1114'};   

for q = 1:numel(subjectnames) % interpolate the correlation matrix to 3d space 
    % source   grid
    % [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectnames{q},cfginterp);
    [source3d] = mous_corrmnebf_interpolate(subjectnames{q},cfginterp);

    tmp = isfinite(source3d.corrmat);  % NaNs are due to interpolation where no value of cortical sheet belong to a particular voxel (gridpoint)
    source3d.corrmat(~isfinite(source3d.corrmat))=0;  % keep track of which participants have NaN in correlation matrix
    if q == 1
        dof  = double(tmp);
        data = source3d;
        inside = source3d.inside;
    else
        dof = double(tmp)+dof;
        data.corrmat = data.corrmat + source3d.corrmat;
    end 
end

dataAvg = data;
dataAvg.corrmat = data.corrmat./dof; % divide by number of subjects that contribute data to that voxel (i.e. subject doesn't have a NAN value for that voxel)
nsubj = numel(subjectnames);

mous_db_putdata('groupresults',[param.savegrpavg,param.roi,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn,'_',num2str(nsubj),'subj'],'dataAvg','data','dof','param','cfginterp');

%% plotting
% see mous_corrmnebf_visualise