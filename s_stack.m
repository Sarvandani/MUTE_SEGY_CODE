function [stack,aux]=s_stack(seismic,varargin)
% Function stacks seismic traces. It a header mnemonic is specified,
% traces with the same value of that header are stacked; otherwise all 
% traces of the input data set are stacked.
%
% Written by: E. R.: June 20, 2001
% Last updated: February 11, 2006: Second output argument is now a structure 
%                                  that might hold more than the one field 
%                                  presently used.
%
%           [stack,aux]=s_stack(seismic,varargin)
% INPUT
% seismic   seismic structure
% varargin  one or more cell arrays; the first element of each cell array is a 
%           keyword, the other elements are parameters. Presently, keywords are:
%           'header'  header mnemonic. Traces with the same header mnemonic
%                  are stacked. 
%                  Default: {'header',''}; i.e. no header mnemonic selected:
%                  all traces of "seismic" are stacked.
% OUTPUT
% stack    seismic structure with the stacked data
%          headers are averaged as well
% aux      structure with additional data
%    'multi'    seismic structure with the same number of traces as "stack". 
%          Each trace sample represents the number of samples of "seismic" 
%          that were used to form the corresponding sample of "stack".

         
%       Set defaults for input parameters
param.header='';

%       Decode and assign input arguments
param=assign_input(param,varargin); 

if isfield(seismic,'null')
   no_null=0;
else
   no_null=1;
end

%	Case of no header specified
if isempty(param.header)
   htext='Stack';
   if isfield(seismic,'headers')
      stack.headers=mean(seismic.headers,2);
   end
   if nargout == 1 	% Multiplicity not requested
      [stack.traces,no_null]=normal_stack(seismic.traces,no_null);

   else			% Multiplicity requested
      [stack.traces,no_null,multi.traces]=normal_stack(seismic.traces,no_null);

%       Copy rest of fields
      if isfield(stack,'headers')
         multi.headers=stack.headers;
      end
      multi=copy_fields(seismic,multi);
   end
  
   stack=copy_fields(seismic,stack);
   if ~no_null
      stack.null=NaN;
   end

else		% Header specified
   htext='Stack';
   no_null_out=1;
   header=s_gh(seismic,param.header);
   uh=unique(header);
   ntr=length(uh);
   stack.traces=zeros(size(seismic.traces,1),ntr);
   stack.headers=zeros(size(seismic.headers,1),ntr);

   if nargout == 1 	% Auxiliary data (second output dataset) not requested
      for ii=1:ntr
         index=find(ismember(header,uh(ii)));
         [stack.traces(:,ii),temp]=normal_stack(seismic.traces(:,index),no_null);
         stack.headers(:,ii)=mean(seismic.headers(:,index),2);
         no_null_out=no_null_out*temp;
      end
   
   else			% Auxiliary data requested
      multi.curves=zeros(size(stack.traces));
      for ii=1:ntr
         index=find(ismember(header,uh(ii)));
         [stack.traces(:,ii),temp,multi.traces(:,ii)]= ...
                 normal_stack(seismic.traces(:,index),no_null);
         stack.headers(:,ii)=mean(seismic.headers(:,index),2);
         no_null_out=no_null_out*temp;
      end
      multi.headers=stack.headers;
      multi=copy_fields(seismic,multi);
   end

   stack=copy_fields(seismic,stack);
   if ~no_null_out
      stack.null=NaN;
   end
end
   
%      Append history field
if isfield(seismic,'history')
   stack=s_history(stack,'append',htext);
end 

if nargout > 1
   aux.multi=s_history(multi,'append','Multiplicity');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [stack,no_null,multipl]=normal_stack(traces,no_null)
% Function computes mean of elements of array traces along rows
% INPUT
% traces      matrix of seismic traces to be stacked
% no_null     logical variable (true (1) if "traces" contains no nulls)
% OUTPUT
% stack       vector of stacked traces
% no_null     logical variable (true (1) if "traces" contains no nulls)
% multipl     multiplicity (number of samples averaged); unless NaNs are
%             present, this is the number of columns of "traces".

[nsamp,ntr]=size(traces);
stack=mean(traces,2);

if nargout > 2
   multipl=ntr*ones(nsamp,1);
end

if no_null
   return
end

% 	Check for NaNs
index=find(isnan(stack));
if isempty(index)
   no_null=1;
   return
end

%	Select rows (times) with NaNs
temp=traces(index,:);
logindex=isnan(temp);
mult=ntr-sum(logindex,2);

%	Replace NaNs by zeros and stack
%idx=find(logindex);	
temp(logindex)=0;
temp=sum(temp,2);

index1=find(mult == 0);
if isempty(index1)
   stack(index)=temp./mult;
   no_null=1;
else
   stack(index)=temp./(mult+eps);
   stack(index(index1))=NaN;
end

if nargout > 2
   multipl(index)=mult;
end
