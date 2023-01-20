function [index,ierr]=s_trace_numbers(seismic,varargin)
% Function outputs sequential trace numbers of seismic input traces based on 
% header values
% See also: "s_select"
%
% Written by: E. R.: April 15, 2000
% Last updated: September 13, 2004: Second output argument
%
%          [index,ierr]=s_trace_numbers(seismic,varargin)
% INPUT
% seismic  seismic structure
% varargin one or more arguments;
%          The first input argument is a string; it can be a header mnemonic or 
%          it can contain a logical expression involving header values.
%          A "pseudo-header" 'trace_no' can also be used.
%          If the second input argument is a string containing only a header 
%          mnemonic there must be a third arguments containing a vector 
%          of values. No defaults            
% OUTPUT
% index    column vector with indices of trace numbers
% ierr     error code
%          no error:                                         ierr = 0
%          Header has no values matching the ones requested: ierr = 1
%          Header has no values within range specified:      ierr = 2
%          No header mnemonics found in expression:          ierr = 3
%          Not a valid logical expression:                   ierr = 4
%          If the second output argument is not supplied and an error occurs 
%          the function aborts with the appropriate error message
%
% EXAMPLES OF USAGE       
%          index=s_trace_numbers(seismic,'offset',[100:100:2000])
%          index=s_trace_numbers(seismic, ...
%                'iline_no > 1000 & iline_no < 1100 & xline_no == 1000')
% EXAMPLES
%          seismic=s_data;
%          index=s_trace_numbers(seismic,'cdp',105,inf)
%          index=s_trace_numbers(seismic,'cdp >= 105')   % This is equivalent to 
%                                                        % the previous command

if ~isstruct(seismic)
   error('First input argument "seismic" must be a structure.')
end
ierr=0;

if iscell(varargin{1})
%  varargin=varargin{1};           % Bug????
end

if ~ischar(varargin{1})            % Traces given explicitely
   if length(varargin) > 1
      index=max([1,varargin{1}]):min([size(seismic.traces,2),varargin{2}]);
   else
      index=varargin{1};
   end

elseif length(varargin) > 1        % Traces defined via header

   header=varargin{1};
   header_vals=s_gh(seismic,header);

   if length(varargin) == 2         % Range of header values specified
      hidx=varargin{2};
      index=ismember_ordered(header_vals,hidx);
      index=reshape(index,1,[]);
      if isempty(index)
         if nargout <= 1
            disp(' Requested header values:')
            disp(hidx)
            error(['Header "',header,'" has no values matching the ones requested'])
         else
            ierr=1;
            index=[];
         end
      end

   elseif length(varargin) == 3                             % First and last header value specified
      ha=varargin{2};       
      he=varargin{3};
      index=find(header_vals >= ha & header_vals <= he);
      if isempty(index)
         if nargout <= 1
            error(['Header "',header,'" has no values within range specified (',num2str([ha,he]),')'])
         else
            ierr=2;
            index=[];
         end
      end
   end

else                               % Traces defined via logical expression
   [index,ierr]=find_trace_index(seismic,varargin{1});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [index,ierr]=find_trace_index(seismic,expression)
% Function finds index of traces whose header values match a logical expression
%
% INPUT
% seismic       seismic data set
% expression    logical expression involving header values
% OUTPUT
% index         index of trace numbers (traces "seismic.traces(:,index)" are selected)
% ierr          error code

global S4M

ierr=0;

words=lower(unique(extract_words(expression)));       % Find all the words in the logical expression

%       Find all the header mnemonics in "words" and assign header values to variables with those names 
if S4M.case_sensitive
   idx=find(ismember(seismic.header_info(:,1),words));
else
   idx=find(ismember(lower(seismic.header_info(:,1)),words));
end

if isempty(idx) & sum(ismember(words,'trace_no')) == 0
  disp([' No header mnemonics found in expression "',expression,'"'])
  disp(' header mnemonics available')
  disp(seismic.header_info(:,1)')
  if nargout == 1
     error(' Abnormal termination')
  else
     ierr=3;
     index=[];
     return
  end
end

nh=length(idx);
for ii=1:nh
  eval([lower(char(seismic.header_info(idx(ii),1))),' = seismic.headers(idx(ii),:);']);
end

                try
index=eval(['find(',lower(expression),')']);

                catch
disp([' The argument of keyword "traces" (',expression,')'])
disp(' is probably not a valid logical expression')
if nargout == 1
   error(' Abnormal termination')
else
   ierr=4;
   index=[];
end
                end
