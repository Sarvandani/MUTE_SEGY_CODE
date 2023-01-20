clear all
clc
data= rand(15001,622);
data_org=zeros(15001,622);
%         data = zeros(size(data));
x=linspace(20,100,81);
data1= data_org(:, 1:min(x)-1)==1;
data2= data_org(:, min(x):max(x))==0;
data3 = data_org(:, max(x):end-1)==1;
data_new=cat(2,data1,data2,data3);
data_new= data_new.*data;
% data=  (data_org) *data
% data= data(min(x):max(x),:)