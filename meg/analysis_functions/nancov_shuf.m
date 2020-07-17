function [C] = nancov_shuf(datain1, datain2, shufvec)

if numel(shufvec)==1
  switch shufvec
    case 0
      C = nancov(datain1, datain2, 1, 2, 1);
    
  end
elseif size(shufvec,1)==1
  nsmp       = cellfun('size', datain1, 2);
  sampleaxis = 1:sum(nsmp);
  smpx       = mat2cell(sampleaxis, 1, nsmp);
  smpx_shuf1 = smpx(shufvec);
  tmp1       = cat(2, datain1{:});
  tmp1       = tmp1(:, cat(2, smpx_shuf1{:}));
  for m = 1:numel(smpx)
    datain1{m} = tmp1(:,smpx{m});
  end
  finite1 = isfinite(cellrowselect(datain1,1));
  finite2 = isfinite(cellrowselect(datain2,1));
  allfinite = finite1&finite2;
  C = nancov(cellcat(1,cellcolselect(datain2,allfinite), cellcolselect(datain1,allfinite)), 1, 2, 1);
elseif size(shufvec,1)==2
  tmp1 = cat(2, datain1{:});
  tmp2 = cat(2, datain2{:});
      
  nsmp       = cellfun('size', datain1, 2);
  sampleaxis = 1:sum(nsmp);
  smpx       = mat2cell(sampleaxis, 1, nsmp);
  smpx_shuf1 = smpx(shufvec(1,:));
  smpx_shuf2 = smpx(shufvec(2,:));
  tmp1       = tmp1(:, cat(2, smpx_shuf1{:}));
  tmp2       = tmp2(:, cat(2, smpx_shuf2{:}));
  for m = 1:numel(smpx)
    datain1{m} = tmp1(:,smpx{m});
    datain2{m} = tmp2(:,smpx{m});
  end
  finite1 = isfinite(cellrowselect(datain1,1));
  finite2 = isfinite(cellrowselect(datain2,1));
  allfinite = finite1&finite2;
  C = nancov(cellcolselect(datain1,allfinite), cellcolselect(datain2,allfinite), 1, 2, 1);
end
