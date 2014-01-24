% % THIS SCRIPT DETERMINES THE SIGNIFICANT CLUSTERS FOR ERF DATA
% % JM, NL 11.6.2012

% full list
%subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         %'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         % 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};
         
% acceptable sub-list  N = 16
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};

%% (A) get the individual data for long time window
basedir = '/home/language/annhul/MOUS/Processed/';
nsubj   = numel(subjlist);
for k = 1:numel(subjlist)
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-pg']);  % load data
  erfAllTar{k} = senTar_CPG;   
  erfAllTar{k}.avg = ((senTar_CPG.avg + seqTar_CPG.avg)./2);
end

%% (C) plot time-locked data both conditions combined across conditions to determine ROI

tmp1 = ft_selectdata(erfAllTar{:},'param','avg','avgoverrpt','yes');

tlck_AllTar = tmp1;                                % 2D data  *chan_time*  
tlck_AllTar.dimord = 'chan_time';             
tlck_AllTar.avg = squeeze(mean(tmp1.avg));     

cfg             = [];
cfg.showlabels  = 'no'; 
cfg.interactive = 'yes';
cfg.fontsize    = 6; 
cfg.layout      = 'CTF275.lay';
cfg.zlim        = 'maxabs';
figure; ft_multiplotER(cfg,tlck_AllTar);
