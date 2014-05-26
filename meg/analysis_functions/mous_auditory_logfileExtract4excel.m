
% This script will analyze the presentation logfiles from all auditory MEG
% subjects. The output is a mat file so that all information can be easily
% copied into an SPSS file. 

%% Create the basics
% go through all subjects as specified below, ugly but easiest to implement
% for now
% AllData cell array will contain all information

s = {'A2001',	'A2002',	'A2003',	'A2004',	'A2005',	'A2006',	'A2007',	'A2008',	'A2009',...
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

AllData = cell((length(s)+1),14);
AllData{1,1} = 'Subjectname';
AllData{1,2} = 'QuestionsTotal';
AllData{1,3} = 'IncorrRespTotal';
AllData{1,4} = 'CorrRespTotal';
AllData{1,5} = 'WordsRCIncorr';
AllData{1,6} = 'SentRCIncorr';
AllData{1,7} = 'WordsMixIncorr';
AllData{1,8} = 'SentMixIncorr';
AllData{1,9} = 'WordsRCCorr';
AllData{1,10} = 'SentRCCorr';
AllData{1,11} = 'WordsMixCorr';
AllData{1,12} = 'SentMixCorr';
AllData{1,13} = 'ErrorsIncorr';
AllData{1,14} = 'ErrorsCorr';
for j = 1:length(s)
    subjectname = s{j};
    try 
        
        % Read in logfile using another MOUS specific funtion. This one
        % again uses mous_db_getfilename in which some "bad subjects" are
        % hard coded and for those the whole script would stop. Therefore,
        % try/catch. Still, there is no output written for "bad subjects".
        % Work on that later.
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
        
        % Create new array with the entire row of the questions
        idx  = find(wordpresent == 1);
        resp  = oritxt(idx);
      
        % Create two array each the same size as resp
        logcor    = zeros(size(resp));
        logincor  = zeros(size(resp));
        
        % Check for ppt's responses 'hit' and 'incorrect' only in resp
        % array. This is is important to avoid that same patterns are
        % conuted as response, e.g. stimulus name= 'verhitte' is not a
        % response.
        for m = 1:size(resp,1)
            checkcor = regexp(resp{m},'hit');
            if ~isempty(checkcor)
                logcor(m) = 1;
            end
            checkincor = regexp(resp{m},'incorrect');          
            if ~isempty(checkincor)
                logincor(m) = 1;
            end
        end
        
        % Create new arrays with the entire row of the answers       
        respcor = resp(find(logcor == 1));
        respincor = resp(find(logincor == 1));
        
        % From all incorrect questions, calculate how many came from
        % sentence vs. words (sequences) condition. Question numbers for
        % sentences are 001-409, for words are 501-909.
        WordsRCIncorr=0;
        WordsMixIncorr=0;
        SentRCIncorr=0;
        SentMixIncorr=0;
        ErrorIncorr=0;
        
        for k = 1:size(respincor,1)
            questIndex = regexp(respincor{k},'QUESTION \d\d\d');
            QueNr = respincor{k}(questIndex+9:questIndex+11); % to only get the number
            QuestionNr = str2num(QueNr);        
            
            if QuestionNr < 204 
                SentRCIncorr = SentRCIncorr+1;
            elseif QuestionNr > 204 && QuestionNr < 409
                SentMixIncorr = SentMixIncorr+1;
            elseif QuestionNr > 501 && QuestionNr < 704
                WordsRCIncorr = WordsRCIncorr+1;
            elseif QuestionNr > 705
                WordsMixIncorr = WordsMixIncorr+1;
            else
                ErrorIncorr = ErrorIncorr+1;
            end
        end
        
        % Do the same for correct trials
        WordsRCCorr=0;
        WordsMixCorr=0;
        SentRCCorr=0;
        SentMixCorr=0;
        ErrorCorr=0;
        
        for k = 1:size(respcor,1)
            questIndex = regexp(respcor{k},'QUESTION \d\d\d');
            QueNr = respcor{k}(questIndex+9:questIndex+11);
            QuestionNr = str2num(QueNr);
            
            if QuestionNr < 204 
                SentRCCorr = SentRCCorr+1;
            elseif QuestionNr > 204 && QuestionNr < 409
                SentMixCorr = SentMixCorr+1;
            elseif QuestionNr > 501 && QuestionNr < 704
                WordsRCCorr = WordsRCCorr+1;
            elseif QuestionNr > 705
                WordsMixCorr = WordsMixCorr+1;
            else
                ErrorCorr = ErrorCorr+1;
            end
        end
        
       % Save everything in cell array
        
        AllData{j+1,1} = subjectname;
        AllData{j+1,2} = m;
        AllData{j+1,3} = numel(respincor);
        AllData{j+1,4} = numel(respcor);
        AllData{j+1,5} = WordsRCIncorr;
        AllData{j+1,6} = SentRCIncorr;
        AllData{j+1,7} = WordsMixIncorr;
        AllData{j+1,8} = SentMixIncorr;
        AllData{j+1,9} = WordsRCCorr;
        AllData{j+1,10} = SentRCCorr;
        AllData{j+1,11} = WordsMixCorr;
        AllData{j+1,12} = SentMixCorr;
        AllData{j+1,13} = ErrorIncorr;
        AllData{j+1,14} = ErrorCorr;
        save('DataSmry_Aud_MEG','AllData')
        
         ok(j) = true;
     catch
         ok(j) = false;
     end
end
