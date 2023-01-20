function seismic=s_log2seismic(wlog,mnems)
% Function converts log curves whose mnemonics are listed in the second input argument
% into a seismic data set. The first column of the log structure must be equidistantly
% sampled
% Written by: E. R.: August 8, 2002
% Last updated: April 1, 2005: New seismic structure fields added.
%
%	    seismic=log2seismic(wlog,mnems)
% INPUT
% wlog      log structure
% nmems     cell array with one or more header mnemonics
%           if there is only one header mnemonic, it can be a simple string
%           if no header mnemonics are given, all curves in the log structure (with
%           the exception of the first column (depth)) are converted
% OUTPUT
% seismic   seismic data set

global S4M      

if ~isfield(wlog,'step') | wlog.step == 0
   error(' Input log must be uniformly sampled')
end

if nargin == 1
   mnems=wlog.curve_info(2:end,1)';
else
   if ~iscell(mnems)
      mnems={mnems};
   end
end

% 	Check if curves with these mnemonics are present
idx=find(ismember(lower(wlog.curve_info(:,1)),lower(mnems)));
if length(idx) < length(mnems)
   disp(' The following curves were requested:')
   disp(mnems)
   disp(' The following requested curves were found:')
   disp(wlog.curve_info(idx,1)')
   disp(' The following curves are available:')
   disp(wlog.curve_info(:,1)')
   error(' Abnormal termination')
end

seismic.type='seismic';
seismic.tag='unspecified';
seismic.name=wlog.name;
seismic.first=wlog.first;
seismic.step=wlog.step;
seismic.last=wlog.last;
seismic.units=wlog.curve_info{1,2};
seismic.traces=wlog.curves(:,idx);
seismic.trace_info=wlog.curve_info(idx,:);

if ismember(seismic.units,{'m','ft'})
   disp([' Warning: Seismic "time units" are in ',seismic.units,'.'])
end

if isfield(wlog,'null') & isnan(wlog.null)
   if any(isnan(seismic.traces(:)))
      seismic.null=NaN;
   end
end

%     Create S4M.history field
if isempty(S4M.history) | S4M.history
   seismic=s_history(seismic,'add',['Curves converted:',cell2str(seismic.trace_info(:,1))]);
end


