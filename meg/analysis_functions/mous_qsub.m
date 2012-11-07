addpath('/home/common/matlab/fieldtrip/qsub');

clear all

% full list
subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
         'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
         'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};

% 16 participants  (ptpSet1 - those used for MSc)     
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050','V1053'};
        
% 19 participants (ptpSet2  - adding to Set1 to analyze with larger N)
subjlist = {'V1004', 'V1005', 'V1007', 'V1009', 'V1035'...
            'V1038', 'V1049', 'V1055', 'V1058', 'V1059'...
            'V1060', 'V1063', 'V1065', 'V1067', 'V1068'...
            'V1071', 'V1072', 'V1078', 'V1079'};


% NL started preprocessing on 25.09.2012, target words, 20:02
qsubcellfun(@mous_preprocessing_pipeline, subjlist, 'timreq', 7000, 'memreq', 4*1024^3);     


% Nietzsche's TFR script started at 
fpst
% ERF pipeline:
for k = 1:numel(subjlist)
  allinput1{k} = subjlist{k};
  allinput2{k} = 'short';  % or 'long'
  allinput3{k} = 'target'; % or 'word'
end
 
qsubcellfun(@mous_erf_pipeline, allinput1, allinput2, allinput3,'timreq', 600, 'memreq', 4*1024^3);  


% 1 hour: 60 seconds * 60 minutes = 3600s
% 1.94h = 7000s 