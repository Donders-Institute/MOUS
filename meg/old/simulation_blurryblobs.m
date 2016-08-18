% this script is aiming to make a point about an issue that is related with
% the large number of subjects versus spread of activity in MEG

% let's consider 2 activated regions

act1 = [gausswin(200,5);zeros(100,1)];
act2 = [zeros(100,1);gausswin(200,5)];

figure;plot(act1+act2);

% let's make a 1000 'subjects' worth of data: random amplitude, but
% the amplitude consistently larger in condition 1 than in condition 2
ampl1_cond1 = rand(1000,1).*1.25;
ampl1_cond2 = rand(1000,1).*1;

ampl2_cond1 = rand(1000,1).*1.25;
ampl2_cond2 = rand(1000,1).*1;

figure;plot(ampl1_cond1); hold on;plot(ampl1_cond2, 'r');


dat1 = (rand(1000,300)).*0.1 + ampl1_cond1*act1' + ampl2_cond1*act2';
dat2 = (rand(1000,300)).*0.1 + ampl1_cond2*act1' + ampl2_cond2*act2';


N = [10 20 50 100 200 500 1000];
for k = 1:numel(N)
  
  Nsubj = N(k);
  
  dat    = [dat1(1:Nsubj,:)' dat2(1:Nsubj,:)'];
  design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg = [];
  cfg.ivar = 1;
  cfg.uvar = 2;
  
  stat(k) = ft_statfun_depsamplesT(cfg,dat,design);
end
figure;plot(cat(2,stat.stat));



