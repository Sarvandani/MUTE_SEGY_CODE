function structure=add_parameter(structure,value,info)
% Add parameter to a structure; replace it if it already exists (same as "set_parameter")
% Written by: E. R.: September 12, 2003
% Last updated:
%
%            structure=add_parameter(structure,value,info)
% INPUT
% structure  structure 
% value      parameter value
% info       three-element cell vector; the elements are strings: 
%            {parameter mnemonic, units of measurement, description}
% OUTPUT
% structure  input structure with parameter added

if isfield(structure,'parameter_info')
   [index,ier]=param_index1(structure,info{1});
   if isempty(index)
      structure.parameter_info=[structure.parameter_info;info];
   else
      structure.parameter_info(index,:)=info;
   end
else
   structure.parameter_info=info;
end

structure=setfield(structure,info{1},value);
