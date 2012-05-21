function [trl] = trialfun_sentence(cfg)

hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

type = {event.type};
fp   = strmatch('frontpanel trigger', type);

val  = [event(fp).value];
smp  = [event(fp).sample];

nsmp = round(hdr.Fs./2);
sel  = find(val==20);
trl  = zeros(0,5);
for k = 1:numel(sel)-1
  begsmp = smp(sel(k)+1);
  endsmp = smp(sel(k+1)-1);
  
  tmp = [begsmp-nsmp endsmp -nsmp k val(k+1)];
  trl = cat(1,trl,tmp);

end
