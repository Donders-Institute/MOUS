function [f] = plot_spectra(A, varargin)

globalscale = ft_getopt(varargin, 'globalscale', true);
plotstyle   = ft_getopt(varargin, 'plotstyle', 'median');
zlim        = ft_getopt(varargin, 'zlim',      'zeromax');
addbar      = ft_getopt(varargin, 'addbar',    []);
cmap        = ft_getopt(varargin, 'colormap',  []);
patchcolor  = ft_getopt(varargin, 'patchcolor', [0.6 0.6 0.6]);
linecolor   = ft_getopt(varargin, 'linecolor', [0 0 0]);

for k = 1:size(A,3)
  if iscell(patchcolor)
    pcolor = patchcolor{k}(1,:);
  else
    pcolor = patchcolor;
  end
  if iscell(linecolor)
    lcolor = linecolor{k}(1,:);
  else
    lcolor = linecolor;
  end
  plotstring = false;
  if ~isempty(A) && isnumeric(A)
    figure;
    if ndims(A)==3
      switch plotstyle
        case 'median'
          [q1,q2]=idealf(A(:,:,k),2);
          q = [q1' flipud(q2)' q1(1)];
          fax = [0:(size(A,1)-1) (size(A,1)-1):-1:0 0];
 
          hold on; patch(fax,q,pcolor,'edgecolor', 'none');
          plot(0:(size(A,1)-1), nanmedian(A(:,:,k),2), 'linewidth', 2, 'color', lcolor);
          
        otherwise
          if ~isempty(cmap)
            hold on;
            for m = 1:size(A,2)
              plot(0:(size(A,1)-1),A(:,m,k),'linewidth',2,'color',cmap(m,:));
            end
          else
            plot(0:(size(A,1)-1),A(:,:,k),'linewidth',2);
          end
      end
    else
      plot(0:(size(A,1)-1),A(:,k),'k');
    end
    abc = axis;
    if ischar(zlim)
    switch 'zlim',
      case 'zeromax'
        axis([0 size(A,1)-1 0 abc(4)]);
      otherwise
        axis([0 size(A,1)-1 abc(3:4)]);
    end
    else
      axis([0 size(A,1)-1 zlim]);
    end
    set(gca,'xtick',[0 10 25 50 75 100],'tickdir','out','fontname','arial','fontsize',16);
    xlabel('frequency (Hz)');
    ylabel('network strength (a.u.)');
    title(['component #',num2str(k)]);
    
    if ~isempty(addbar)
      plot(find(addbar(k,:)),zeros(1,sum(addbar(k,:))),'color','k','linewidth',3);
    end
      
  elseif ~isempty(A) && iscell(A)
    plotstring = true;
  end
  
  
  set(gcf,'color','white');
  %set(gcf,'renderer','painters');
  f(k) = getframe(gcf);
end
