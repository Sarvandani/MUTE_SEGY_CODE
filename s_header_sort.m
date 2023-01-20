function index=s_header_sort(seismic,varargin)
% Function sorts the headers of the seismic structure "seismic" and creates an index 
% vector. This index vector can be used in S_SELECT to sort the traces
% Written by: E. R.
% Last updated: January 2, 2001; compact/new header structure; use of "sortrows"
%
%                   index=s_header_sort(seismic,varargin)
% INPUT
% seismic    seismic structure
% varargin   one or more cell arrays; the first element of each cell array is a keyword,
%            the other elements are parameters. Presently, keywords are:
%            'headers'  List of headers to be sorted
%                       General form: {'headers',{header1,sort_dir1},{header2,sort_dir2}, ...
%                       {header3,sort_dir3}}
%                       First the traces are are sorted by trace header "header1", then by
%                       trace header "header2", ...
%                       "sort_dir1", "sort_dir2", ... denote sort directions. Possible
%                       values are 'inceasing' or 'decreasing.  Default is 'increasing'.
%            'sortdir'  Default sort direction ('increasing' or 'decreasing'); 
%                       used if sort direction is not given explicitely with each header
%                       Default: 'increasing'
%                       This value is overruled by any explicitely given sort direction
% OUTPUT
% index      column vector with trace indices
%
% EXAMPLES
%            index=s_header_sort(seismic,{'headers',{'offset','increasing'}})
%
%            index=s_header_sort(wavelet,{'headers',{'cc_median','decreasing'},{'cdp'}})
%            swavelet=s_select(wavelet,{'headers','trace_no',index(1:44)})

if ~isstruct(seismic)
  error(' First input argument must be a seismic structure')
end

%     	Set default values for input arguments
param.headers=[];
param.sortdir='increasing';

param=assign_input(param,varargin);
if ~iscell(param.headers),  param.headers={param.headers};  end

nk=length(param.headers);
ntr=size(seismic.traces,2);

%       Reserve room for arrays
headers=zeros(ntr,nk);

% 	Get header values to be sorted
for ii=1:nk
  if iscell(param.headers{ii}) & length(param.headers{ii}) == 2
     if strcmpi(param.headers{ii}(2),'increasing')
        headers(:,ii)=s_gh(seismic,param.headers{ii}(1))';
     else
        headers(:,ii)=-s_gh(seismic,param.headers{ii}(1))';
     end

  else
     if strcmpi(param.sortdir,'increasing')
        headers(:,ii)=s_gh(seismic,param.headers{ii})';
     else
        headers(:,ii)=-s_gh(seismic,param.headers{ii})';
     end  
  end
end

%   Sort headers
[dummy,index]=sortrows(headers);

