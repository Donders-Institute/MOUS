function [trl] = trialfun_word(cfg)

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
  tmpsel = (sel(k)+1):(sel(k+1));
  begsmp = smp(tmpsel(1:end-1));
  endsmp = smp(tmpsel(2:end));
  
  tmp = [begsmp(:) endsmp(:) zeros(numel(begsmp),1) ones(numel(begsmp),1)*k val(tmpsel(1:end-1))'];
  trl = cat(1,trl,tmp);

end
