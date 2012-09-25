function [h1,h2] = mous_artifact_qualitycheck(subjectname)

% MOUS_ARTIFACT_QUALITYCHECK does a quality control check on the
% ouput of the artifact pipeline, mrelying on visual inspection of a
% number of output figures, generated from the output from the dss artifact
% identification.
%
% Use as
%   mous_artifact_qualitycheck(subjectname)
%
% For example
%   mous_artifact_qualitycheck('V1020')
%
% See also MOUS_ARTIFACT_PIPELINE

cfgart = mous_db_getdata(subjectname, 'meg_artifactcfg');

% the idea is to generate figures summarizing the artifacts
for k = 1:numel(cfg)
  % do it for each of the artifact types
  
  % read in the MEG-data corresponding to the identified intervals
  cfg = [];
  cfg.dataset    = cfgart{k}.dataset;
  cfg.continuous = 'yes';
  cfg.trl        = cfgart{k}.artfctdef.zvalue.artifact;
  cfg.trl(:,1)   = cfg.trl(:,1) - 120;
  cfg.trl(:,2)   = cfg.trl(:,2) + 120;
  cfg.trl(:,3)   = cfg.trl(:,1) - mean(cfg.trl,2);
  cfg.channel    = 'MEG';
  cfg.demean     = 'yes';
  data           = ft_preprocessing(cfg);

  % visualize it in a butterfly plot
  Nart = numel(data.trial);
  
  % come up with a trick to generate more than one figure, if the number of artifacts>100
  Ncol = 10;
  Nrow = 10;
  for m = 1:Nart
    hpos = mod(m-1,Ncol)*0.1;
    vpos = 1 - floor((m-1)/10)*0.1;
    
    ft_plot_vector(data.time{m},data.trial{m},'width',0.09,'height',0.09,'hpos',hpos,'vpos',vpos,'color','k');
    
  end


  % we will use ft_plot_vector for efficiency

end
