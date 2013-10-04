function [stat,sent,seq,datsent,datseq] = mous_mne_groupanalysis(subj, suffix, rootdir)

if nargin==2
  rootdir = '';
end

% load in the data
for k = 1:numel(subj)
  mous_db_getdata(subj{k}, ['meg_mne_',suffix,'-sent'], rootdir);
  
  if k==1
    tmp.pos  = source.pos;
    tmp.time = source.time(1:4:end);
    tmp.tri  = source.tri;
    tmp.inside  = source.inside;
    tmp.outside = source.outside;
    tmp.method  = 'average';
  end
  tmp.avg.pow = ft_preproc_smooth(source.avg.pow,4);
  tmp.avg.pow = tmp.avg.pow(:,1:4:end);
  tmp.avg.dspm = ft_preproc_smooth(source.avg.dspm,4);
  tmp.avg.dspm = tmp.avg.dspm(:,1:4:end);
  sent{k} = tmp;
  
  mous_db_getdata(subj{k}, ['meg_mne_',suffix,'-seq'], rootdir);
  tmp.avg.pow = ft_preproc_smooth(source.avg.pow,4);
  tmp.avg.pow = tmp.avg.pow(:,1:4:end);
  tmp.avg.dspm = ft_preproc_smooth(source.avg.dspm,4);
  tmp.avg.dspm = tmp.avg.dspm(:,1:4:end);
  seq{k} = tmp;
end

Nsubj = numel(sent);
for k = 1:Nsubj
  sent{k}.dim = [8196 1 1];
  seq{k}.dim  = [8196 1 1];
end

cfg = [];
cfg.method = 'montecarlo';
cfg.statistic = 'difference';
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
cfg.ivar   = 1;
cfg.uvar   = 2;
cfg.numrandomization = 10;
cfg.parameter = 'avg.pow';
stat = ft_sourcestatistics(cfg,sent{:},seq{:});

datsent = zeros(size(stat.stat));
datseq  = zeros(size(stat.stat));
for k = 1:Nsubj
  datsent = datsent+sent{k}.avg.pow;
  datseq  = datseq+seq{k}.avg.pow;
end
datsent = datsent./Nsubj;
datseq  = datseq./Nsubj;





% function [tmp1,tmp2] = mous_mne_groupanalysis(s1, s2, subjectname, smooth, spatialds)
% 
% 
%   % subselect time
%   tim1 = nearest(s1.time, -0.2); 
%   tim0 = nearest(s1.time, 0);
%   tim2 = nearest(s1.time, 0.9);
%   bsl1 = nanmean(s1.avg.dspm(:,tim1:tim0),2);
%   s1.avg.dspm = s1.avg.dspm(:,tim1:tim2);
%   s1.time     = s1.time(tim1:tim2);
%   tim1 = nearest(s2.time, -0.1);
%   tim0 = nearest(s2.time, 0);
%   tim2 = nearest(s2.time, 0.9);
%   bsl2 = nanmean(s2.avg.dspm(:,tim1:tim0),2);
%   s2.avg.dspm = s2.avg.dspm(:,tim1:tim2);
%   s2.time     = s2.time(tim1:tim2);
% 
%   % subtract average baseline across conditions
%   bsl = (bsl1+bsl2)./2;
%   s1.avg.dspm = s1.avg.dspm - bsl*ones(1,numel(s1.time));
%   s2.avg.dspm = s2.avg.dspm - bsl*ones(1,numel(s2.time));
%   
%   % interpolate to 3D
%   tmp1 = mous_mne_2dto3d(subjectname, s1, 'parameter', 'avg.dspm', 'interpmethod', 'nearest');%, 'insidemethod', 'source');
%   tmp2 = mous_mne_2dto3d(subjectname, s2, 'parameter', 'avg.dspm', 'interpmethod', 'nearest');%, 'insidemethod', 'source');
%   
%   
%   % spatial smoothing
%   if smooth == 1 
%       ft_hastoolbox('spm8', 1);
%       dum = zeros(tmp1.dim);
%       for m = 1:numel(tmp1.time)
%         dum(:) = 0;
%         dum(:) = tmp1.avg.dspm(:,m);
%         spm_smooth(dum,dum,1); % fwhm = 1 which is ~ 0.8 cm
%         tmp1.avg.dspm(:,m) = dum(:);
%         dum(:) = 0;
%         dum(:) = tmp2.avg.dspm(:,m);
%         spm_smooth(dum,dum,1); % fwhm = 1 which is ~ 0.8 cm
%         tmp2.avg.dspm(:,m) = dum(:);
%       end  
%   end
%   
%   
%   % spatial downsampling
%   if spatialds == 1 
%   dum   = reshape(1:prod(tmp1.dim), tmp1.dim);
%   invol = zeros(size(dum));
%   invol(tmp1.inside) = 1;
%   invol(1:2:end,1:2:end,1:2:end) = invol(1:2:end,1:2:end,1:2:end) + 1; 
% 
% 
%   sel   = dum(1:2:end,1:2:end,1:2:end);
%   sel   = sel(:);
%   invol = invol(1:2:end,1:2:end,1:2:end);
%   in    = find(invol==2);
%   out   = find(invol~=2);
%  
%   tmp1.pos      = tmp1.pos(sel,:);
%   tmp1.avg.dspm = tmp1.avg.dspm(sel,:);
%   tmp1.inside   = in;
%   tmp1.outside  = out;
%   tmp1.dim      = size(invol);
%   
%   tmp2.pos      = tmp2.pos(sel,:);
%   tmp2.avg.dspm = tmp2.avg.dspm(sel,:);
%   tmp2.inside   = in;
%   tmp2.outside  = out;
%   tmp2.dim      = size(invol);
%   end
% 
% 
