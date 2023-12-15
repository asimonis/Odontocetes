



%% import a binary file and create an output template that can be used for testing
clear
file = 'H:\Odontocetes\NBHF\TrainingData\PG2_02_09_CCES_022_Ksp_384kHz\20181118\Click_Detector_Click_Detector_Clicks_20181118_224350.pgdf';
uid = 1000004; % the UID of the click to slect a template. 
sr=384000; 
%load the clicks
[clicks, fileinfo]= loadPamguardBinaryFile(file);
%select the click with correct UID to be used as a template
template = clicks([clicks.UID]==uid); 
%create a filename for the template
filename = ['clicktemplate_' num2str(uid) '.csv'];
%write template to csv file.
[clickstruct] = clickstruct2csv(template, sr, filename);



function [clickstruct] = clickstruct2csv(clickstruct, sr, filename)
%CLICKSTRUCT2CSV converts a click structure to a template that can be read
%by PAMGuard's matched click classifier.
A = clickstruct.wave(:,1)'; 
format long
dlmwrite(filename, A);
dlmwrite(filename, sr, '-append');
end