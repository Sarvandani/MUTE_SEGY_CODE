function seismic=s_attribute(seismic,action,attributes)
% Function computes functionals of the seismic traces and stores them in like-named 
% header(s); if no output data set is provided, information about these functionals
% printed via the 'list' (short list) option of S_HEADER.
%
% Function is obsolete: use "s_attributes" instead.
%
% Written by: E. R.: April 11, 2000
% Last updated: September 18, 2005: Add L2-norm calculation
%
%              seismic=s_attribute(seismic,action,attributes)            
% INPUT
% seismic      Seismic structure;
% 
% action       Defines action to take. Possible values are:
%              'add'      Add header with mnemonic "type". Gives error message if 
%                         header already exists 
%              'add_ne'   Add header with mnemonic "type". Replaces it if it already exists.
%              'Default: 'add_ne'
%             
% attributes   Cell array with one or more character strings describing the 
%              functional(s) to compute. Possible values are:
%              'amax'     Compute the maximum absolute value of each trace and store 
%                         it in header amax
%              'amean'    Compute the mean of the absolute value of each trace and store it 
%              'amedian'  Compute the median of the absolute value of each trace and store 
%                         it in header amedian
%              'amin'     Compute the minimum absolute value of each trace and store 
%                         it in header amin
%                         in header amean (same as 'aaa').
%              'l2norm'   Compute the L2 norm of each trace, i.e. 
%                         SQRT(sum of squares of the samples of each trace)
%              'max'      Compute the maximum value of each trace and store it in header max
%              'mean'     Compute the mean value of each trace and stores it in header mean
%              'median'   Compute the median value of each trace and store it in 
%                         header median
%              'min'      Compute the minimum value of each trace and store it in 
%                         header min
%              'minabs'   Compute the absolute value of the minimum of each trace and store 
%                         it in header minabs
%              'rms'      Compute the rms value of each trace and store it in header rms
%              'trend'    Compute the trend (robust estimate of the average gradient)
%
%              Default: all functionals except trend
%
% OUTPUT
% seismic      "Updated" seismic structure
%

alert('Function is obsolete: use "s_attributes" instead.')

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

if nargin == 1
   action='add_ne';
end

if nargin < 3
   attributes={'aaa','amax','amean','amedian','amin','l2norm', ...
               'max','mean','median','min','minabs','rms'};
else
   if ischar(attributes)
      attributes={attributes};
   end
end

htext=[action,':'];    % Prepare text for history field

[nsamp,ntr]=size(seismic.traces);

	for ii=1:length(attributes)
type=attributes{ii};

%     Check if a header with the name "type" already exists and determine row of header
%     and header_info to store new data
if ~isfield(seismic,'header_info')
   idx=[];
else
   idx=find(ismember(lower(seismic.header_info(:,1)),type));
end
if ~isempty(idx)
   if strcmpi(action,'add')
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
for ii=1:ntr
   temp(ii)=norm(seismic.traces(:,ii));
end
seismic.headers(idx,:)=temp;
seismic.header_info(idx,1:3)={type,'n/a','Maximum of trace'};

               case 'max'
seismic.headers(idx,:)=max(seismic.traces);
seismic.header_info(idx,1:3)={type,'n/a','L2 norm'};

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
for ii=1:ntr
    seismic.headers(idx,ii)=repeated_median_trend(seismic.traces(:,ii))*scf;
end
seismic.header_info(idx,1:3)={type,'1/sec','Trend'};

               case 'logtrend'
scf=1000/seismic.step;
for ii=1:size(seismic.traces,2)
    seismic.headers(idx,ii)=repeated_median_trend(log(seismic.traces(:,ii)+eps))*scf;
end
seismic.header_info(idx,1:3)={type,'1/sec','Logrithmic trend'};

               otherwise
error(['Type ',type,' not (yet?) defined'])

end

nh=size(seismic.headers,1);    % Update number of header mnemonics
htext=[htext,' ',type];        % Update text for history file

% test=max(seismic.headers(1,:)) %test

	end	% End FOR-loop


if nargout == 0   % If no output argument is specified
   s_header(seismic,'list',attributes)
   clear seismic

else

%    Append history field
   if isfield(seismic,'history')
      seismic=s_history(seismic,'append',htext);
   end
end   


