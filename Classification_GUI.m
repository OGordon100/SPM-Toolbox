%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE CLASSIFICATION GUI %%%
%%%    Oliver Gordon, 2017   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup

clear all
close all

% Check if SPIW toolbox is installed correctly
%if exist('SPIW_open','file') == 2
%else
%    error(['SPIW toolbox not installed. Install from https://sour',...
%        'ceforge.net/projects/spiw/files/latest/download'])
%end

% Set up loop
repeat_loop = 1;
input_folder = [];
filename = 'you shouldn`t see this';
renew = 0;
classified_images = 0;
thechosenone = 0;
image_no = 0;
in_press = 0;
delete_true = 1;   

%% GUI Backbone
% Create centered figure window to hold everything
FigHandle1 = figure(1);
FigHandle1.Position = [100, 100, 900, 500];
FigHandle1.Name='SPM Image Classifier 1.2';
FigHandle1.NumberTitle='off';
movegui(FigHandle1,'center')

% Draw vertical grey lines for visual gravy
line_axis = axes;
line_axis.Visible = 'off';
line_axis.Position = [0, 0, 1, 1];
line_axis.XLim = [0,1];
line_axis.YLim = [0,1];
for linedif = [0.25,0.75]
    line([linedif,linedif],line_axis.YLim,...
        'Color',[0.5,0.5,0.5],'LineWidth',0.01)
end

% VIEW IMAGE
image_axis = axes;
axis square
image_axis.Position = [0.06, 0.01, 0.88, 0.88];
image_axis.XAxis.Visible = 'off';
image_axis.YAxis.Visible = 'off';

% STRINGS
text_setup=uicontrol('Style','text','String','SETUP',...
    'Position',[60, 455, 100, 40],'FontSize',20);
text_view=uicontrol('Style','text','String','VIEW',...
    'Position',[400, 455, 100, 40],'FontSize',20);
text_classify=uicontrol('Style','text','String','CLASSIFY',...
    'Position',[690, 455, 200, 40],'FontSize',20);
text_current_status=uicontrol('Style','text','String','CURRENT STATUS:',...
    'Position',[10, 70, 200, 30],'FontSize',15);
text_current_status_actual=uicontrol('Style','text','String',...
    'Initialising',...
    'Position',[12, 15, 200, 50],'BackgroundColor','white');
text_input=uicontrol('Style','text','String','NO FOLDER SELECTED',...
    'Position',[12, 345, 200, 40]);
text_output=uicontrol('Style','text','String','NO FOLDER SELECTED',...
    'Position',[12, 185, 200, 40]);

% Vertically center text on current status
jh = findjobj(text_current_status_actual);
ji = findjobj(text_input);
jj = findjobj(text_output);
jh.setVerticalAlignment(javax.swing.JLabel.CENTER)
ji.setVerticalAlignment(javax.swing.JLabel.TOP)
jj.setVerticalAlignment(javax.swing.JLabel.TOP)

% BUTTONS
button_unclass_quality=uicontrol('Style','pushbutton',...
    'Position',[690 395 200 50],'String','Unclassified (Quality)',...
    'CallBack', @(src,eventdata)unclass_quality(src,eventdata,...
    text_current_status_actual,input_folder,image_axis));
button_unclass_multiple=uicontrol('Style','pushbutton',...
    'Position',[690 335 200 50],'String','Unclassified (Multiple)',...
    'CallBack', @(src,eventdata)unclass_mult(src,eventdata,...
    text_current_status_actual));
button_row=uicontrol('Style','pushbutton',...
    'Position',[690 235 95 50],'String','Rows',...
    'CallBack', @(src,eventdata)row(src,eventdata,...
    text_current_status_actual));
button_dimer=uicontrol('Style','pushbutton',...
    'Position',[690 175 95 50],'String','Dimer',...
    'CallBack', @(src,eventdata)dimer(src,eventdata,...
    text_current_status_actual));
button_atomic=uicontrol('Style','pushbutton',...
    'Position',[795 235 95 50],'String','Atomic',...
    'CallBack', @(src,eventdata)atomic(src,eventdata,...
    text_current_status_actual));
button_asym=uicontrol('Style','pushbutton',...
    'Position',[795 175 95 50],'String','Asymmetric',...
    'CallBack', @(src,eventdata)asym(src,eventdata,...
    text_current_status_actual));
button_bad=uicontrol('Style','pushbutton',...
    'Position',[690 15 200 50],'String','Bad/Blurry',...
    'CallBack', @(src,eventdata)bad(src,eventdata,...
    text_current_status_actual));

button_open=uicontrol('Style','pushbutton',...
    'Position',[12 395 200 50],'String','Select Input Folder',...
    'CallBack', @inputfolder);
button_close=uicontrol('Style','pushbutton',...
    'Position',[12 235 200 50],'String','Select Output Folder',...
    'CallBack', @outputfolder);
button_undo=uicontrol('Style','pushbutton',...
    'Position',[230 449 100 50],'String','Undo',...
    'CallBack', @undo);
button_refresh=uicontrol('Style','pushbutton',...
    'Position',[571 449 100 50],'String','Next',...
    'CallBack', @(src,eventdata)refresh_image...
    (src,eventdata,input_folder,...
    image_axis,text_current_status_actual,image_axis));

% Start timer
tic

%% CORE LOOP
while repeat_loop == 1 && ishandle(FigHandle1) == 1
    % Set status string
    text_current_status_actual.String = 'Just Chillin`';
    
    % Get input/output folders from functions (P.S. fuck Mathworks for
    % this and not letting anything better exist)
    in_out = FigHandle1.UserData;
    if in_press == 1
        input_folder = extractfield(rdir([fol_in,'*\**\*.png']),'name');
    end
    
    if length(input_folder) == 2
        warndlg('Out of files!!!')
        beep
        inputfolder(gca)
    end
    
    % Output folder button press
    if ischar(in_out) == 1
        % Set status string
        text_current_status_actual.String = 'Setting up output folder';
        text_output.String = in_out;
        
        output_folder = in_out;
        clear in_out;
        FigHandle1.UserData = 0;
        
        % Check if output folders exist and create accordingly
        if exist(fullfile(output_folder,'Unclassified (Quality)'),'dir')...
                == 0
            mkdir(output_folder,'Unclassified (Quality)')
        end
        if exist(fullfile(output_folder,'Unclassified (Multiple)'),...
                'dir') == 0
            mkdir(output_folder,'Unclassified (Multiple)')
        end
        if exist(fullfile(output_folder,'Rows'),'dir')...
                == 0
            mkdir(output_folder,'Rows')
        end
        if exist(fullfile(output_folder,'Atomic'),'dir')...
                == 0
            mkdir(output_folder,'Atomic')
        end
        if exist(fullfile(output_folder,'Dimer'),'dir')...
                == 0
            mkdir(output_folder,'Dimer')
        end
        if exist(fullfile(output_folder,'Asymmetric'),'dir')...
                == 0
            mkdir(output_folder,'Asymmetric')
        end
        if exist(fullfile(output_folder,'Bad or Blurry'),'dir')...
                == 0
            mkdir(output_folder,'Bad or Blurry')
        end
        if exist(fullfile(output_folder,'Classified'),'dir')...
                == 0
            mkdir(output_folder,'Classified')
        end
        
    elseif isstruct(in_out) == 0
        % Input folder button pressed
    else
        % Set status string and update name
        try
            text_current_status_actual.String = 'Setting up input files';
            input_folder = extractfield(in_out,'name');
            in_press = 1;
            FigHandle1.Name=['SPM Image Classifier 1.0 - Working On ',...
                num2str(length(input_folder)),' Files'];
            text_input.String = fol_in;
            
            % Send new input names to refresh button
            button_refresh.Callback = ...
                @(src,eventdata)refresh_image(src,eventdata,input_folder,...
                image_axis,text_current_status_actual,image_axis);
            clear in_out;
            
            
            % Refresh image
            refresh_image(gca,[],input_folder,...
                image_axis,text_current_status_actual,image_axis)
        catch
            warndlg('No matrix files found!')
        end
        FigHandle1.UserData = 0;
    end
    
    % Refresh image after classification event
    if renew == 1
        pause(0.2)
        refresh_image(gca,[],input_folder,...
            image_axis,text_current_status_actual,image_axis)
        renew = 0;
    end
    
    %% CLOSING ROUTINE
    % Check if figure is closed or stop button is pressed and if so, exit
    pause(0.1)
    if ishandle(text_current_status_actual) ~= 1
        repeat_loop = 0;
        clf
        close all
    end
end

% Display level of suffering
disp('---------------------------')
disp(['Images Classified: ',num2str(classified_images)])
disp(['Time Suffered For: ',datestr(toc/(24*60*60), 'HH:MM:SS')])
disp('---------------------------')

%% CALLBACKS
% Input folder
function inputfolder(src,~)

% Get directory
fol_in = uigetdir(pwd, 'Select a folder to input from:');
files = rdir([fol_in,'*\**\*.png']);

% Pass back
src.Parent.UserData = files;
assignin('base','fol_in',fol_in)
end

% Output folder
function outputfolder(src,~)

% Get directory
fol_out = uigetdir(pwd, 'Select a folder to output to:');

% Pass back
src.Parent.UserData = fol_out;
end

% Unclassified (quality)
function unclass_quality(~,~,text_current_status_actual,~,~)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
    
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Unclassified (Quality)';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Unclassified (Quality)\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
    
end
end

% Unclassified (multiple)
function unclass_mult(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Unclassified (Multiple)';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Unclassified (Multiple)\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Classify as row
function row(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Rows';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Rows\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Classify as dimer
function dimer(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Dimer';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Dimer\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Classify as atomic
function atomic(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Atomic';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Atomic\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Classify as asymmetric
function asym(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Asymmetric';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Asymmetric\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Classify as bad
function bad(~,~,text_current_status_actual)
failing = 1;

% Get file name and RGB values, making sure that the folders exist!!
try
    text_current_status_actual.String = 'Checking For Output Folder';
    pause(0.05)
    output_folder_fix = evalin('base','output_folder');
catch
    warndlg('Output Folder Not Selected!')
    beep
    failing = 0;
end
try
    text_current_status_actual.String = 'Checking For Input Folder';
    pause(0.05)
    file_name_fix = evalin('base','filename');
    fullfile_name_fix = evalin('base','view_file_name');
    fullfile_RGB_fix = evalin('base','view_file_RGB');
catch
    warndlg('Input Folder Not Selected!')
    beep
    failing = 0;
end
pause(0.5)
% If input and output folder selected
if failing ~=0
    % Save result
    text_current_status_actual.String = ...
        'Saving as Bad/Blurry';
    pause(0.5)
    imwrite(fullfile_RGB_fix,[output_folder_fix,...
        '\Bad or Blurry\',file_name_fix,'.png'])
    
    % Move to "bin" so not selected again
    try
        movefile(fullfile_name_fix,[output_folder_fix,'\Classified'])
    catch
        assignin('base','renew',1);
    end
    
    % Delete matrix file so image will not re-appear
    delete_true = evalin('base','delete_true');
    if delete_true == 1
        %delete(fullfile_name_fix)
    end
    
    % Refresh image
    renew = 1;
    assignin('base','renew',renew);
    classified_images = evalin('base','classified_images');
    assignin('base','classified_images',classified_images+1);
end
end

% Undo
function undo(~,~)
assignin('base','thechosenone',1);
assignin('base','renew',1);
end

% Renew image
function refresh_image(~,~,~,~,text_current_status_actual,image_axis)

pause(0.1)
thechosenone = evalin('base','thechosenone');
image_no = evalin('base','image_no');
input_folder = evalin('base','input_folder');
% View random file
try
    
    % Try again if file format not mtrx or png
    rep = 1;
    while rep == 1
        
        % Get random file and determine if .png or .zmtrx
        if thechosenone == 0
            text_current_status_actual.String = 'Selecting Random File';
            pause(0.1)
            rand_no = randi(length(input_folder));
            assignin('base','image_no',rand_no);
        else
            % Callback for undo button pressed
            warndlg('Not Yet Implemented :(')
            
            rand_no = image_no;
            assignin('base','thechosenone',0);
        end
        [~,filename,ext] = fileparts(char(input_folder(rand_no)));
        view_file = char(input_folder(rand_no));
        
        % Convert if .mtrx
        if strcmp(ext,'.Z_mtrx') == 1
            text_current_status_actual.String = 'Converting .mtrx';
            pause(0.1)
            Ims = SPIW_open(view_file);
            CminV = min(Ims{1,1}.data(:));
            CmaxV= max(Ims{1,1}.data(:));
            RGB = Data2RGB(Ims{1,1}.data,nanomap,[CminV,CmaxV]);
            rep = 0;
        elseif strcmp(ext,'.png') == 1
            text_current_status_actual.String = ['Reading ',ext,' Image'];
            RGB = imread(view_file);
            rep = 0;
        end
        pause(0.1)
    end
    
    % Display and write to workspace
    text_current_status_actual.String = 'Rendering Image';
    imshow(RGB)
    image_axis.XAxis.Visible = 'off';
    image_axis.YAxis.Visible = 'off';
    assignin('base','view_file_name',view_file)
    assignin('base','view_file_RGB',RGB)
    assignin('base','filename',filename)
    pause(0.25)
catch
    % No input folder yet selected, so open dialogue
    beep
    warndlg('No Input File Avaliable!')
    inputfolder(gca)
end
end