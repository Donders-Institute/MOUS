function mous_makePDF(pdfname, figlist)

% check whether the figures are in .eps format, otherwise convert
epslist = cell(size(figlist));
for k = 1:numel(figlist)
  [p,fn,e] = fileparts(figlist{k});
  if strcmp(e, '.eps')
    epslist{k} = figlist{k};
  else
    epslist{k} = fullfile(p,[fn '.eps']);
    fprintf('converting %s into %s\n', figlist{k}, epslist{k});
    system(['convert ',figlist{k},' ',epslist{k}]);
  end
end

str = 'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dEPSCrop -sOutputFile=';
str = [str, pdfname];
for k = 1:numel(epslist)
  str = [str, ' ', epslist{k}];
end

system(str);
for k = 1:numel(figlist)
  if ~strcmp(figlist{k},epslist{k})
    delete(epslist{k});
  end
end
