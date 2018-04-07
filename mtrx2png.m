clear all
close all

% Select input folder and get all files
fol_in = uigetdir(pwd, 'Select a folder to input from:');
all_files = extractfield(rdir([fol_in,'*\**\*.z_mtrx']),'name');
no_files = length(all_files);

tic
for loop = 1:length(all_files)
    clear Ims CminV CmaxV RGB
    pause(0.1)
    
    % Read in file and get parts
    [pathstr,name,ext] = fileparts(char(all_files(loop)));
    
    % Convert file and flatten
    Ims = SPIW_open(char(all_files(loop)));
    %CminV = min(Ims{1,1}.data(:));
    %CmaxV= max(Ims{1,1}.data(:));
    %RGB = Data2RGB(Ims{1,1}.data,nanomap,[CminV,CmaxV]);
        
    Ims_flat = Im_Flatten_X(Ims{1,1});
    CminV_flat = min(Ims_flat.data(:));
    CmaxV_flat= max(Ims_flat.data(:));
    RGB_flat = Data2RGB(Ims_flat.data,nanomap,[CminV_flat,CmaxV_flat]);
    
    % Save file as .png in original location
    imwrite(RGB_flat,[pathstr,'\',name,'.png'])
    
    % Display success
    disp([datestr(toc/(24*60*60), 'HH:MM:SS'),' - Converted ',...
        num2str(loop),'/',num2str(length(all_files)),...
        ' Files']);
end

% Announce finish
load('handel.mat');
sound(y, 1*Fs);
disp('Completed');
disp(['Time Taken: ',datestr(toc/(24*60*60), 'HH:MM:SS')])