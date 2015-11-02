outputdir = '/project/3011020.09/jansch/results/revision_oscillationpaper';

% theta
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',5,1);
save(fullfile(outputdir,'stats_theta_powbsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',5,0);
save(fullfile(outputdir,'stats_theta_pow_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',5,1);
save(fullfile(outputdir,'stats_theta_pow2bsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',5,0);
save(fullfile(outputdir,'stats_theta_pow2_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent-erf.avgseq',5,0);
save(fullfile(outputdir,'stats_theta_erf_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent-itc.avgseq',5,0);
save(fullfile(outputdir,'stats_theta_itc_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');

% alpha
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',10,1);
save(fullfile(outputdir,'stats_alpha_powbsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',10,0);
save(fullfile(outputdir,'stats_alpha_pow_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',10,1);
save(fullfile(outputdir,'stats_alpha_pow2bsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',10,0);
save(fullfile(outputdir,'stats_alpha_pow2_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent-erf.avgseq',10,0);
save(fullfile(outputdir,'stats_alpha_erf_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent-itc.avgseq',10,0);
save(fullfile(outputdir,'stats_alpha_itc_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');

% beta
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',16,1);
save(fullfile(outputdir,'stats_beta_powbsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent-pow.avgseq',16,0);
save(fullfile(outputdir,'stats_beta_pow_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',16,1);
save(fullfile(outputdir,'stats_beta_pow2bsl_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent-pow2.avgseq',16,0);
save(fullfile(outputdir,'stats_beta_pow2_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent-erf.avgseq',16,0);
save(fullfile(outputdir,'stats_beta_erf_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent-itc.avgseq',16,0);
save(fullfile(outputdir,'stats_beta_itc_sentseq'), 'stat', 'stat250', 'stat350', 'stat450');

% make ciftis
d = dir('stat*.mat');
for k = 1:numel(d)
  filename = d(k).name;
  load(d(k).name);
  fprintf('processing %s\n',filename);
  mous_mne_3dto2d(stat,'filename',[filename(1:end-4),'_time'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat250,'filename',[filename(1:end-4),'_250'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat350,'filename',[filename(1:end-4),'_350'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat450,'filename',[filename(1:end-4),'_450'],'parameter','stat','method','wb');
end

%%%%%%%%%%%%%%%%%%%
%do early vs late

% theta
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',5,1);
save(fullfile(outputdir,'stats_theta_powbsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',5,0);
save(fullfile(outputdir,'stats_theta_pow_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',5,1);
save(fullfile(outputdir,'stats_theta_pow2bsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',5,0);
save(fullfile(outputdir,'stats_theta_pow2_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent_late-erf.avgsent_early',5,0);
save(fullfile(outputdir,'stats_theta_erf_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent_late-itc.avgsent_early',5,0);
save(fullfile(outputdir,'stats_theta_itc_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');

% alpha
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',10,1);
save(fullfile(outputdir,'stats_alpha_powbsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',10,0);
save(fullfile(outputdir,'stats_alpha_pow_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',10,1);
save(fullfile(outputdir,'stats_alpha_pow2bsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',10,0);
save(fullfile(outputdir,'stats_alpha_pow2_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent_late-erf.avgsent_early',10,0);
save(fullfile(outputdir,'stats_alpha_erf_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent_late-itc.avgsent_early',10,0);
save(fullfile(outputdir,'stats_alpha_itc_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');

% beta
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',16,1);
save(fullfile(outputdir,'stats_beta_powbsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow.avgsent_late-pow.avgsent_early',16,0);
save(fullfile(outputdir,'stats_beta_pow_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',16,1);
save(fullfile(outputdir,'stats_beta_pow2bsl_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('pow2.avgsent_late-pow2.avgsent_early',16,0);
save(fullfile(outputdir,'stats_beta_pow2_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('erf.avgsent_late-erf.avgsent_early',16,0);
save(fullfile(outputdir,'stats_beta_erf_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');
[stat,stat250,stat350,stat450]=mous_bfica_revision_tmap('itc.avgsent_late-itc.avgsent_early',16,0);
save(fullfile(outputdir,'stats_beta_itc_sentlateearly'), 'stat', 'stat250', 'stat350', 'stat450');

% make ciftis
d = dir('stat*early*.mat');
for k = 1:numel(d)
  filename = d(k).name;
  load(d(k).name);
  fprintf('processing %s\n',filename);
  mous_mne_3dto2d(stat,'filename',[filename(1:end-4),'_time'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat250,'filename',[filename(1:end-4),'_250'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat350,'filename',[filename(1:end-4),'_350'],'parameter','stat','method','wb');
  mous_mne_3dto2d(stat450,'filename',[filename(1:end-4),'_450'],'parameter','stat','method','wb');
end
