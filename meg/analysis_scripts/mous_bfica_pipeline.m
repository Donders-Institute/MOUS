
dodss    = false;
dofreq   = false;
dosource = false;
dovox    = false;
doica    = true;

if dodss,
  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  mous_db_putdata(subjectname, 'meg_processed_{bfICA_comp}', comp, avgcomp, avgpre);
end

%toi = 0.375;
%toi = 0.5;
if dofreq,
  % theta frequency
  %freq   = mous_bfica_freq(subjectname, 5);
  %mous_db_putdata(subjectname, 'meg_processed_{bfICA_freq5}', freq);
  
  % beta frequency
  freq   = mous_bfica_freq(subjectname, 20);
  mous_db_putdata(subjectname, 'meg_processed_{bfICA_freq}', freq);
end
if dosource,
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_processed_{bfICA_freq5}');
  %source = mous_bfica_source(subjectname, freq, toi);
  %mous_db_putdata(subjectname, ['meg_processed_{bfICA_source5_',num2str(round(toi*1000)),'}'], source);
  
  freq   = mous_db_getdata(subjectname, 'meg_processed_{bfICA_freq}');
  source = mous_bfica_source(subjectname, freq);
  %mous_db_putdata(subjectname, ['meg_processed_{bfICA_source',num2str(round(toi*1000)),'}'], source);
  mous_db_putdata(subjectname, 'meg_processed_{bfICA_source}', source);
end
if dovox,
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_processed_{bfICA_freq5}');
  %source = mous_db_getdata(subjectname, ['meg_processed_{bfICA_source5_',num2str(round(toi*1000)),'}']);
  %sourcedata = mous_bfica_sourcedata(source, freq, toi);
  %mous_db_putdata(subjectname, ['meg_processed_{bfICA_sourcedata5_',num2str(round(toi*1000)),'}'], sourcedata);
  
  freq   = mous_db_getdata(subjectname, 'meg_processed_{bfICA_freq}');
  source = mous_db_getdata(subjectname, 'meg_processed_{bfICA_source}');
  sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
  mous_db_putdata(subjectname, 'meg_processed_{bfICA_sourcedata}', sourcedata);
end

if doica,
  
  comp = mous_bfica_ica(subjectname);
  mous_db_putdata(subjectname, 'meg_processed_{bfICA_ica}', comp);
end


% 
% % do ica -> can this be done on single subject if sufficient data is
% % present?
% cfg = [];
% cfg.demean       = 'no'; % do outside the function is possibly more memory efficient
% cfg.method       = 'fastica';
% cfg.fastica.lastEig = 100;
% comp = ft_componentanalysis(cfg, sdata);
