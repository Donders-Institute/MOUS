% This script extracts the SubjectName, QuestionNr and responses from
% all specified logfiles.

%% Get responses for single trials
AllFiles = {'V1001',	'V1002',	'V1003',	'V1004',	'V1005',	'V1006',	'V1007',	'V1008',	'V1009',	'V1010',...
            'V1011',	'V1012',	'V1013',	'V1015',	'V1016',	'V1017-5',	'V1017-6',	'V1019',	'V1020',...
            'V1021',	'V1022',	'V1023',	'V1024',	'V1025',	'V1026',	'V1027',	'V1028',	'V1029',	'V1030',...
            'V1031',	'V1032',	'V1033',	'V1034',	'V1035',	'V1036',	'V1037',	'V1038',	'V1039',	'V1040',...
            'V1042',	'V1044',	'V1045',	'V1046',	'V1048',	'V1049',	'V1050',...
           	'V1052',	'V1053',	'V1054',	'V1055',	'V1057',	'V1058',	'V1059',...
            'V1061',	'V1062',	'V1063',	'V1064',	'V1065',	'V1066',	'V1068',	'V1069',	'V1070',...
            'V1071',	'V1072',	'V1073',	'V1074',	'V1075',	'V1076',	'V1077',	'V1078',	'V1079',	'V1080',...
            'V1081',	'V1083',	'V1084',	'V1085',	'V1086',	'V1087',	'V1088',	'V1089',	'V1090',...
          	'V1092',	'V1093',	'V1094',	'V1095',	'V1097',	'V1098',	'V1099',	'V1100',...
            'V1101',	'V1102',	'V1103',	'V1104',	'V1105',	'V1106',	'V1107',	'V1108',	'V1109',	'V1110',...
            'V1111',	'V1113',	'V1114',	'V1115'};
%%
% In each iteration of the loop a logfile is opened, data are extracted
% as mentioned above and added to output array AllDataSingleTrials.

for j = 1:length(AllFiles)
    subjectname = AllFiles{j};
    try
        %% Get data
        % Read in logfile using another MOUS specific funtion. This one
        % again uses mous_db_getfilename in which some "bad subjects" are
        % hard coded and for those the whole script would stop. Therefore,
        % try/catch.
        [oritxt] = read_logfile_visual(subjectname);
        
        % Go through the logfile and check when the questions have been
        % presented
        wordpresent = zeros(size(oritxt));
        for m = 1:size(oritxt,1)
            check = regexp(oritxt{m},'QUESTION \d\d\d');
            if ~isempty(check)
                wordpresent(m) = 1;
            end
        end
        %% Extract data
        % get entire row of the questions
        idx  = find(wordpresent == 1);
        resp  = oritxt(idx);
        % get QuestionNr (needed for conditions) and Subjnr from logfile
        % (not the running nr!), hardcoded difference between aud and vis
        % script Axxxx  vs Vxxxx
        A=[];
        C={};
        for k = 1:size(resp,1)
            questIndex = regexp(resp{k},'QUESTION \d\d\d');
            QueNr = resp{k}(questIndex+9:questIndex+11); % to only get the number
            A(3,k) = str2num(QueNr);
            
            SubnrInd = regexp(resp{k},'V\d\d\d\d');
            subname = resp{k}(SubnrInd+1:SubnrInd+4);
            subnr = str2num(subname);
            
        end
        QuestionNr = transpose(A);
        
        % mark the condition in another row
        for R = 1:length(QuestionNr)
            QuestionNr(R,1) = subnr;
            if QuestionNr(R,3) < 204
                QuestionNr(R,4) = 4;
            elseif QuestionNr(R,3) > 204 && QuestionNr(R,3) < 409
                QuestionNr(R,4) = 3;
            elseif QuestionNr(R,3) > 501 && QuestionNr(R,3) < 704
                QuestionNr(R,4) = 2;
            elseif QuestionNr(R,3) > 705
                QuestionNr(R,4) = 1;
            end
        end
        % Check for ppt's responses 'incorrect'
        logincor  = zeros(size(resp));
        for m = 1:size(resp,1)
            checkincor = regexp(resp{m},'incorrect');
            if ~isempty(checkincor)
                QuestionNr(m,2) = 1;
            end
        end
        
        %% Save data
        if ~exist('AllTrials_Vis_meg','var')
            AllTrials_Vis_meg = QuestionNr;
        else
            AllTrials_Vis_meg = [AllTrials_Vis_meg;QuestionNr];
        end
        
        
        ok(j) = true;
    catch
        ok(j) = false;
    end
end
save('AllTrials_Vis_meg','AllTrials_Vis_meg')
