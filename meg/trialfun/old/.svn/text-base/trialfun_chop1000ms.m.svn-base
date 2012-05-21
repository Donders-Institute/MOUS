function [trl] = trialfun_chop1000ms(cfg)

hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

type = {event.type};
fp   = strmatch('frontpanel trigger', type);

val  = [event(fp).value];
smp  = [event(fp).sample];

nsmp = round(hdr.Fs);
sel  = find(val==20);
trl  = zeros(0,4);
for k = 1:numel(sel)-1
  begsmp = smp(sel(k)+1);
  endsmp = smp(sel(k+1)-1);
  
  tmp = begsmp+hdr.Fs./4:nsmp:(endsmp-nsmp+1);
  tmp = [tmp(:) tmp(:)+nsmp-1 zeros(numel(tmp),1) ones(numel(tmp),1)*val(sel(k)+1)];
  trl = cat(1,trl,tmp);

end
