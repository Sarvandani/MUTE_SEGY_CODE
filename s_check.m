function s_check(seismic)
% Function checks if seismic data set is consistent and complies with
% specifications
% Written by: E. R., August 15, 2001
% Last updated: September 1, 2003: Check for structure type
%
%           s_check(seismic)
% INPUT
% seismic   seismic data set

global S4M

param.verbose=logical(0);

verbose=param.verbose;

ier=logical(0);

if nargin ~= 1
  disp(' One argument (seismic data set) required')
  return
end

if ~istype(seismic,'seismic')
   disp('Input to "s_check" is not a seismic data set')
   return
end

%       Establish name of input structure for reference later
dataset=inputname(1);   
if isempty(dataset)
   dataset=' Input argument "seismic"';
else
   dataset=['"',dataset,'"'];
end

if ~isstruct(seismic)
   disp([' ',dataset,' is not a structure'])
   return
end 

%       Check if required fields are present
fields=fieldnames(seismic);
required={'first','last','step','units','traces'};
index=find(~ismember(required,fields));
if ~isempty(index)
   disp([' ',dataset,' does not have the required field(s): ',cell2str(required(index))])
   ier=logical(1);
else
   if verbose
      disp([' ',dataset,' has the required fields: ',cell2str(required)])
   end
end

%       Check if traces are empty
[nsamp,ntr]=size(seismic.traces);
if nsamp*ntr == 0
   disp([' Traces of ',dataset,' are empty'])
   return
else
   if verbose
     disp([' ',dataset,' has ',num2str(ntr),' trace(s) with ',num2str(nsamp), ...
                  ' sample(s)'])
   end  
end 

%       Check if start time, end time, sample interval and # of samples agree
if seismic.step <= 0
  disp(' Sample interval must be positive')
  return
end
if ~isnearinteger((seismic.last-seismic.first)/seismic.step,1.0e-7)
   disp(' Difference of end and start time not integer multiple of sample interval')
   ier=logical(1);
end
if (seismic.last-seismic.first)/seismic.step+1 ~= nsamp
   disp([' Start or end time error is ',  ...
    num2str((seismic.last-seismic.first)-seismic.step*(nsamp-1)),' ',seismic.units])
   disp(['              equivalent to ',  ...
    num2str((seismic.last-seismic.first)/seismic.step+1-nsamp),' sample(s)'])
   ier=logical(1);
end

%       Check headers (if there are any)
if ismember('headers',fields)
  [nh,mh]=size(seismic.headers);
  if ismember('header_info',fields)

% 	Check for identical headers
    if S4M.case_sensitive
      mnems=unique(seismic.header_info(:,1));
      if length(mnems) < nh
        disp(' Curve mnemonics are not unique (headers are case-sensitive)')
        ier=logical(1);
        for ii=1:length(mnems)
          idx=find(ismember(seismic.header_info(:,1),mnems{ii}));
          if length(idx) > 1
            disp(['     ',cell2str(seismic.header_info(idx,1),', ')])
          end
        end
      end

    else
      mnems=unique(lower(seismic.header_info(:,1)));
      if length(mnems) < nh
        disp(' Curve mnemonics are not unique (headers are not case-sensitive):')
        ier=logical(1);
        for ii=1:length(mnems)
          idx=find(ismember(lower(seismic.header_info(:,1)),mnems{ii}));
          if length(idx) > 1
            disp(['     ',cell2str(seismic.header_info(idx,1),', ')])
          end
        end
      end 
    end

    if iscell(seismic.header_info)
       nhi=size(seismic.header_info,1);    
       if nhi ~= nh
          disp(' Number of headers differs from number of rows of field "header_info"')
          ier=logical(1);
       end
       if mh ~= ntr
          alert(' Number of headers values differs from number of traces')
          ier=logical(1);
       end
    else
       disp(' Headers are present but there is no field "header_info"')
       if mh ~= ntr
          disp(' Number of headers values differs from number of traces')
          ier=logical(1);
       end
    end
  else
    disp(' Field "header_info" must be a cell array')
    ier=logical(1);
  end
elseif ismember('header_info',fields)
  disp(' Field "header_info" is present, but there are no headers')
  ier=logical(1);
else
   if verbose
      disp(' No headers present')
   end
end

%       Check for NaNs
idx=find(isnan(seismic.traces));
if isempty(idx) & ismember('null',fields)
   alert(' Field "null" exists, but traces have no null values')
   ier=logical(1);
elseif ~isempty(idx) & ~ismember('null',fields)
   alert(' Field "null" does not exist, but traces have null values')
   ier=logical(1);
else
   if verbose
      disp(' No problem with null values')
   end
end

if ~ier
   disp([' No formal errors found in ',dataset,])
end 

