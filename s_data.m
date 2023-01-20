function seismic=s_data
% Generate test dataset consisting of 12 traces of filtered random Gaussian
% noise (1000 ms long, 4 ms sample interval)
% The dataset has one header('CDP')
%
% Written by: E. R.: August 27, 2003
% Last updated: March 25, 2005: change field "name" and add "history" field
%
%           seismic=s_data

run_presets_if_needed

randn('state',99999)
seismic=s_convert(randn(251,12),0,4);
seismic=s_filter(seismic,{'ormsby',10,15,30,60});
seismic=s_header(seismic,'add','CDP',101:100+size(seismic.traces,2),'n/a','CDP number');
seismic.name='Test data';

seismic=s_history(seismic,'add','Synthetic filtered noise');
