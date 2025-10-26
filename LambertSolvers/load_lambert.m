function [] = load_lambert()
    dllDirectory_Path = convertStringsToChars(string(cd) + "\LambertSolvers\ivLamV2p41_738416p65617\matlabInterface\lib\");  %at distribution in this file near the driver, otherwise change here.
    
    addpath(dllDirectory_Path) %add the path where the .dll resides
    
    %load the dll and initialize the lambert routines
    iflag=ivLam_initializeDLL(dllDirectory_Path);
    if(iflag~=0)
        return
    else
        disp('coef path and dll path appear correct, data loaded ok!')
    end
end