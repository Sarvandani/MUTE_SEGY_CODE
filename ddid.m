function ddid
%	Display Distribution ID

global S4M

run_presets_if_needed

disp(['SeisLab Distribution ID: ',num2str(S4M.dd)])
