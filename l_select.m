function wlog=l_select(wlog,varargin)
% Function retrieves subset of log from log structure
% An error message is printed if a column mnemonic is not found. 
% Column mnemonics are not case sensitive (corresponds to l_select1.m of folder Geophysics)
%
% Written by: E. R.: October 7, 2000;
% Last updated: March 4, 2003: Allow string with comma-separated curve mnemonics
%                              for keyword 'curves'
%  
%           wlog=l_select(wlog,varargin)
% INPUT
% wlog	    log structure
% varargin  same number of traces
% varargin  one or more cell arrays; the first element of each cell array is a 
%           keyword, the other elements are parameters. Presently, keywords are:
%       'curves'  strings with curve mnemonics. 
%           Default: {'curves','*'} (implies all curves)
%           The depth (first column of "wlog.curves") is always included  
%       'depths'  start and end depth of log segment (two comma-separated numbers
%           or a two-element vector)
%           Default: {'depths',wlog.first,wlog.last}
%       'rows'  string with logical expression involving one more of the 
%           curve mnemonics
%           Default: {'rows',''} (implies all rows)
%           Keywords 'curves., 'depths' and 'rows' may be given at the same time               
%
% OUTPUT
% wlog    output log with curves defined in "curves"
%
% EXAMPLES  wlog=l_select(wlog,{'curves','depth','twt'},{'rows','depth > 5000'})
%           wlog=l_select(wlog,{'curves','depth','twt'},{'depths',2000,3000})
%           wlog=l_select(wlog,{'rows','depth > 1000 & twt < 2000'})
%           wlog=l_select(wlog,{'depths',4000,4500},{'rows','vclay < 0.35})

global S4M

%    Set default values for input parameters
param.curves='*';
param.depths=[wlog.first,wlog.last];
param.rows='';

%       Decode and assign input arguments
param=assign_input(param,varargin);

if iscell(param.depths)
   param.depths=cat(2,param.depths{:});
end

ncols=size(wlog.curves,2);

%       Select curves
if strcmp(param.curves,'*')
   cindex=1:ncols;
else
   cindex=curve_indices(wlog,param.curves);
%   if ~isempty(find(cindex==0))
   if isempty(cindex)  |  any(cindex==0)
      error(' Abnormal termination')
   end
   if cindex(1) ~= 1
      cindex=[1,cindex];
   end
end

%       Select rows
param.depths=sort(param.depths);
dindex=find(wlog.curves(:,1) >= param.depths(1) & wlog.curves(:,1) <= param.depths(2));
if isempty(dindex)
   error([' Requested depth range (',num2str(param.depths(1)),', ',num2str(param.depths(2)), ...
        ') outside of range of log depths (',num2str(wlog.first),', ',num2str(wlog.last),')'])
end

if ~isempty(param.rows)

%       Find all the words in the logical expression
   words=lower(extract_words(param.rows));
   mnems=wlog.curve_info(ismember(lower(wlog.curve_info(:,1)),words),1);   % Find curve mnemonics in logical expression    
   [index,dummy]=curve_indices(wlog,mnems);
   index=unique(index);
   index=index(index > 0); 
   if isempty(index)
       disp([' No colunm mnemonics in logical expression "',param.rows,'"'])
       error([' Available curve mnemonics are: ',cell2str(wlog.curve_info(:,1))])
   end

%          Create vectors whose names are the curve mnemonics in the logical expression
   for ii=1:length(index)
       eval([lower(char(wlog.curve_info(index(ii),1))),' = wlog.curves(dindex,index(ii));']);
   end

%          Modify expression to be valid for vectors
   expr=strrep(param.rows,'*','.*');
   expr=strrep(expr,'/','./');
   expr=strrep(expr,'^','.^');
   expr=lower(expr);

%          Evaluate modified expression
        try
   rindex=eval(['find(',expr,')']);

       	catch
   disp([' Expression "',param.rows,'" appears to have errors'])
   disp([' curve mnemonics found in expression:',cell2str(wlog.curve_info(index,1))])
   disp([' curve mnemonics available:',cell2str(wlog.curve_info(:,1))])
   disp(' Misspelled curve mnemonics would be interpreted as variables')
   error(' Abnormal termination')
        end

   if isempty(rindex)
       error([' No rows selected by condition "',param.rows,'"'])
   else
       dindex=dindex(rindex);
   end
end

wlog.curve_info=wlog.curve_info(cindex,:);
wlog.curves=wlog.curves(dindex,cindex);
wlog.first=wlog.curves(1,1);
wlog.last=wlog.curves(end,1);
dd=diff(wlog.curves(:,1));

if ~isempty(dd)
   mad=max(dd);
   mid=min(dd);
   if mid*(1+1.0e6*eps) < mad
      wlog.step=0;
   else
      wlog.step=(wlog.last-wlog.first)/length(dd);
   end
else
   wlog.step=1;
end

% 	Add null value if necessary
if ~isfield(wlog,'null')
   if any(any(isnan(wlog.curves(:,2:end))))
      wlog.null=NaN;
   end
end
    
%	Select subset of curve types including only those curves that are
%	also in the log
if isfield(wlog,'curve_types')
   if S4M.case_sensitive
      bool=ismember(wlog.curve_types(:,1),wlog.curve_info(:,1));
   else
      bool=ismember(lower(wlog.curve_types(:,1)),lower(wlog.curve_info(:,1)));
   end
   if ~any(bool)
      wlog=rmfield(wlog,'curve_types');
   else
      wlog.curve_types=wlog.curve_types(bool,:);
   end
end
