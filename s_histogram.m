function histogram=s_histogram(seismic,varargin)
% Function computes histogram of seismic amplitudes
% Written by: E. R., September 14, 2000
% Last updated: January 18, 2005: add required fields to seismic structure
%
%         histogram=s_histogram(seismic,varargin)
% INPUT
% seismic       seismic data set
% varargin      one or more cell arrays; the first element of each cell array is a keyword,
%               the other elements are parameters. Presently, keywords are:
%         'option'    specifies what to compute. Presently, the following
%             options are available:
%             'tracewise'  compute a histogram for each trace
%             'dataset'    computes one histogram for the whole data set
%             Default: {'option','dataset')
%         'abs'       specifies if the absolute value of the traces is to be taken.
%             Default: {'abs','no'}
%         'bins'      number of bins to use
%         'limits'    Lower and upper limits of range of values for which histogram is 
%             to be computed. 
%             Default: {'limits',min(seismic.traces),max(seismic.traces)} or, 
%                      if {'abs','yes'}
%                      {'limits',min(abs(seismic.traces)),max(abs(seismic.traces))}
%
%         'binedges'   counts the number of values in seismic that fall between the elements 
%             in the edges vector (which must contain monotonically non-decreasing 
%                     values).
%             if specified, it overrides param.bins and param.limits
%             Default: {'binedges',[]}
%         'output_type' Describes the type of output. The two options are '%' and
%             'samples'. If the former is chosen, the output represents the 
%             percentage of samples falling into each bin. In the latter
%             case, the output is the number of samples in each bin.
%             Default: {'output_type','%'}
%         'binsize' specifies if bins are equal or unequal
% OUTPUT
% histogram   histogram of of seismic amplitudes.
%             The first bin starts at histogram.first-histogram.step and ends at
%             histogram.first  

%       Set defaults
param.option='dataset';
param.abs='no';
param.bins=50;
param.fraction=1;       % Fraction of sample to use
param.limits=[];
param.output_type='%';
param.binedges=[];      % Bin edges; if specified, it overrides param.bins and param.limits
param.binsize='equal';

%       Decode and assign input arguments
param=assign_input(param,varargin);

if ~isstruct(seismic)
  error(' First input argument must be seismic structure')
end

if strcmp(param.abs,'yes')
   traces=abs(seismic.traces);
else
   traces=seismic.traces;
end

[nsamp,ntr]=size(traces);


if ~isempty(param.binedges)
   edges=param.binedges;

else
%       Compute edges of histogram bins
   if strcmpi(param.binsize,'unequal')
      edges=edges_from_samples(traces(:),param.bins,param.fraction);

   elseif strcmpi(param.binsize,'equal')
      if ~isempty(param.limits)
         edges=linspace(param.limits(1),param.limits(2),param.bins+1);
      else
         edges=pp_edges_from_samples(traces,param.bins+1);
      end
   else
      param.binsize
      error('Unknown option for parameter "binsize"')
   end
end


histogram.type='seismic';
histogram.tag='histogram';
histogram.name=['Histogram (',seismic.name,')'];

switch param.option

                case 'dataset'
histogram.traces=histc(traces(:),edges);
if strcmpi(param.output_type,'%')
   histogram.traces=histogram.traces*(100/(nsamp*ntr));
end

                case 'tracewise'
histogram.traces=histc(traces,edges);
if strcmpi(param.output_type,'%')
   histogram.traces=histogram.traces*(100/nsamp);
end
if isfield(seismic,'header_info')
   histogram.header_info=seismic.header_info;
   histogram.headers=seismic.headers;
end
                otherwise
error(' Unknown option for parameter "option"')

end


histogram.traces=histogram.traces(1:end-1,:); 	% The last velue is generally zero 
     %    or irrelavant since it must fall exactly on the end of the last interval 
     %    (edges(end)) which has earlier been increased by 1+eps.
						% 

if strcmpi(param.binsize,'equal')
   histogram.first=edges(1);
   histogram.last=edges(end-1);
   histogram.step=edges(2)-edges(1);
   histogram.units='amplutude';
   histogram.binsize='equal';

else
   histogram.first=1;
   histogram.last=length(edges)-1;
   histogram.step=1;
   histogram.units='bin index';
   histogram.binsize='unequal';

end
   

histogram.binedges=edges;

%    Append history field
if isfield(seismic,'history')
   histogram.history=seismic.history;
   htext=param.option;
   histogram=s_history(histogram,'append',htext);
end 
 
