function [stat GA_Sen GA_Seq] = mous_mne_groupanalysis(subjectnames)


for k = 1:numel(subjectnames)
  %tmp = mous_db_getdata(subjectnames{k}, 'meg_processed_{MNE02-1ds}');
  % assume the file to contain sd1 and sd2 variables 
  tmp  = mous_db_getdata(subjectnames{k},'meg_mne_{MNE02-1ds_Allwords_Sent_20121126}');
  tmp2 = mous_db_getdata(subjectnames{k},'meg_mne_{MNE02-1ds_Allwords_Seq_20121126}');
  
  s1 = [];
  s2 = [];
  for m = 1:numel(tmp)
    if strcmp(tmp{m}.varname, 'sd_Sent')
      s1 = tmp{m};
    end
  end
  for m = 1:numel(tmp2)
     if strcmp(tmp2{m}.varname, 'sd_Seq')
      s2 = tmp2{m};
     end
  end
  clear tmp;
  clear tmp2;
  
  % subselect time
  tim1 = nearest(s1.time, -0.1);
  tim2 = nearest(s1.time, 0.9);
  s1.avg.dspm = s1.avg.dspm(:,tim1:tim2);
  s1.time     = s1.time(tim1:tim2);
  s2.avg.dspm = s2.avg.dspm(:,tim1:tim2);
  s2.time     = s2.time(tim1:tim2);

  % interpolate to 3D
  tmp1 = mous_mne_2dto3d(subjectnames{k}, s1, 'parameter', 'avg.dspm', 'interpmethod', 'nearest');%, 'insidemethod', 'source');
  tmp2 = mous_mne_2dto3d(subjectnames{k}, s2, 'parameter', 'avg.dspm', 'interpmethod', 'nearest');%, 'insidemethod', 'source');
  
  % spatial smoothing 
  ft_hastoolbox('spm8', 1);
  dum = zeros(tmp1.dim);
  for m = 1:numel(tmp1.time)
    dum(:) = 0;
    dum(:) = tmp1.avg.dspm(:,m);
    spm_smooth(dum,dum,2);
    tmp1.avg.dspm(:,m) = dum(:);
    dum(:) = 0;
    dum(:) = tmp2.avg.dspm(:,m);
    spm_smooth(dum,dum,2);
    tmp2.avg.dspm(:,m) = dum(:);
  end  
  
  % spatial downsampling
  dum   = reshape(1:prod(tmp1.dim), tmp1.dim);
  invol = zeros(size(dum));
  invol(tmp1.inside) = 1;
  invol(1:2:end,1:2:end,1:2:end) = invol(1:2:end,1:2:end,1:2:end) + 1; 


  sel   = dum(1:2:end,1:2:end,1:2:end);
  sel   = sel(:);
  invol = invol(1:2:end,1:2:end,1:2:end);
  in    = find(invol==2);
  out   = find(invol~=2);
 
  tmp1.pos      = tmp1.pos(sel,:);
  tmp1.avg.dspm = tmp1.avg.dspm(sel,:);
  tmp1.inside   = in;
  tmp1.outside  = out;
  tmp1.dim      = size(invol);
  
  tmp2.pos      = tmp2.pos(sel,:);
  tmp2.avg.dspm = tmp2.avg.dspm(sel,:);
  tmp2.inside   = in;
  tmp2.outside  = out;
  tmp2.dim      = size(invol);

  dat1{k} = tmp1;
  dat2{k} = tmp2;
end

% if the the stat cacluation runs out memory, this intermediate data can be
% saved and and the rest of the code run step by step
% keyboard
% save MOUS/meg/mne/mne37subjStatsAllwords.mat dat2 dat1 stat subjectnames


% compute statistics
Nsubj = numel(dat1);
cfg           = [];
cfg.method    = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.parameter = 'avg.dspm';
cfg.numrandomization = 1000;
cfg.correctm = 'cluster';
cfg.design = [ones(1,Nsubj) 2*ones(1,Nsubj);1:Nsubj 1:Nsubj];
cfg.ivar   = 1;
cfg.uvar   = 2;
stat = ft_sourcestatistics(cfg, dat1{:}, dat2{:}); 


%compute grand averages

for n = 1:length(dat1)
    if n ==1
        temp1= dat1{1,n}.avg.dspm; 
        temp2 = dat2{1,n}.avg.dspm;
    else
        temp1= temp1+dat1{1,n}.avg.dspm;
        temp2= temp2+dat2{1,n}.avg.dspm;
    end
end

ga_temp1 =temp1/length(dat1);
ga_temp2 = temp2/length(dat2);

% copy the other necessary field to the array from the stat array
GA_Sen = stat;
tmp=cell(size(GA_Sen)); [GA_Sen(:).dspm]=ga_temp1(tmp{:});
GA_Sen.dspm = ga_temp1;
GA_Sen = rmfield(GA_Sen, 'stat');

GA_Seq = stat;
tmp=cell(size(GA_Seq)); [GA_Seq(:).dspm]=ga_temp2(tmp{:});
GA_Sen.dspm = ga_temp2;
GA_Seq = rmfield(GA_Seq, 'stat');


