% This script extracts the SubjectName, QuestionNr and responses from
% all specified logfiles.
% updated on 22 May 2014 to reflect and updated set of subjectnames and to
% correct the code NL

%% Get responses for single trials
subjectname = {'V1001',	'V1002',	'V1003',	'V1004',	'V1005',	'V1006',	'V1007',	'V1008',	'V1009',	'V1010',...
            'V1011',	'V1012',	'V1013',	'V1015',	'V1016',	'V1017',	'V1019',	'V1020',...
            'V1022',	'V1024',	'V1025',	'V1026',	'V1027',	'V1028',	'V1029',	'V1030',...
            'V1031',	'V1032',	'V1033',	'V1034',	'V1035',	'V1036',	'V1037',	'V1038',	'V1039',	'V1040',...
            'V1042',	'V1044',	'V1045',	'V1046',	'V1048',	'V1049',	'V1050',...
            'V1052',	'V1053',	'V1054',	'V1055',	'V1057',	'V1058',	'V1059',...
            'V1061',	'V1062',	'V1063',	'V1064',	'V1065',	'V1066',	'V1068',	'V1069',	'V1070',...
            'V1071',	'V1072',	'V1073',	'V1074',	'V1075',	'V1076',	'V1077',	'V1078',	'V1079',	'V1080',...
            'V1081',	'V1083',	'V1084',	'V1085',	'V1086',	'V1087',	'V1088',	'V1089',	'V1090',...
            'V1092',	'V1093',	'V1094',	'V1095',	'V1097',	'V1098',	'V1099',	'V1100',...
            'V1101',	'V1102',	'V1103',	'V1104',	'V1105',	'V1106',	'V1107',	'V1108',	'V1109',	'V1110',...
            'V1111',	'V1113',	'V1114',	'V1115',  'V1116',  'V1117'};
%%
% In each iteration of the loop a logfile is opened, data are extracted
% as mentioned above and added to output array AllDataSingleTrials.

for j = 1:numel(subjectname)
        %% Get data
        % Read in logfile using another MOUS specific funtion. This one
        % again uses mous_db_getfilename in which some "bad subjects" are
        % hard coded and for those the whole script would stop. Therefore,
        % try/catch.
        [oritxt] = read_logfile_visual(subjectname{j});
        
        % Check when the questions have been presented in logfile
        % sum(wordpresent) == total num questions
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
        % get QuestionNr, which corresponds to .wavfile name 
        % Subjnr = subjectname 
        % (not the running nr!), hardcoded difference between aud and vis
        % script Axxxx  vs Vxxxx
        A=[];
        C={};
        for k = 1:size(resp,1)
            qidx = regexp(resp{k},'QUESTION \d\d\d');
            QueNr = resp{k}(qidx+9:qidx+11); % to only get the number
            A(3,k) = str2num(QueNr);
            
            subnr = str2num(subjectname{j}(2:5));
        end
        QuestionNr = transpose(A);
        
        % mark the condition (triggers) in column 4
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
        
        if j == 1
          subjavg = zeros(numel(subjectname),3);
        end
        % all questions
        wrong = sum(QuestionNr(:,2));
        allq  = size(QuestionNr,1);
        subjavg(j,1) = ((allq-wrong)/allq)*100; % percentage correct per person
        
        % sent
        i = find(ismember(QuestionNr(:,4),[4 3]));
        tmp = QuestionNr(i,:);
        wrong = sum(tmp(:,2));
        allq  = size(tmp,1);
        subjavg(j,2) = ((allq-wrong)/allq)*100;
        
        % word lists
        i = find(ismember(QuestionNr(:,4),[1 2]));
        tmp = QuestionNr(i,:);
        wrong = sum(tmp(:,2));
        allq  = size(tmp,1);
        subjavg(j,3) = ((allq-wrong)/allq)*100;

        %% Save data
        if j == 1
            SingleTrialResponse_vis_meg = QuestionNr;
        else
            SingleTrialResponse_vis_meg = [SingleTrialResponse_vis_meg;QuestionNr];
        end
end

grpdesc(1,:) = mean(subjavg);
grpdesc(2,:) = std(subjavg);

save('QuestionResponses_vis_meg_14Oct2014','SingleTrialResponse_vis_meg','subjavg','grpdesc');