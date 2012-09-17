% This function pulls the average number of trials based on the ERF analyses
% NL 12.6.2012

%full list
% subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' 'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024'...
%           'V1025' 'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1036' 'V1037'...
%           'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1061'};


% Partial (clean) list:
subjlist = {'V1010' 'V1012' 'V1013' 'V1015' 'V1024'...
            'V1025' 'V1027' 'V1028' 'V1031' 'V1033'...
            'V1034' 'V1036' 'V1037' 'V1044' 'V1050' 'V1053'};


    
%%  get the individual data
basedir = '/home/language/annhul/MOUS/Processed/';
for k = 1:numel(subjlist)
load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_targetword_05-3ds-ag']);

%% Write number of accepted trials into text file
txtfile = strcat('/home/language/annhul/MOUS/Processed/MeanNumAvgTrials_ERF_tar_',date,'.txt');
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenWord mean:\t%d\t SD:\t%1.1f \tSeqWord mean:\t%d\t SD:\t%1.1f \n', ...
              datestr(now), subjlist{k}, round(mean(senWord_AG.dof(1:end))), std(senWord_AG.dof(1:end)),round(mean(seqWord_AG.dof(1:end))), std(seqWord_AG.dof(1:end)));          
if k == size(subjlist,2)
    fprintf('\n --------------------------------- \n');
end           
fclose(fid);

cmd = ['chmod g+w ' txtfile];
system(cmd);

end
fprintf('Updated number of averages file %s ', txtfile); % prints in command window


%% Target plus one
basedir = '/home/language/annhul/MOUS/Processed/';
for k = 1:numel(subjlist)
  %tmp = mous_db_getdata(subjlist{k}, 'meg_processed_...');
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_tarplusOne_05-3ds-ag']);

%% Write number of accepted trials into text file
txtfile = '/home/language/annhul/MOUS/Processed/MeanNumAcceptedAvg4ERF_tarplusOne_05-3_7July2012.txt';
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenTarPlusOne mean:%d \tSD:%1.1f  \tSeqTarPlusOne mean:%d \tSD:%1.1f \n', ...
              datestr(now), subjlist{k}, round(mean(senTarPlusOne_AG.dof(1:end))),std(senTarPlusOne_AG.dof(1:end)),round(mean(seqTarPlusOne_AG.dof(1:end))),std(seqTarPlusOne_AG.dof(1:end)));        
fclose(fid);
fprintf('Updated number of averages file %s ', txtfile);

cmd = ['chmod g+w ' txtfile];
system(cmd);

end

%%  Target plus two
basedir = '/home/language/annhul/MOUS/Processed/';
for k = 1:numel(subjlist)
  %tmp = mous_db_getdata(subjlist{k}, 'meg_processed_...');
  load([basedir subjlist{k} '/ERF/' subjlist{k} 'ERF_tarplusTwo_05-3ds-ag']);

%% Write number of accepted trials into text file
txtfile = '/home/language/annhul/MOUS/Processed/MeanNumAcceptedAvg4ERF_tarplusTwo_05-3_7July2012.txt';
fid = fopen(txtfile, 'a');
fprintf(fid, '%s %s SenTarPlusTwo mean:%d \tSD:%1.1f  \tSeqTarPlusTwo mean:%d \tSD:%1.1f \n', ...
             datestr(now), subjlist{k}, round(mean(senTarPlusTwo_AG.dof(1:end))),std(senTarPlusTwo_AG.dof(1:end)),round(mean(seqTarPlusTwo_AG.dof(1:end))),std(seqTarPlusOne_AG.dof(1:end)),round(mean(senTarPlusTwo_AG.dof(1:end))), std(senTarPlusTwo_AG.dof(1:end)),round(mean(seqTarPlusTwo_AG.dof(1:end))), std(seqTarPlusTwo_AG.dof(1:end)));
fclose(fid);
fprintf('Updated number of averages file %s ', txtfile);

cmd = ['chmod g+w ' txtfile];
system(cmd);

end