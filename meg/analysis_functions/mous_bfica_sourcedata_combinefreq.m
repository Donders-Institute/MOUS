function mous_bfica_sourcedata_combinefreq(subjectname, prefix, freqs, savesuffix)

rootdir = '/project/3011020.09/MEG/';
switch prefix
  case 'sourcedatasentseq'
     freqsent  = appendstuff(subjectname, prefix, freqs, 'tlcksent');
     freqseq   = appendstuff(subjectname, prefix, freqs, 'tlckseq');
     freqtstat = appendstuff(subjectname, prefix, freqs, 'tstat');        
     
     mous_db_putdata(subjectname, ['meg_bfica_',prefix,'_',savesuffix],'freqsent','freqseq','freqtstat',rootdir);
  case 'sourcedatasentpar'
  case 'sourcedataseqpar'
  otherwise
    error('unknown prefix specified');
end

function data = appendstuff(subjectname, prefix, freqs, fieldname)

for k = 1:numel(freqs)
  suff = [prefix,num2str(freqs(k)*10),'_dft'];
  filename = mous_db_getfilename(subjectname,['meg_bfica_',suff]);
  dum      = load(filename{1});
  
  tmpdata = dum.(fieldname);
  clear dum;
  
  if isstruct(tmpdata)
    if k == 1
      data = tmpdata;
      % reshape into 3D matrix: source_freq_time for .avg and .var fields
      data.avg = reshape(tmpdata.avg,[size(tmpdata.avg,1),1,size(tmpdata.avg,2)]);
      data.var = reshape(tmpdata.var,[size(tmpdata.var,1),1,size(tmpdata.var,2)]);
    else
      data.avg(:,k,:) = tmpdata.avg;
      data.var(:,k,:) = tmpdata.var;
    end
  elseif isnumeric(tmpdata)
    if k == 1
      data = reshape(tmpdata,[size(tmpdata,1),1,size(tmpdata,2)]);
    else      
      data(:,k,:)    = tmpdata;
    end
  end
end 
if isstruct(tmpdata)
  data.freq = freqs;
  data.dimord = 'chan_freq_time';
end


