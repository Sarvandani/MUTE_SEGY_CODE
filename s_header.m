function seismic=s_header(seismic,action,mnem,values,units,description)
% Function manipulates header(s) of a seismic dataset
%
% Written by E. R.; Date March 16, 2000
% Last updated; January 17, 2006: more checks of input data
%
%           seismic=s_header(seismic,action,mnem,values,units,description)
%           seismic=s_header(seismic,action,mnem)    for action=delete,delete_ne,keep,keep_ne,list
%           seismic=l_header(seismic)                assumes action list          
% INPUT
% seismic  Seismic structure;
%          If this is the only input argument, "action" is set to 'slist' and "mnem' is
%          set to '*'. The function prints a list of all header values as describend 
%          below. 
% action   Defines action to take. Possible values are:
%          'add'      Add header with mnemonic mnem. Gives error message if 
%                     header already exists
%          'add_ne'   Add header with mnemonic mnem. Replaces it if it already exists.
%          'replace'  Replaces header with mnemonic mnem; error if
%                     header does not exist
%          'delete'   Delete header(s) with mnemonic(s) mnem; 
%                     error if header does not exist 
%          'delete_ne' Delete header(s) with mnemonic(s) mnem if the header is present
%                     no error if one or more of the header(s) specified does not exist 
%          'keep'     Keep header(s) with mnemonic(s) mnem and deletes all others;
%                     error if one or more of the header(s) do not exist 
%          'keep_ne'  Keep header(s) with mnemonic(s) mnem if it is (they are) present
%                     and deletes all others; no error if any or all headers specified 
%                     are not present
%          'rename'   Rename header mnemonic, keep everything else the same
%          'list'    Print short list: for specified header mnemonic(s) it lists minimum 
%                     and maximum value, smallest and greatest trace-to-trace change,
%                     units of measurement, and header description
%          
%          The other input parameters depend on the parameter "action"
%
%                   CASE action = 'add', 'add_ne', or 'replace'
% mnem     Header mnemonic
% values   Header values; if only one value is given the header is assumed 
%          to be constant
% units    Units of measurement for curve values (optional if 'action' is 
%          'replace')
% description  Description of curve mnemonic (optional if 'action' is 'replace')
%          If "action" is 'replace' "units" and "description" need not be given; 
%          in this case the original "units" and "description" are retained.
%
%                  CASE action = 'delete', delete_ne', 'keep', 'keep_ne', or 'list'
% mnem     Header mnemonic or cells array with header mnemonics
%          '*' means all headers
%
%                  CASE action = 'rename'
% mnem     Cell array consisting of two strings: the old and 
%          the new name of the header
%
% OUTPUT
% seismic  "Updated" seismic structure (no output if action == 'list')
%

global S4M

if nargin < 1
   error('At least one input argument (seismic structure) required')
end

if ~istype(seismic,'seismic')
   error('The first input argument must be a seismic structure.')
end

if isempty(seismic.traces)
   error('Seismic input dataset has no traces.')
end

if nargin == 1
   action='list';
   mnem={'*'};
else
   action=lower(action);
   if ~iscell(mnem)
%     mnem={mnem};
      mnem=tokens(mnem,',');
   end
end

if ~isfield(seismic,'headers') 
   if ~strcmp(action,'add') & ~strcmp(action,'add_ne')
      disp('Seismic structure has no headers')
      if nargout == 0
         clear seismic; 
      end
      return
   else
      nh=0;
      mh=size(seismic.traces,2);
   end
else
   [nh,mh]=size(seismic.headers);
end

if isfield(seismic,'history') & S4M.history
   seismic=s_history(seismic,'append',[char(action),': ',cell2str(mnem,', ')]);
end

lmnem=length(mnem);
if lmnem == 1 & strcmp(char(mnem),'*') & ...
   ~strcmp(action,'add') & ~strcmp(action,'add_ne') & ~strcmp(action,'replace')
  mnem=seismic.header_info(:,1);
  lmnem=length(mnem);
end

switch action
               case {'add','add_ne','replace'}

lv=length(values);
if lv == 1
  val=values; 
elseif lv == mh
  val=reshape(values,1,mh);
else
  error(['Input argument "values" must be a constant or a vector ', ...
         'whose length is equal to the number of traces in the seismic structure'])
end

if ~isfield(seismic,'header_info')
   idx=[];
else
   [idx,ierr]=header_index1(seismic,mnem);
%   idx=find(ismember(lower(seismic.header_info(:,1)),mnem));
end

if ~isempty(idx)
   if strcmpi(action,'add')
      error(['The header mnemonic ',char(mnem),' already exists in the header'])
   else
     seismic.headers(idx,:)=val;
     if nargin > 4
       seismic.header_info{idx,2}=units;
       if nargin > 5
         seismic.header_info{idx,3}=description;
       end
     end
   end
else
  if strcmpi(action,'replace')
    error(['The header mnemonic ',char(mnem),' does not exist in the header'])
  else
    idx=nh+1;
    seismic.header_info(idx,1)=mnem;
    seismic.headers(idx,1:mh)=val;
    seismic.header_info{idx,2}=units;
    seismic.header_info{idx,3}=description;
  end      
end

              case {'delete','delete_ne'}
idx=find(ismember(lower(seismic.header_info(:,1)),mnem));
if lmnem ~= length(idx) & strcmp(action,'delete')
  for ii=1:lmnem
    if ~ismember(lower(seismic.header_info(:,1)),mnem(ii))
      disp(['Header ',char(mnem(ii)),' not present'])
    end
  end
  error('Abnormal termination')
end
if length(idx) == length(seismic.header_info(:,1))
%  seismic=rmfield(seismic,{'headers','header_mnem','header_units','header_descriptions'});
  seismic=rmfield(seismic,{'headers','header_info'});
else
  seismic.headers(idx,:)=[];
  seismic.header_info(idx,:)=[];
end 

              case {'keep','keep_ne'}
idx=find(~ismember(seismic.header_info(:,1),mnem));
if lmnem ~= nh-length(idx) & strcmp(action,'keep')
  for ii=1:lmnem
    if ~ismember(lower(seismic.header_info(:,1)),mnem(ii))
      disp(['Header ',char(mnem(ii)),' not present'])
    end
  end
  error(' Abnormal termination')
end
if length(idx) == nh
  seismic=rmfield(seismic,{'headers','header_info'});
else
  seismic.headers(idx,:)=[];
  seismic.header_info(idx,:)=[];
end 

              case 'rename'
if lmnem ~= 2
  error(['Parameter mnem must be a cell array with two strings' , ... 
        '(old header mnemonic and new header mnemonic)'])
elseif ismember(seismic.header_info(:,1),mnem(2))
  error(['New header mnemonic ',char(mnem(2)),' already exists in the header'])
else
  idx=find(ismember(seismic.header_info(:,1),mnem(1)));
  if isempty(idx)
    error(['Seismic header ',char(mnem(1)),' does not exist'])
  else
    seismic.header_info(idx,1)=mnem(2);
  end
end

              case 'list'
idx=find(ismember(seismic.header_info(:,1),mnem));
if isempty(idx)
  error([' Header(s) "',cell2str(mnem,'", "'),'" do(es) not exist'])
end
mnems=char('MNEMONIC',seismic.header_info{idx,1});
descr=char('DESCRIPTION',seismic.header_info{idx,3});
units=char('UNITS',seismic.header_info{idx,2});
hmin=min(seismic.headers(idx,:),[],2);
hmax=max(seismic.headers(idx,:),[],2);
dh=diff(seismic.headers(idx,:),[],2);
dhmin=min(dh,[],2);
dhmax=max(dh,[],2);
spaces(1:length(hmax)+1)=' ';

if isempty(dhmin)     % handle case of only one input trace (no trace-to-trace change)
   dhmin=' n/a';
   sdhmin=char('MIN_STEP',dhmin(ones(length(hmin),1),:));
   sdhmax=char('MAX_STEP',dhmin(ones(length(hmin),1),:));
else
   sdhmin=char('MIN_STEP',num2str(dhmin));
   sdhmax=char('MAX_STEP',num2str(dhmax));
end

shmin=char('MIN_VAL',num2str(hmin));
shmax=char('MAX_VAL',num2str(hmax));
disp(['Headers of seismic data set "',seismic.name,'"'])
disp([mnems,spaces',shmin,spaces',spaces',shmax,spaces', ...
      spaces',sdhmin,spaces',spaces',sdhmax,spaces',units,spaces',descr]);

%   Write message if one or more of the headers specified were not found
if lmnem ~= length(idx)    
  for ii=1:lmnem
    if ~ismember(lower(seismic.header_info(:,1)),mnem(ii))
      disp([char(mnem(ii)),' is not present'])
    end
  end
end


              otherwise
error(['Action ',action,' not defined'])

end	      % End of switch block

if nargout == 0
   clear seismic;
end
