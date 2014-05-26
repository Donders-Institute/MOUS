% This script extracts the SubjectName, QuestionNr and responses from
% all specified logfiles.
% updated on 22 May 2014 to reflect and updated set of subjectnames and to
% correct the code NL

%% Get responses for single trials
AllFiles = {'A2001',	'A2002',	'A2003',	'A2004',	'A2005',	'A2006',	'A2007',	'A2008',	'A2009',...
  'A2010',	'A2011',	'A2012',	'A2013',	'A2014',	'A2015',	'A2016',	'A2017',  'A2018',	'A2019',	'A2020',...
  'A2021',	'A2023',	'A2024',	'A2025',	'A2026',	'A2027',	'A2028',	'A2029',	'A2030',...
  'A2031',	'A2032',	'A2033',	'A2034',	'A2035',	'A2036',	'A2037',	'A2038',	'A2039',	'A2040',...
  'A2041',	'A2042',	'A2046',	'A2047',	'A2048',	'A2049',	'A2050',...
  'A2051',	'A2052',	'A2053',	'A2055',	'A2056',	'A2057',	'A2058',	'A2059',	'A2060',...
  'A2061',	'A2062',	'A2063',	'A2064',	'A2065',	'A2066',	'A2067',	'A2068',	'A2069',	'A2070',...
  'A2071',	'A2072',	'A2073',	'A2075',	'A2076',	'A2077',	'A2078',	'A2079',	'A2080',...
  'A2083',	'A2084',	'A2085',	'A2086',	'A2088',	'A2089',	'A2090',...
  'A2091',	'A2092',	'A2094',	'A2095',	'A2096',	'A2097',	'A2098',	'A2099',...
  'A2101',	'A2102',	'A2103',	'A2104',	'A2105',	'A2106',	'A2108',	'A2109',	'A2110',...
  'A2111',	'A2112',	'A2113',	'A2114'};

% N.B. subjects A2001, A2018 had no questions in the MEG experiment because of coding
% error in Presentation file. 
% Annika updated this afterwards for subsequent subjects using scenario 6.
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
            
            SubnrInd = regexpi(resp{k},'A\d\d\d\d');
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
        if ~exist('AllTrials_Aud_meg','var')
            AllTrials_Aud_meg = QuestionNr;
        else
            AllTrials_Aud_meg = [AllTrials_Aud_meg;QuestionNr];
        end
        
        
        ok(j) = true;
    catch
        ok(j) = false;
    end
end
save('AllTrials_Aud_meg','AllTrials_Aud_meg')
