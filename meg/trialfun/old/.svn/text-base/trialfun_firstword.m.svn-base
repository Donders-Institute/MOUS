function [trl] = trialfun_firstword(cfg)

hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

type = {event.type};
fp   = strmatch('frontpanel trigger', type);

val  = [event(fp).value];
smp  = [event(fp).sample];

sel  = find(val==20);
trl  = zeros(0,4);
for k = sel(1:end-1)
  trl = [trl; smp(k+1)-hdr.Fs smp(k+1)+hdr.Fs-1 -hdr.Fs val(k+1)];
end
