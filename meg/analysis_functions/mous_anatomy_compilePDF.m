function mous_anatomy_compilePDF

[f1,s1]=mous_db_getfilename('all','meg_anatomy_figure_sourcemodel2dslice1');
[f2,s2]=mous_db_getfilename('all','meg_anatomy_figure_sourcemodel2dslice2');
[f3,s3]=mous_db_getfilename('all','meg_anatomy_figure_sourcemodel2dslice3');
[f4,s4]=mous_db_getfilename('all','meg_anatomy_figure_sourcemodel2d');
[f5,s5]=mous_db_getfilename('all','meg_anatomy_figure_sourcemodel3d');
[f6,s6]=mous_db_getfilename('all','meg_anatomy_figure_headmodel');
[f7,s7]=mous_db_getfilename('all','meg_anatomy_figure_coreg');

sel = s1+s2+s3+s4+s5+s6+s7==7;
f   = cat(2,f1(sel),f2(sel),f3(sel),f4(sel),f5(sel),f6(sel),f7(sel));
f   = reshape(f',[numel(f) 1]);

cd('/home/language/jansch/');
%mkdir('tempfigs');
cd('tempfigs');  
cnt = 0;
for k = 1:numel(f)
  k
  [a,b,c] = fileparts(f{k});
  system(['convert ',f{k},' ',b,'.eps']);
  tmp = [b,'.eps'];
  d   = dir(tmp);
  if d.bytes>0
    cnt = cnt+1;
    f2{cnt} = tmp;
  end
end
makePDF(f2, 'anatomy_qualitycheck');