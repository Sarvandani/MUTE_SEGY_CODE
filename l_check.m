function ier=l_check(wlog)
% Function checks if log structure set is consistent and complies with
% specifications
%
% Written by: E. R., August 26, 2001
% Last updated: January 1, 2006: Check field "units"
%
%         ier=l_check(wlog)
% INPUT
% wlog    log structure
% OUTPUT
% ier     error indicator; logical(1) if there is an error oan logical(0) if not

global S4M

param.verbose=logical(0);

verbose=param.verbose;

ier=logical(0);

if nargin ~= 1
   disp(' One argument (log structure) required')
   ier=logical(1);
   return
end

if ~istype(wlog,'well_log')
   dispdlg('Input to "l_check" is not a well log')
   ier=logical(1);
   return
end

%       Establish name of input structure for reference later

dataset=['"',wlog.name,'"'];

if ~isstruct(wlog)
   dispdlg([' ',dataset,' is not a structure'])
   return
end 

%       Check if required fields are present
fields=fieldnames(wlog);
required={'first','last','step','units','curves','curve_info'};
index=find(~ismember(required,fields));
if ~isempty(index)
   dispdlg([' ',dataset,' does not have required field(s): ',cell2str(required(index))])
   return
else
   if verbose
      dispdlg([' ',dataset,' has the required fields: ',cell2str(required)])
   end
end

%       Check if curves are empty
[nsamp,ncurves]=size(wlog.curves);
if nsamp*ncurves == 0
   dispdlg([' curves of ',dataset,' are empty'])
   ier=logical(1);
   return
else
   if verbose
      dispdlg([' ',dataset,' has ',num2str(ncurves),' curve(s) with ',num2str(nsamp), ...
                  ' sample(s)'])
   end  
end 

%       Check if start depth, end depth, sample interval and # of samples agree
if wlog.step < 0
   dispdlg(' Sample interval must be non-negative')
   ier=logical(1);
   return
end
if wlog.first ~= wlog.curves(1,1)
   dispdlg([' Field "first" (',num2str(wlog.first),') differs from first value', ...
      ' of depth curve (',num2str(wlog.curves(1,1)),')'])
   ier=logical(1);
end
if wlog.last ~= wlog.curves(end,1)
   dispdlg([' Field "last" (',num2str(wlog.last),') differs from last value', ...
      ' of depth curve (',num2str(wlog.curves(end,1)),')'])
   ier=logical(1);
end

ddd=diff(wlog.curves(:,1));
if any(isnan(ddd))
% if ~isempty(find(isnan(ddd)));
   dispdlg(' The first column of the log curves must not contain NaNs')
   ier=logical(1);
else
   middd=min(ddd);
   if middd <= 0
      dispdlg(' Depth values must be monotonically increasing')
      ier=logical(1);
      if wlog.step > 0
         dispdlg(' "wlog.step" must be zero for nonuniform depth values')
      end
   else
      bool=isconstant(ddd,S4M.log_step_error);
      maddd=max(ddd);
      mddd=0.5*(maddd+middd);
      if wlog.step == 0  &  bool
         dispdlg([' Depth increment is uniform (',num2str(ddd(1)),'), but "wlog.step" is zero'])
         ier=logical(1);
      elseif wlog.step > 0  &  ~bool
         dispdlg([' Depth increment not uniform (',num2str(middd),' - ',num2str(maddd), ...
             '), but "wlog.step" is not zero'])
         ier=logical(1);
      elseif wlog.step > 0  &  bool
         if abs(wlog.step-ddd(1)) > S4M.log_step_error*wlog.step
            dispdlg([' Depth increment (',num2str(mddd),') and "wlog.step" (', ...
                num2str(wlog.step),') do not agree'])
            ier=logical(1);
         end
      end
   end
end


%       Check field "curve_info"
[nci,mci]=size(wlog.curve_info);
if ~iscell(wlog.curve_info)
   dispdlg(' Field "curve_info" must be a cell array')

else
   if nci ~= ncurves
      dispdlg([' The number of log curves (',num2str(ncurves),') is not equal to ', ...
          'the number of rows (',num2str(nci),') of cell array "curve_info"'])
     ier=logical(1);
   end

   if mci ~= 3
      dispdlg(' The cell array of field "curve_info" must have 3 columns')
   end

   temp=wlog.curve_info(:);
   ix=0;
   for ii=1:3*nci
      if ~ischar(temp{ii})
         ix=1;
      end
   end
   if ix
      dispdlg(' Elements of field "curve_info" must be character strings')
      ier=logical(1);
   end
end

%	Check parameters
ier=max(param_check(wlog),ier);
if verbose & ~ier
   dispdlg(' No formal errors with parameters')
end


%       Check for NaNs
idx=find(isnan(wlog.curves));
if isempty(idx) & ismember('null',fields)
   alert(' Field "null" exists, but curves have no null values')
   ier=logical(1);
elseif ~isempty(idx) & ~ismember('null',fields)
   dispdlg(' Field "null" does not exist, but curves do have null values')
   ier=logical(1);
else
   if verbose
      dispdlg(' No problem with null values')
   end
end

% 	Check for identical mnemonics
if S4M.case_sensitive
  mnems=unique(wlog.curve_info(:,1));
  if length(mnems) < ncurves
    dispdlg(' Curve mnemonics are not unique (mnemonics are case-sensitive)')
    ier=logical(1);
    for ii=1:length(mnems)
      idx=find(ismember(wlog.curve_info(:,1),mnems{ii}));
      if length(idx) > 1
        dispdlg(['     ',cell2str(wlog.curve_info(idx,1),', ')])
      end
    end
  end
  
else
   mnems=unique(lower(wlog.curve_info(:,1)));
   if length(mnems) < ncurves
      dispdlg(' Curve mnemonics are not unique (mnemonics are not case-sensitive):')
      ier=logical(1);
      for ii=1:length(mnems)
         idx=find(ismember(lower(wlog.curve_info(:,1)),mnems{ii}));
         if length(idx) > 1
            dispdlg(['     ',cell2str(wlog.curve_info(idx,1),', ')])
         end
      end
   end 
end

if ~ier & nargout == 0
   dispdlg([' No formal errors found in ',dataset,])
end 

%	Check field "units"
if ~strcmp(wlog.units,wlog.curve_info{1,2})
   ier=logical(1);
   dispdlg(['Depth units in field "units" ( ',wlog.units, ...
       ' ) differ from those in field "curve_info" ( ',wlog.curve_info{1,2},' ).'])
end

if nargout == 0
   clear ier
end

