function wlog=l_rm_nulls(wlog,action,mnemonics)
% Function removes leading and trailing rows from log curves if they contain 
% null values; with option "anywhere", every row with a NaN in one of the 
% listed curves is removed.
% Null values bracketed by non-null values may be retained. The function assumes that 
% null values are represented by NaNs. If this is not the case they are replaced by NaNs in the
% output structure
%
% Written by:  E. R.: March 6, 2000
% Last updated: March 2, 2005: Renove field 'null' if all nulls have been removed
%
%        wlog=l_rm_nulls(wlog,action,mnemonics)
% INPUT
% wlog   log structure
% action Parameter which controls action to be performed; possible values are:
%        'all'  leading and trailing rows are removed if the non-depth 
%               curves listed in "mnemonics" are all NaN  (DEFAULT).
%        'any'  leading and trailing rows are removed if any of the non-depth 
%               curves listed in "mnemonics" has a NAN value
%        'anywhere' rows are removed anywhere if there is a NaN in one of the 
%               curves listed in "mnemonics"   
% mnemonics  optional cell array of mnemonics to be considered 
%        if not given or if empty then all curves are used
%
% OUTPUT
% wlog   output log structure
%
% EXAMPLE
%        wlog=l_rm_nulls(wlog,'any',{'DTp','RHO'})     

global S4M

if ~isfield(wlog,'null')        % If no null values are present in log curves ...   
   return
end

m=size(wlog.curves,2);
if nargin < 2 | isempty(action)
   action='all';
end

if nargin < 3 | isempty(mnemonics)
   idx=2:m;
else
   if ischar(mnemonics)
      mnemonics={mnemonics};
   elseif ~iscell(mnemonics)
      error(' Input parameter mnemonics must be a string or a cell array of strings')
   end
   nm=length(mnemonics);
   if S4M.case_sensitive
      idx=find(ismember(wlog.curve_info(:,1),mnemonics));
   else
      idx=find(ismember(lower(wlog.curve_info(:,1)),lower(mnemonics)));
   end
   if length(idx) ~= nm
      disp([char(13),' Curves requested:'])
      disp(mnemonics)
      disp(' Curves in log structure:')
      disp(wlog.curve_info(:,1)')
      error(' Not all requested curves available in log structure')
   end
end

if ~isnan(wlog.null)
%   idx=find(wlog.curves == wlog.null);
   wlog.curves(wlog.curves == wlog.null)=NaN;
   wlog.null=NaN;   
end

switch action

              case {'any','anywhere'}
test=sum(wlog.curves(:,idx),2);

              case 'all'
test=min(wlog.curves(:,idx),[],2);

              otherwise
error(['Action "',action,'" is not defined'])

end

index=find(~isnan(test));
if isempty(index)
   disp(' No depth found for which at least one of the requested curves has a non-NaN value')
   disp(' yet field "null" exists')
   return
end

switch action

	case 'anywhere'
wlog.curves=wlog.curves(~isnan(test),:);
wlog=rmfield(wlog,'null');

	otherwise
ia=index(1);
ie=index(end);
wlog.curves=wlog.curves(ia:ie,:);

end

wlog.first=wlog.curves(1,1);
wlog.last =wlog.curves(end,1);

%	Check if all null values have been removed
if all(~isnan(wlog.curves(:,2:end)))
   wlog=rmfield(wlog,'null');
end
