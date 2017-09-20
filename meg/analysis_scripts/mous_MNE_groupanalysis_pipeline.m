% %'V1013'  Something wrong with file
% 
% %Whole in head model: 22, 35, 38, 40, 78, 79
% 
% subjectnames = {'V1004' 'V1005' 'V1007' 'V1010' 'V1011' 'V1012' 'V1015' 'V1016' 'V1017'...
%         'V1019' 'V1020' 'V1021' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
%         'V1030' 'V1032' 'V1034' 'V1036' 'V1037' 'V1039' 'V1042' ...
%         'V1044' 'V1045' 'V1046' 'V1049' 'V1050' 'V1052' 'V1066' 'V1067' 'V1068' 'V1071' ...
%         'V1072' 'V1077'}; 
     
clear all
[subj,s] = setdiff(mous_db_getfilename('allV','subjectname'), mous_db_getfilename('bad','subjectname'));
Nsubj   = numel(subj); 

suffix = 'meg_processed_{_mne_allwords_02-nextword-rc-sent_currentdensity_weighted}';
rootdir = '/project/3011020.09/MEG/';

[stat,sent,seq,datsent,datseq] = mous_mne_groupanalysis(subj, suffix, rootdir);

%[stat GA_Sen GA_Seq] = mous_mne_groupanalysis(subj); 
% returns the stats and grand averages

%% save the stats and the grand averages
 
%fixme: implement the save function. 
%mous_db_putdata('groupresults', 'meg_processed_{MNE37subj_stat_allwords20121220}',stat, subjectnames);
save MOUS/meg/mne/mne37subjStatsAllwordsCluster.mat stat subjectname

%fixme: implement the save function. 
%mous_db_putdata('groupresults', 'meg_processed_{MNE37subj_GA_allwords20121220}',stat, subjectnames);
save MOUS/meg/mne/mne37subjGA.mat.mat GA_Sen & GA_Seq subjectnames

%%  Ploting %%

load ~/matlab/MOUS/meg/templates/sourcemodel/canonicalmesh.mat
load ~/matlab/MOUS/meg/templates/sourcemodel/canonicalinflated.mat


%% plot the t-values by funparameter = stat

%stat2d=mous_mne_3dto2d(stat,'target',canonicalmesh,'parameter','stat');
stat2d=mous_mne_3dto2d(stat,'target',canonicalmesh,'parameter','stat', 'inside', stat.inside);

% Uncomment if you want to plot the
% inflated brain
%stat2d.pos = canonicalinflated.pnt; 

cfg=[];
cfg.funparameter='stat';

figure;
ft_sourcemovie(cfg, stat2d);

%% plot the p-values by funparameter = prob

stat.prob = -log10(stat.prob);  % change 
stat2d=mous_mne_3dto2d(stat,'target',canonicalmesh,'parameter','prob', 'inside', stat.inside);

cfg=[];
cfg.funparameter='prob';

figure;
ft_sourcemovie(cfg, stat2d);

%% plot the grand averages
load MOUS/meg/mne/mne37subjGA.mat.mat
%fixme: use getdata

GA2dSen=mous_mne_3dto2d(GA,'target',canonicalmesh,'parameter','dspm_Sen', 'inside', GA.inside);
GA2dSeq=mous_mne_3dto2d(GA,'target',canonicalmesh,'parameter','dspm_Seq', 'inside', GA.inside);


% Uncomment if you want to plot the
% inflated brain
% stat2d.pos = canonicalinflated.pnt; 


cfg=[];
cfg.funparameter='dspm';
figure;
% use 2 output parameters if you want to save the video
[out, video]= ft_sourcemovie(cfg, GA2dSen, GA2dSeq);



%%  create video
% movie2avi(video, 'mneGA37subjLH');  
% transform video to wma on laptop. 
% Add code here. 


 