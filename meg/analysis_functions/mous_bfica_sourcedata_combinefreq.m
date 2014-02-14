function mous_bfica_sourcedata_combinefreq(subjectname, prefix, freqs, savesuffix)
% This function combines the source-level analyses done over time for each
% frequency, into one matrix holding all frequencies: source_freq_time
% N.B. dimord is 'chan_freq_time' as FieldTrip doesn't understand 'source'

% VARIABLES
% prefix = name of single-subject level contrast
% freqs  = frequency range
% savesuffix: 'low','medium','high' i.e. 2.5-12.5, 12-32, 40-100Hz for MOUS

if strcmp(subjectname(1),'V')
  rootdir = '/project/3011020.09/MEG/'; 
elseif strcmp(subjectname(1),'A')  % analyses not yet finalised therefore in nielam dir.
  rootdir = '/project/3011020.09/nielam/';
else
  error('unknown subject modality, use V1XX or A2XX');
end 

switch prefix
  case 'sourcedatasentseq'
    tlcksent  = appendstuff(subjectname, prefix, freqs, rootdir,'tlcksent');
    tlckseq   = appendstuff(subjectname, prefix, freqs, rootdir, 'tlckseq');
    tstat = appendstuff(subjectname, prefix, freqs, rootdir,'tstat');        
    
    mous_db_putdata(subjectname, ['meg_bfica_',prefix,'_',savesuffix],'tlcksent','tlckseq','tstat',rootdir);
  case 'sourcedatasentpar'
    
    tlcksentpar  = appendstuff(subjectname, prefix, freqs, rootdir, 'tlcksentpar');
    statsentpar  = appendstuff(subjectname, prefix, freqs, rootdir,'statsentpar');
    stat2sentpar = appendstuff(subjectname, prefix, freqs, rootdir, 'stat2sentpar');
     
    mous_db_putdata(subjectname, ['meg_bfica_',prefix,'_',savesuffix],'tlcksentpar','statsentpar','stat2sentpar',rootdir); 
  case 'sourcedataseqpar'
    
    tlckseqpar   = appendstuff(subjectname, prefix, freqs, rootdir, 'tlckseqpar');
    statseqpar  = appendstuff(subjectname, prefix, freqs, rootdir,'statseqpar');
    stat2seqpar = appendstuff(subjectname, prefix, freqs, rootdir,'stat2seqpar');
     
    mous_db_putdata(subjectname, ['meg_bfica_',prefix,'_',savesuffix],'tlckseqpar','statseqpar','stat2seqpar',rootdir); 
  otherwise
    error('unknown prefix specified');
end

function data = appendstuff(subjectname, prefix, freqs, rootdir,fieldname)

for k = 1:numel(freqs)
  if freqs(end) < 40
    suff = [prefix,num2str(freqs(k)*10)];
  elseif freqs(end) >= 40 && freqs(end) <= 100
    suff = [prefix,num2str(freqs(k)*10),'_dft'];  % next round of computations = remove dft
  end
  
  filename = mous_db_getfilename(subjectname,['meg_bfica_',suff],0,rootdir);
  dum      = load(filename{1});
  
  tmpdata = dum.(fieldname);
  clear dum;
  
  if isstruct(tmpdata)
    
    if isfield(tmpdata,'avg')
      if k == 1
        data = tmpdata;
        % reshape into 3D matrix: source_freq_time for .avg and .var fields
        data.avg = reshape(tmpdata.avg,[size(tmpdata.avg,1),1,size(tmpdata.avg,2)]);
        data.var = reshape(tmpdata.var,[size(tmpdata.var,1),1,size(tmpdata.var,2)]);
      else
        data.avg(:,k,:) = tmpdata.avg;
        data.var(:,k,:) = tmpdata.var;
      end
      
    elseif isfield(tmpdata,'stat')
      if k == 1
        data = tmpdata;
        % reshape into 3D matrix: source_freq_time for .avg and .var fields
        data.stat = reshape(tmpdata.stat,[size(tmpdata.stat,1),1,size(tmpdata.stat,2)]);
        data.prob = reshape(tmpdata.prob,[size(tmpdata.prob,1),1,size(tmpdata.prob,2)]);
        data.mask = reshape(tmpdata.mask,[size(tmpdata.mask,1),1,size(tmpdata.mask,2)]);
        data.cirange = reshape(tmpdata.cirange,[size(tmpdata.cirange,1),1,size(tmpdata.cirange,2)]);
      else
        data.stat(:,k,:) = tmpdata.stat;
        data.prob(:,k,:) = tmpdata.prob;
        data.mask(:,k,:) = tmpdata.mask;
        data.cirange(:,k,:) = tmpdata.cirange;
      end
    end
      
  elseif isnumeric(tmpdata)
    if k == 1
      data = reshape(tmpdata,[size(tmpdata,1),1,size(tmpdata,2)]);
    else      
      data(:,k,:)    = tmpdata;
    end
  end  % end numeric tmpdata i.e. 'tstat' variable
end    % end loop through frequency range
if isstruct(tmpdata)
  data.freq = freqs;
  data.dimord = 'chan_freq_time';
end


