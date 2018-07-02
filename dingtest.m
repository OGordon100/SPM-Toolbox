clc
clear
close all

allSubFolders=genpath('E:\\images\\afmstm');
remain = allSubFolders;
listOfFolderNames = {};
while true
    [singleSubFolder, remain] = strtok(remain, ';');
    if isempty(singleSubFolder)
        break;
    end
    listOfFolderNames = [listOfFolderNames singleSubFolder];
end
numberOfFolders = length(listOfFolderNames)



for folderi=1:numberOfFolders
    foldername=listOfFolderNames{folderi};
    
    imagefiles = dir(sprintf('%s\\*.Z_mtrx',foldername));
    nfiles = length(imagefiles);
    
    if nfiles==0
        
    else 
        for ii=1:nfiles  
            currentfilename= imagefiles(ii).name;
            [pathstr,subname,ext] = fileparts(currentfilename);
            Ims = SPIW_open(sprintf('%s\\%s.Z_mtrx',foldername,subname));
            CminV = min(Ims{1,1}.data(:));
            CmaxV= max(Ims{1,1}.data(:));
            RGB = Data2RGB(Ims{1,1}.data,nanomap,[CminV,CmaxV]);
            
            k = strfind(foldername, 'Good');
            if k>1
            imwrite(mat2gray(RGB),sprintf('E:\\images\\afmgoodbad\\good\\%s.png',subname));
            else 
            imwrite(mat2gray(RGB),sprintf('E:\\images\\afmgoodbad\\bad\\%s.png',subname));
            end
            
        end
    end
end


% Ims = SPIW_open('E:\images\afmstm\H-passivated surface - selection of images_(Ben)\H-passivated surface - selection of images\Good quality\2014-11-26\default_2014Nov26-171521_STM-STM_Spectroscopy--4_1.Z_mtrx');
% CminV = min(Ims{1,1}.data(:));
% CmaxV= max(Ims{1,1}.data(:));
% RGB = Data2RGB(Ims{1,1}.data,nanomap,[CminV,CmaxV]);