function seismic=s_hilbert(seismic,varargin)
% Function computes Hilbert transform or instantaneous amplitude of seismic data
% Written by: E. R., October 10, 2000
% Last updated: June 10, 2004: keyword 'output' as replacement for 'type';
%                              trace nulls removed if present
%
%              seismic=s_hilbert(seismic,varargin)
% INPUT
% seismic      seismic structure
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%     'output'  Possible values are: 
%             'hilbert'  (Hilbert transform of the seismic input data)
%             'complex' (seismic+i*hilbert(seismic) )
%             'amplitude' (instantaneous amplitude)
%              Default: {'output','amplitude'}
% OUTPUT
% seismic    seismic structure after the transformation specified via 'output'

%     Set default values
param.output='amplitude';

%       Decode and assign input arguments
param=assign_input(param,varargin);

if isfield(seismic,'null')
   if isnan(seismic.null)
      disp(' Null values in seismic rmoved or replaced by zeros via "s_rm_trace_nulls".')
      seismic=s_rm_trace_nulls(seismic);
   end
end

switch param.output

                case 'amplitude'
seismic.traces=abs(myhilbert(seismic.traces));
htext='Instantaneous amplitude';

                case 'complex'
seismic.traces=myhilbert(seismic.traces);
htext='Complex trace';

                case 'hilbert'
seismic.traces=imag(myhilbert(seismic.traces));
htext='Hilbert transform';

                otherwise
error([' Unknown output "',param.output,'"'])
   
end

%    Append history field
if isfield(seismic,'history')
   seismic=s_history(seismic,'append',htext);
end
