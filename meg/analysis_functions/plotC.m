function plotC(C,A,P,flag)

if nargin<4
  flag = false;
end

load atlas_conte69_8196reg_LR_brodmann_subparc
load cortex_inflated_8196reg

figure;
h1=subplot(2,2,1);h1m=ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',P*nanmean(C(:,:,1),1)');
h2=subplot(2,2,2);h2m=ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',P*nanmean(C(:,:,1),2));
h4=subplot(2,2,4);h4m=ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',P*nanmean(C(:,:,1),2));
hlink=linkprop([h1 h2],{'cameraposition' 'cameraupvector' 'clim'});
hlink2=linkprop([h1 h4],{'cameraposition' 'cameraupvector'});
setappdata(h1,'graphics_linkprop',hlink);
setappdata(h1,'graphics_linkprop',hlink2);

if ~isempty(A)
subplot(2,2,3);h3m=plot(0:119,zeros(1,120));xlim([0 120]);
tmpA = A(:,ix);
end

ix=0;
while ix<size(A,2) 
ix=ix+1;
if flag
  tmpC = C(:,:,ix);
  sel  = find(tmpC(:)~=0);
  out  = boxplotrule(tmpC(sel),1);
  tmpC(sel(~out)) = 0;
  dat1 = sum(tmpC>0,1)';
  dat2 = sum(tmpC>0,2);
  
  datd = dat2-dat1;
else
  tmpC = C(:,:,ix);
  dC   = tmpC-tmpC';
  
  dat1 = mean(tmpC,1)';
  dat2 = mean(tmpC,2);
  datd = mean(dC,1)';
end

c  = max(abs([dat1;dat2]));
c2 = max(abs(datd));
 
set(h1m,'facevertexcdata',P*dat1); 
set(h2m,'facevertexcdata',P*dat2); 
if exist('h3m', 'var'), set(h3m,'ydata',tmpA); end
set(h4m,'facevertexcdata',P*datd);
caxis(h1,[0 c]);
caxis(h4,[-c2 c2]);
pause;
end

