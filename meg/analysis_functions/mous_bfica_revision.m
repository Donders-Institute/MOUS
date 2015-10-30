function [output] = mous_bfica_revision(subjectname, suff, frequency)

% this function implements an analysis as requested by a reviewer:
% he/she asked for an erp-type of analysis, so that we can demonstrate
% the lack of effects, and make a stronger claim with respect to us
% describing the data in terms of oscillations.
%
% He/she asked for source reconstruction of bandpassfiltered erps.
% We do it as follows: adopt the same general strategy as the bfica pipeline,
% with the sole difference that we project the avg(fourier) through the spatial
% filters, rather than computing a per trial power, and average that.
% Our approach should be more or less equivalent to what the reviewer asks for.

rootdir = '/project/3011020.09/MEG/';

% get the sensor level frequency data
if str2num(subjectname(3:end)) < 100 && strcmp(suff,'high')
  load(['/home/language/jansch/tmp/mous/bfica_tmp/',subjectname,'_bfica_freq_', suff]); 
else
  mous_db_getdata(subjectname, ['meg_bfica_freq_',suff], rootdir);
  ntap = 1;
end
freq = ft_struct2double(freq);
freq.cumtapcnt = ones(size(freq.fourierspctrm,1)./ntap,1)*ntap;   % ntap = 1 for hanning taper, 3 for multitaper

cfg = [];
cfg.frequency = frequency;
cfg.latency   = [-0.1 0.6];
freq = ft_selectdata(cfg, freq);

% source estimates across all time points  
freq.cfg.t_ftimwin = freq.cfg.previous.t_ftimwin(1);
[source, trialinfo] = mous_bfica_source(subjectname, freq, [], 8, rootdir,0);  % compute spatial filter
sourcedataorig      = mous_bfica_sourcedata(source, freq, [], 0);
[trial,time,trialinfonew] = trial2words(sourcedataorig.trial{1},sourcedataorig.trialinfo(:,[1 5 8 2:4 6 7]),freq.time);
%NOTE: I had to use the eighth column of the trialinfo matrix. It could be
%that along the way an extra column with information has been added. I am
%not sure when this occurred, and what the relationship is with the last
%time the Nietzsche ran her pipeline. The git version of the bfica pipeline
%has a hardcoded 7th column at this step, which yields incorrect results
%when having multiple time points in the input!!!! VERIFY

% now we can use the trialinfonew matrix to select and compare

% get sentence words, third column has trigger
sel1 = find(ismember(trialinfonew(:,3),[1 2 5 6]));

% get sequence words
sel2 = find(ismember(trialinfonew(:,3),[3 4 7 8]));

% some dummy variable, the need to have this should be cleaned up at some point in the
% low-level function
s.X = 1;

params          = [];
params.demean   = 0;
[early1, late1] = extract_earlylate(trialinfonew(sel1,[1 3 4 5 2 6 7])); % shuffle the columns to get wordid and original sentenceid in column 5 and 6
[early2, late2] = extract_earlylate(trialinfonew(sel2,[1 3 4 5 2 6 7]));

nmin = min(numel(sel1),numel(sel2));
sel1n = sort(sel1(randperm(numel(sel1),nmin)));
sel2n = sort(sel2(randperm(numel(sel2),nmin)));

nmin   = min([numel(early1),numel(late1),numel(early2),numel(late2)]);
early1 = sort(early1(randperm(numel(early1),nmin)));
early2 = sort(early2(randperm(numel(early2),nmin)));
late1 = sort(late1(randperm(numel(late1),nmin)));
late2 = sort(late2(randperm(numel(late2),nmin)));

% all sentence words
tmptrial          = trial(sel1n);
tmptime           = time(sel1n);
params.time       = tmptime;
[~,~,erf.avgsent] = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgsent] = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgsent] = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgsent(:,begsmp:endsmp);
end
[~,~,pow2.avgsent] = denoise_avg2(params,abs(tmptrial).^2,s);

% all early words
tmptrial          = trial(sel1(early1));
tmptime           = time(sel1(early1));
params.time       = tmptime;
[~,~,erf.avgsent_early] = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgsent_early] = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgsent_early] = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgsent_early(:,begsmp:endsmp);
end
[~,~,pow2.avgsent_early] = denoise_avg2(params,abs(tmptrial).^2,s);

% all late words
tmptrial          = trial(sel1(late1));
tmptime           = time(sel1(late1));
params.time       = tmptime;
[~,~,erf.avgsent_late] = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgsent_late] = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgsent_late] = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgsent_late(:,begsmp:endsmp);
end
[~,~,pow2.avgsent_late] = denoise_avg2(params,abs(tmptrial).^2,s);

% all word list words
tmptrial          = trial(sel2n);
tmptime           = time(sel2n);
params.time       = tmptime;
[~,~,erf.avgseq]  = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgseq]  = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgseq]  = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgseq(:,begsmp:endsmp);
end
[~,~,pow2.avgseq] = denoise_avg2(params,abs(tmptrial).^2,s);

% all early word list words
tmptrial          = trial(sel2(early2));
tmptime           = time(sel2(early2));
params.time       = tmptime;
[~,~,erf.avgseq_early]  = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgseq_early]  = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgseq_early]  = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgseq_early(:,begsmp:endsmp);
end
[~,~,pow2.avgseq_early] = denoise_avg2(params,abs(tmptrial).^2,s);

% all late word list words
tmptrial          = trial(sel2(late2));
tmptime           = time(sel2(late2));
params.time       = tmptime;
[~,~,erf.avgseq_late] = denoise_avg2(params,tmptrial,s);
[~,~,pow.avgseq_late] = denoise_avg2(params,abs(tmptrial).^2,s);
[~,~,itc.avgseq_late] = denoise_avg2(params,tmptrial./abs(tmptrial),s);
for k = 1:numel(tmptrial)
  begsmp = nearest(freq.time, tmptime{k}(1));
  endsmp = nearest(freq.time, tmptime{k}(end));
  tmptrial{k} = tmptrial{k}-erf.avgseq_late(:,begsmp:endsmp);
end
[~,~,pow2.avgseq_late] = denoise_avg2(params,abs(tmptrial).^2,s);

% post processing
itc.avgsent = abs(itc.avgsent);
itc.avgsent_early = abs(itc.avgsent_early);
itc.avgsent_late  = abs(itc.avgsent_late);
itc.avgseq = abs(itc.avgseq);
itc.avgseq_early = abs(itc.avgseq_early);
itc.avgseq_late  = abs(itc.avgseq_late);

erf.avgsent = abs(erf.avgsent).^2;
erf.avgsent_early = abs(erf.avgsent_early).^2;
erf.avgsent_late  = abs(erf.avgsent_late).^2;
erf.avgseq = abs(erf.avgseq).^2;
erf.avgseq_early = abs(erf.avgseq_early).^2;
erf.avgseq_late  = abs(erf.avgseq_late).^2;

output = struct('pow2', pow2, 'pow',pow,'itc',itc,'erf',erf,'time',freq.time,'freq',frequency);
