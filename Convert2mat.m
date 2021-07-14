function [mat_runnable,Data] = d97tomat( d97_path, plt_path,SamplingTime )
%This function converts the .d97 measurement file to the .mat file using the .plt files
% Example Function Call : 
% [D97Data,Data] = d97tomat('D:\customer_project\jlr\src_cm4sl\Results\Measurements\LMC\LMC_runnable.D97',...
%     'D:\customer_project\jlr\Data\TestRun\vmc_sim_simple_tests\GenericFunctions\LMC_PLT.plt',0.005)

mystring = strcat('C:\tools\MDFDSET6c.exe ifn=',d97_path,';pltfn= ',plt_path,' MATLAB7 ofn=d97tomat.mat',' tc=',num2str(SamplingTime));
dos(mystring)

mat_runnable = load('d97tomat.mat');
mat_runnable = structfun(@transpose,mat_runnable,'UniformOutput',false);
delete('d97tomat.mat');

SigList = fieldnames(mat_runnable) ; 
SigListRequired = SigList(~startsWith(SigList,'q_')) ; 

for i = 1:numel(SigListRequired)
    Data.(SigListRequired{i}) = timeseries(mat_runnable.(SigListRequired{i}),mat_runnable.q_T0,'Name',SigListRequired{i});
end

save Myd97ToMatConverted.mat Data -v7.3

end
