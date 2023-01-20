function seismic=s_convert(traces,first,step,history,units)
% Function creates a minimal seismic data structure (the history field is optional)
% Written by; E. R.
% Last updated: October 7, 2003: add "tag" field
%
%            seismic=s_create(traces,first,step,history,units)
% INPUT
% traces     array of seismic traces
% first      start time/frequency/depth
% step       sample interval
% history    optional string to put into history field
% units      string with units of measurements (default: 'ms')
% OUTPUT
% seismic    seismic structure satisfying minimal requirements

global S4M

run_presets_if_needed

seismic.type='seismic';
seismic.tag='unspecified';
seismic.name='';
seismic.first=first;
seismic.last=first+(size(traces,1)-1)*step;
seismic.step=step;

if nargin < 5
   seismic.units='ms';
else
   seismic.units=units;
end

seismic.traces=traces;

test=find(isnan(traces));     % Check for NaNs
if ~isempty(test)
   seismic.null=NaN;
end

if S4M.history
   if nargin < 4
      history=[];
   end
   seismic=s_history(seismic,'add',history);
end
