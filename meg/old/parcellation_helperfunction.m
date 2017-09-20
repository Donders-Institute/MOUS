function out = parcellation_helperfunction(in, P, method)

% assume dimensionality of the data to be NxNx....

siz    = [size(in) 1];
if siz(1)==siz(2)
  isnxn = true;
else
  isnxn = false;
end

if isnxn
  newsiz = [siz(1) siz(2) prod(siz(3:end))];
  in     = reshape(in, newsiz);

  out(size(P,1), size(P,1), newsiz(3)) = 0;

  switch method
    case 'multiply'
      % loop over third dimension for efficient multiplication 
      for k = 1:size(in,3)
        tmp = in(:,:,k);
        tmp = parc_submethod(tmp, P, method);
        out(:,:,k) = tmp;
      end
    case 'trimmean'
      % do the trimmean without looping
      out = parc_submethod(in, P, method);
    otherwise
  end
  out = reshape(out, [size(out,1) size(out,2) siz(3:end)]);
else
  newsiz = [siz(1) prod(siz(2:end))];
  in     = reshape(in, newsiz);
  
  out(size(P,1), newsiz(2)) = 0;
  
  switch method
    case 'multiply_uni'
    case 'trimmean_uni'
      for k = 1:size(in,2)
        tmp = in(:,k);
        tmp = parc_submethod(tmp, P, method);
        out(:,k) = tmp;
      end
    otherwise
  end
  
  out = reshape(out, [size(out,1) siz(2:end)]);
end

function out = parc_submethod(in, P, method)

switch method
  case 'multiply'
    in(~isfinite(in))=0;
    out = P*in*P';
  case 'trimmean'
    P = P>0;
    n = size(P,1);
    out = zeros(n,n,size(in,3))+nan;
    for k = 1:n
      for m = 1:n
        tmp = reshape(in(P(k,:),P(m,:),:),sum(P(k,:))*sum(P(m,:)),[]);
        sel = sum(~isfinite(tmp), 2)==0;
        tmp = tmp(sel,:);
        switch size(tmp,1)
          case 0,
          case 1,
            out(k,m,:) = tmp;
          otherwise
            out(k,m,:) = trimmean(tmp,0.2,1);
          
        end
      end
    end
  case 'trimmean_uni'
    P = P>0;
    n = size(P,1);
    out = zeros(n,size(in,2))+nan;
    for k = 1:n
      tmp = in(P(k,:),:);
      sel = sum(~isfinite(tmp), 2)==0;
      tmp = tmp(sel,:);
      switch numel(tmp)
        case 0,
        case 1,
          out(k) = tmp;
        otherwise
          out(k,:) = trimmean(tmp,0.2);
      end
    end
  otherwise
end
 
