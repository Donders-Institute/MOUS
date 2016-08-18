function [u,s,dat,mr,mi] = pca_realvsimag(datin)

n  = size(datin,2);
m  = mean(datin,2);
mr = real(m);
mi = imag(m);

dat     = [real(datin)-repmat(mr,[1 n]);imag(datin)-repmat(mi,[1 n])];
[u,s,v] = svd(dat*dat');
dat     = u'*dat;
dat     = dat(1,:)+1i*dat(2,:); 
