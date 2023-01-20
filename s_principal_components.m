function [pc,aux]=s_principal_components(seismic,varargin)
% Function computes principal components of seismic data. It can output the 
% input data represented by any combination of the principal components --- 
% usually the first few. 
% It can also output a seismic data set representing one or more of the principal components
%
% Written by: E. R.: July 18, 2000
% Last updated: August 2, 2006: Fix bug in headers.
%
%             [pc,aux]=s_principal_components(seismic,varargin)
% INPUT
% seismic     seismic data set
% varargin    one or more cell arrays; the first element of each cell array is a keyword,
%             the other elements are parameters. Presently, keywords are:
%             'output' Type of output. Possible values are: 
%                     'pc' (principal components), 'seismic', 'coefficients'. 
%                      In the first case one trace is output for each principal 
%                      component requested; headers which are constant are output as well.
%                      In the second case the number of output traces equals the number
%                      of input traces and all headers are copied.
%                      In the third case the coefficients of each with 
%                      which the principal components are multiplied to form one 
%                      trace are output.
%                      Default: {'output','seismic'}
%             'components' Principal components requested. Possible values are integers > 0.
%                      The maximum value is the smaller of the number of
%                      samples and the number of traces. A request for principal components
%                      with higher order is ignored. 
%                      Default: if {'output','seismic'} then {'components',1}
%                               if {'output','pc'} then {'components',1:maximum_value}
%             'scale'  Only used if {'output','pc'}. Possible values are: 'yes' (scale them by
%                      energy) or 'no'. Default: {'scale','yes'}
% OUTPUT
% pc          seismic structure; if {'output','seismic'} it is the seismic input data 
%             represented by the principal components defined via keyword 'components'.
%             if {'output','pc'} it is the principal components defined via keyword 
%             'components'.
% aux         structure with auxiliary information
%     if output is "seismic'
%     'energy' row vector: scaled energy of the principal components of each trace
%     'd'     column vector: cumulative sum of the squared singular values (scaled so that 
%             the last entry is 1)
%     if output is "pc"
%     'sing_values"   singular values


if ~isstruct(seismic)
  error(' First input argument must be a structure')
end

if isfield(seismic,'null') & isnan(seismic.null)
  error(' Seismic data must not contain NaNs')
end

pc=seismic;

[nsamp,ntr]=size(seismic.traces);
min_nsamp_ntr=min([nsamp,ntr]);

% 	Set default values
param.output='seismic';
param.components=[];

%       Decode and assign input arguments
param=assign_input(param,varargin);

%       Set/check number of principal components requested.
if isempty(param.components)
   if strcmpi(param.output,'seismic')
      param.components=1;
   else
      param.components=1:min_nsamp_ntr;
   end
else
%   idx=find(param.components <= min_nsamp_ntr);
   param.components=param.components(param.components <= min_nsamp_ntr);
end


switch param.output

           	case 'seismic'
[pr_cmp,energy,d]=princ_comp_no1(seismic.traces,param.components);
pc.traces=pr_cmp;

%   	Copy rest of the fields
pc=copy_fields(seismic,pc);

%	Add history field if it exists in seismic
aux.energy=energy;
aux.d=d;
pc=s_header(pc,'add_ne','energy',energy,'n/a','Fraction of total trace energy retained');
 
        	case 'pc'
[pc.traces,sing_val]=princ_comp_no2(seismic.traces,param.components);

%   	Copy rest of the fields
% pc=copy_fields(seismic,pc);

%   	Copy headers that are constant and delete others
if isfield(seismic,'header_info')
   nh=size(seismic.headers,1);
   headers=zeros(nh,1);
   header_info=cell(nh,3);
   icount=0;
   for ii=1:nh
      if min(seismic.headers(ii,:)) == max(seismic.headers(ii,:))
         icount=icount+1;
         headers(icount)=seismic.headers(ii,1);
         header_info(icount,:)=seismic.header_info(ii,:);
      end
   end
   if icount > 0
      pc.headers=headers(1:icount,:);
      pc.header_info=header_info(1:icount,:);
   else
      pc=rmfield(pc,{'headers','header_info'});
   end
end      

%	Choose sign of the principal components so that they best
% 	represents the average of the input data
stack=sum(seismic.traces,2);
pcc=pc.traces'*stack;
idx=find(pcc < 0);
if  ~isempty(idx), 
   pc.traces(:,idx)=-pc.traces(:,idx); 
end

if nargout > 1
   aux.sing_values=sing_val;
end

                case 'coefficients'
[pc.traces,d]=princ_comp_no3(seismic.traces,param.components);
if nargout > 1
   aux.sing_values=d;
end
pc.first=1;
pc.last=length(param.components);
pc.step=1;
pc.unit='samples';
pc.tag='principal_components';
pc.row_label=param.components(:);


  		otherwise
error([' Unknowm option for keyword "output": ',param.output])
		
end		% End of switch block


%	Add entry to the history field if it exists in seismic
htext=[' Principal components: ',num2str(param.components)];
pc=s_history(pc,'append',htext); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pc,energy,dd]=princ_comp_no1(s,npc)
% Function computes principal components of s over the range npc and outputs
% them together with the total relative energy in each column of s.
%       [pc,energy,d]=princ_comp(s,npc)
% INPUT
% s     input array
% npc   indices of principal components to use
%       max(npc) <= number of columns of s
% OUTPUT
% pc    principal components
% energy  fraction of total trace energy

[ns,ntr]=size(s);

if ns >= ntr
  [u,d,v]=svd(s,0);
else
  [v,d,u]=svd(s',0);
end

d=diag(d);

if nargout > 2; 
   dd=d.^2;
   scf=1/sum(dd);
   dd=cumsum(dd)*scf; 
else
   scf=1/sum(d.^2);
end

%scf=1/sum(d.^2);

ik=0;
for ii=npc
   ik=ik+1;
   vv(:,ik)=v(:,ii)*d(ii);
end

pc=u(:,npc)*vv';
if ik == 1
   energy=reshape((vv.^2)*scf,1,[]);
else
   energy=sum(vv.^2,2)*scf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pc,sing_val]=princ_comp_no2(s,npc)
% Function computes principal components of s over the range of indices npc 
% and outputs them together with the total relative energy in each column of s.
%
%           [pc,sing_val]=princ_comp1(s,npc)
% INPUT
% s         input array
% npc       indices of principal components to use
% OUTPUT
% pc        principal components
% sing_val  normalized singular values (sum of squares = 1)

[u,d]=svd(s,0);

pc=u(:,npc);
sing_val=d(npc)./sqrt(sum(diag(d).^2));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vv,d]=princ_comp_no3(s,npc)
% Function computes coefficients of the principal components of s over
% the range of indices npc and outputs them together with the total 
% relative energy in each column of s.
%
%           [pc,sing_val]=princ_comp1(s,npc)
% INPUT
% s         input array
% npc       indices of principal components to use
% OUTPUT
% vv        Matrix with coefficients of the principal components for each column of s
%           there are as many columns as there are columns of "s"
% d         all singular values 

[ns,ntr]=size(s);

if ns >= ntr
   [u,d,v]=svd(s,0);
else
   [v,d]=svd(s',0);
end

d=diag(d);

ik=0;
for ii=npc
   ik=ik+1;
   vv(:,ik)=v(:,ii)*d(ii);
end

if ns < ntr
   vv=vv';
end

