
dodss    = false;
dofreq   = true;
dosource = false;
dovox    = false;
doica    = false;
dosourcedss = false;

rootdir  = '/home/language/jansch/public/mous/';

if dodss,
  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_comp}', comp, avgcomp, avgpre, rootdir);
end

%toi = 0.375;
%toi = 0.5;
if dofreq,
  % theta frequency
  %freq   = mous_bfica_freq(subjectname, 5);
  %mous_db_putdata(subjectname, 'meg_bfica_{_bfica_freq5}', freq);
  
  % beta frequency
  freq   = mous_bfica_freq(subjectname, 20);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_freq}', freq, rootdir);
end
if dosource,
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_freq5}');
  %source = mous_bfica_source(subjectname, freq, toi);
  %mous_db_putdata(subjectname, ['meg_bfica_{_bfica_source5_',num2str(round(toi*1000)),'}'], source);
  
  freq   = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_freq}', rootdir);
  source = mous_bfica_source(subjectname, freq);
  %mous_db_putdata(subjectname, ['meg_bfica_{_bfica_source',num2str(round(toi*1000)),'}'], source);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_source}', source, rootdir);
end

if dovox,
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_freq5}');
  %source = mous_db_getdata(subjectname, ['meg_bfica_{_bfica_source5_',num2str(round(toi*1000)),'}']);
  %sourcedata = mous_bfica_sourcedata(source, freq, toi);
  %mous_db_putdata(subjectname, ['meg_bfica_{_bfica_sourcedata5_',num2str(round(toi*1000)),'}'], sourcedata);
  
  freq   = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_freq}', rootdir);
  source = mous_db_getdata(subjectname, 'meg_bfica_{_bfica_source}', rootdir);
  sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_sourcedata}', sourcedata, rootdir);
end

if doica,
  comp = mous_bfica_ica(subjectname, [], rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_ica}', comp, rootdir);
end

if dosourcedss,
  comp = mous_bfica_sourcedatadss(subjectname, rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_{_bfica_sourcedatadss}', comp, rootdir);
end

% 
% % do ica -> can this be done on single subject if sufficient data is
% % present?
% cfg = [];
% cfg.demean       = 'no'; % do outside the function is possibly more memory efficient
% cfg.method       = 'fastica';
% cfg.fastica.lastEig = 100;
% comp = ft_componentanalysis(cfg, sdata);
