function [Y1,Y2,Y3] = testOutputParser(filenames)
%TESTOUTPUTPARSER Summary of this function goes here
%   Detailed explanation goes here

Y1 = dlmread(filenames{1});
Y2 = dlmread(filenames{2});
Y3 = dlmread(filenames{3});

end

