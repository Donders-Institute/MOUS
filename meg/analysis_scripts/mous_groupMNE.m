%'V1013'  Something wrong with file

list = {'V1004' 'V1005' 'V1007' 'V1010' 'V1011' 'V1012' 'V1015' 'V1016' 'V1017'...
        'V1019' 'V1020' 'V1021' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
        'V1030' 'V1032' 'V1034' 'V1036' 'V1037' 'V1039' 'V1042' ...
        'V1044' 'V1045' 'V1046' 'V1049' 'V1050' 'V1052' 'V1066' 'V1067' 'V1068' 'V1071' ...
        'V1072' 'V1077'};
%     

    for k= 1:length(list)
      subjectname = list{k};
      
     %[filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_target_Sent_20121122}');
     [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent_20121126}');
     load(filename{1})
     source3d_Sent = mous_mne_2dto3d(subjectname, sd_Sent);
     %save normalized source ?
          
      %[filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_target_Seq_20121122}');
     [filename, st] = mous_db_getfilename(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq_20121126}');
     load(filename{1})
     source3d_Seq = mous_mne_2dto3d(subjectname, sd_Seq);
     %save normalized source ?
    
    end
   
    % should all the normalized sources be saved in one file and if so, in a struct
    % array or something else? If not should the cfg.inputfile parameter contain a list of filenames? 
         
   %load all normalized sources ?
   cfg = [];
   cfg.parameter          = 'avg.pow'; %or should it be simply 'pow'?
   cfg.keepindividual     = 'yes' ;
   cfg.imputfile          = '*sent.mat*'; %source3d
   [ga_sent] = ft_sourcegrandaverage(cfg, subjcect1, subject2);
     
   cfg.imputfile          = '*seq.mat*'; %source3d
   [ga_seq] = ft_sourcegrandaverage(cfg, subjcect1, subject2);

    cfg = [];
   cfg.parameter          = 'avg.pow';
   cfg.method             = 'montecarlo' ;
   [stat] = ft_sourcestatistics(cfg, ga_seq, ga_sent); % not sure how this function does the group stats

    
    cfg = [];
    cfg.funparameter='avg.pow';
    cfg.interactive='yes';
    figure;ft_sourceplot(cfg, source3d);

 