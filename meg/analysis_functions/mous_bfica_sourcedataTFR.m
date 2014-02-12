function mous_bfica_sourcedataTFR(subjectname)

freqs = 40:4:100;
rootdir = '/project/3011020.09/MEG/';
for k = 1:numel(freqs)
    suff = ['sourcedatasentseq',num2str(freqs(k)*10),'_dft'];
    filename = mous_db_getfilename(subjectname,['meg_bfica_',suff]);
    load(filename{1});
    
    if k == 1
      allfreqsent = tlcksent;
      % reshape into 3D matrix: source_freq_time for .avg and .var fields
      allfreqsent.avg = reshape(tlcksent.avg,[size(tlcksent.avg,1),1,size(tlcksent.avg,2)]);
      allfreqsent.var = reshape(tlcksent.var,[size(tlcksent.var,1),1,size(tlcksent.var,2)]);
      
      allfreqseq  = tlckseq;
      allfreqseq.avg = reshape(tlckseq.avg,[size(tlckseq.avg,1),1,size(tlckseq.avg,2)]);
      allfreqseq.var = reshape(tlckseq.var,[size(tlckseq.var,1),1,size(tlckseq.var,2)]);
      
      % FIXME: matlab precedence issue "tstat" is a function name in
      % matlab...
      allfreqtstat = reshape(tstat2,[size(tstat2,1),1,size(tstat2,2)]);
    else
      allfreqsent.avg(:,k,:) = tlcksent.avg;
      allfreqseq.avg(:,k,:)  = tlckseq.avg;
      allfreqtstat(:,k,:) = tstat2;
    end
end 

mous_db_putdata(subjectname,'meg_bfica_sourcedatasentseq_high','allfreqsent','allfreqseq','allfreqtstat',rootdir);

