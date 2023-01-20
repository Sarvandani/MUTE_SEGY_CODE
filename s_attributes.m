function seismic=s_attributes(seismic,varargin)
% Function computes functionals of the seismic traces and stores them in like-named 
% header(s); if no output data set is provided, information about these functionals
% printed via the 'list' (short list) option of "s_header".
%
% Written by: E. R.: April 11, 2000
% Last updated: July 26, 2006: Bug fix
%
% SEE ALSO
%            "s_zone_attributes"
%
%            seismic=s_attributes(seismic,varargin)           
% INPUT
% seismic    Seismic dataset;
% varargin   one or more cell arrays; the first element of each cell array is a keyword,
%            the other elements are parameters. Presently, keywords are:
%     'action'  Defines action to take. Possible values are:
%            'add'      Add header with mnemonic "attribute". Gives error message if 
%                         header already exists 
%            'add_ne'   Add header with mnemonic "attribute". Replaces it if it already exists.
%            'Default: {'action','add_ne'}
%     'attributes'    Defines the attributes to compute. Possible attributes
%                    are (not case sensitive):
%            'max'      Compute the maximum value of each trace and store it in header max
%            'amax'     Compute the maximum absolute value of each trace and store 
%                         it in header amax
%            'min'      Compute the minimum value of each trace and store it in 
%                         header min
%            'amin'     Compute the minimum absolute value of each trace and store 
%                         it in header amin
%            'minabs'   Compute the absolute value of the minimum of each trace and store 
%                         it in header minabs
%            'mean'     Compute the mean value of each trace and stores it in header mean
%            'amean'    Compute the mean of the absolute value of each trace and store it 
%                         in header amean
%            'median'   Compute the median value of each trace and store it in 
%                         header median
%            'amedian'  Compute the median of the absolute value of each trace and store 
%                         it in header amedian
%            'rms'      Compute the rms value of each trace and store it in header rms
%            Default: {'attributes','max','min', ... ,'rms'}  (all attributes)
% OUTPUT
% seismic    "Updated" seismic structure
%
% EXAMPLE   
%            s_attributes(s_data)  

%       Set defaults parameters
param.action='add_ne';
param.attributes={'aaa','amax','amean','amedian','amin','l2norm','max', ...
        'mean','median','min','minabs','rms'};
param.min_thick=seismic.step;

%       Replace default parameters by input arguments (if any)
param=assign_input(param,varargin);

if nargin < 1
   error('At least one input argument (seismic structure) is required.')
end

if ~isstruct(seismic)
   error('The first input argument must be a seismic structure.')
end

if ~isfield(seismic,'headers')
   nh=0;
else
   nh=size(seismic.headers,1);
end

if ischar(param.attributes)
   param.attributes={param.attributes};
end

lattributes=length(param.attributes);

htext=cell(lattributes+1,1);
htext{1}=[param.action,':'];    % Prepare text for history field

[nsamp,ntr]=size(seismic.traces);

	for ii=1:lattributes
type=param.attributes{ii};

%     Check if a header with the name "type" already exists and determine row of header
%     and header_info to store new data
if ~isfield(seismic,'header_info')
   idx=[];
else
   idx=find(ismember(lower(seismic.header_info(:,1)),type));
end
if ~isempty(idx)
   if strcmpi(param.action,'add')
      error(['The header mnemonic ',type,' already exists in the header'])
   end
else
   idx=nh+1;
end

switch type

               case {'amean','aaa'}
seismic.headers(idx,:)=mean(abs(seismic.traces));
seismic.header_info(idx,1:3)={type,'n/a','Mean of absolute values of trace'};

	       case 'amax'
seismic.headers(idx,:)=max(abs(seismic.traces));
seismic.header_info(idx,1:3)={type,'n/a','Maximum of absolute values of trace'};

               case 'amedian'
seismic.headers(idx,:)=median(abs(seismic.traces));
seismic.header_info(idx,1:3)={type,'n/a','Median of absolute values of trace'};

               case 'amin'
seismic.headers(idx,:)=abs(min(seismic.traces));
seismic.header_info(idx,1:3)={type,'n/a','Absolute value of trace minimum'};

               case 'l2norm'
temp=zeros(1,ntr);
for jj=1:ntr
   temp(jj)=norm(seismic.traces(:,jj));
end
seismic.headers(idx,:)=temp;
seismic.header_info(idx,1:3)={type,'n/a','L2 norm of trace'};

               case 'max'
seismic.headers(idx,:)=max(seismic.traces);
seismic.header_info(idx,1:3)={type,'n/a','Maximum of trace'};

               case 'mean'
seismic.headers(idx,:)=mean(seismic.traces);
seismic.header_info(idx,1:3)={type,'n/a','Mean of trace'};

               case 'median'
seismic.headers(idx,:)=median(seismic.traces);
seismic.header_info(idx,1:3)={type,'n/a','Median of trace'};

               case 'min'
seismic.headers(idx,:)=min(seismic.traces);
seismic.header_info(idx,1:3)={type,'n/a','Minimum of trace'};

               case 'minabs'
seismic.headers(idx,:)=min(abs(seismic.traces));
seismic.header_info(idx,1:3)={type,'n/a','Minimum of absolute values of trace'};


               case 'rms'
seismic.headers(idx,:)=sqrt(sum(seismic.traces.^2)/nsamp);
%rms=seismic.headers(idx,:)%test
seismic.header_info(idx,1:3)={type,'n/a','RMS amplitude of trace'};

               case 'trend'
scf=1000/seismic.step;
for jj=1:ntr
    seismic.headers(idx,ii)=repeated_median_trend(seismic.traces(:,ii))*scf;
end
seismic.header_info(idx,1:3)={type,'1/sec','Trend'};

               case 'logtrend'
scf=1000/seismic.step;
for jj=1:size(seismic.traces,2)
    seismic.headers(idx,ii)=repeated_median_trend(log(seismic.traces(:,ii)+eps))*scf;
end
seismic.header_info(idx,1:3)={type,'1/sec','Logrithmic trend'};

               otherwise
error(['Type ',type,' not (yet?) defined'])

end

nh=size(seismic.headers,1);    % Update number of header mnemonics
% htext=[htext,' ',type];        % Update text for history file
htext{ii+1}=type;

% test=max(seismic.headers(1,:)) %test

	end	% End FOR-loop


if nargout == 0   % If no output argument is specified
   s_header(seismic,'list',param.attributes)
   clear seismic

else

%    Append history field
   if isfield(seismic,'history')
      seismic=s_history(seismic,'append',cell2str(htext,' '));
   end
end   
