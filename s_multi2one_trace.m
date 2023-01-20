function seismic1=s_multi2one_trace(seismic,header)
% Function converts the traces of a data set into individual one-trace datasets.
% The result is a structure vector of data sets
% See also: s_one2multi_trace
% Written by: E. R.: August 23, 2005
% Last updated:
%
%           seismic1=s_multi2one_trace(seismic,header)
% INPUT
% seismic   seismic dataset
% header    optional; mnemonic of header whose value is to be added to 
%           the dataset name as (header = headervalue)
% OUTPUT
% seismic1  structure vector of one-trace datasets; thus selecting the third
%           trace
%              temp=s_select(seismic,{'traces',3}), 
%	    where "seismic" is the input dataset can now be achieved by
%              temp=seismic1(3)
%           where "seismic1" is the output data set

ntr=size(seismic.traces,2);

if nargin == 2
   values=s_gh(seismic,header);

   for ii=1:ntr
      temp=s_select(seismic,{'traces',ii});
      temp.name=[temp.name,' (',header,'=',num2str(values(ii)),')'];
      seismic1(ii)=temp;
   end

else
   for ii=1:ntr
      seismic1(ii)=s_select(seismic,{'traces',ii});
   end
end



