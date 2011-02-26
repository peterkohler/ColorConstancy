clear all;
close all;

%% GET SUBJECT NAME

subName  = input('Initials of subject? [default=tmp] ','s');
if length(subName) < 1; subName = 'tmp'; end;
%subName = 'tmp';
useKB  = input('Use buttonbox? 1=yes, 2=no. [default=1] ');
if isnan(useKB); useKB = 1'; end;
%% OPEN SCREEN
HideCursor; %hides the cursor
ListenChar(2);
stColor = [145 145 145]; %[200 100 20]; 
bgColor = [0 0 0];
ScreenNum = max(Screen('Screens'));
[w,rect]=Screen('OpenWindow',ScreenNum,bgColor);%, [], [], [], [], kPsychNeedFastBackingStore);
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Priority(2); %sets the priority to the maximum possible
x0 = rect(3)/2; % screen center
y0 = rect(4)/2;
%% SET VARIABLES
mondNum = 40; %num of mondrians
trialsPer = 20; % trials per color
fixColor = [255 0 0];
fixlineColor = [255 255 255];
mondCount = 1;

% KEYS
if useKB ==1
    leftkey = 49;
    rightkey = 50;
else
    leftkey = KbName('right');
    rightkey = KbName('left');
end
%% LOAD IN CUBES AND CREATE TARGETS
picL = imread('./images/gtarget_L_tall.png'); % stimuli where target is in light
picS = imread('./images/gtarget_S_tall.png'); % stimuli where target is in shadow

cube(1)=Screen('MakeTexture',w,picS); %cube in shadow
cube(2)=Screen('MakeTexture',w,picL); %cube in light

colorVals (:,1) = [100 130 150 160 170 190 220];
colorVals (:,2) = [70 100 120 130 140 160 170];

%colorVals(:,1) = [170   190   200   205   210   220   240];
%colorVals(:,2)= [90   110   120   125   130   140   160];
    
numColors = length(colorVals);

tSize = (rect(4)/2)*(4/9)*.5; %4/9 if not tall. if tall 2/9 
imSize = [rect(3)*.5,rect(4)*.5];

imCoords(:,1) = [0, 0,rect(3)*.5,rect(4)]; % context on left side of screen
imCoords(:,2) = [rect(3)*.5, 0,rect(3),rect(4)]; %context on right side of screen

imCenter(:,1) = [sum(imCoords(1:2:3,1))/2;sum(imCoords(2:2:4,1))/2];
imCenter(:,2) = [sum(imCoords(1:2:3,2))/2;sum(imCoords(2:2:4,2))/2];

targetCoords(:,1) = [imCenter(1,1)-tSize,imCenter(2,1)-tSize,imCenter(1,1)+tSize,imCenter(2,1)+tSize];
targetCoords(:,2) = [imCenter(1,2)-tSize,imCenter(2,2)-tSize,imCenter(1,2)+tSize,imCenter(2,2)+tSize];

whole_Coords(:,:,2) = [0, 0; ...
                    0, rect(4);...
                    rect(3)*.5,rect(4);...
                    rect(3)*.5,0];
whole_Coords(:,1,1) = whole_Coords(:,1,2) + (rect(3)*.5);
whole_Coords(:,2,1) = whole_Coords(:,2,2);

%% TRIAL ORDER
tempColor = reshape((ones(trialsPer,1))*(1:numColors),trialsPer*numColors,1); 
tempContext = ones(trialsPer*numColors,1);
tempContext(2:2:length(tempContext))=2;
tempSide = [];
for z = 1:numColors
    tempSide = [tempSide;ones(trialsPer/2,1);ones(trialsPer/2,1)*2];
end
randOrder = randperm(length(tempContext));
RunOrder = [tempColor(randOrder),tempContext(randOrder),tempSide(randOrder)];

%% INITIALIZE STAIRCASES

%% LOAD IN MONDRIANS
cd mondrians
for m = 1:mondNum
    temp_image = imread(['ovals' num2str(m) '.bmp'],'bmp');
    mond(m)=Screen('MakeTexture',w,temp_image);
end
cd ..  
%% SHOW STIMULI
if useKB == 1;
    [P4, openerror] = IOPort('OpenSerialPort', 'COM1','BaudRate=115200'); %opens port for receiving scanner pulse
    IOPort('Flush', P4); %flush event buffer
else
end

data = zeros(trialsPer*2,6);

for trial = 1:length(RunOrder)    
    Screen('DrawTexture',w,cube(RunOrder(trial,2)),[],imCoords(:,RunOrder(trial,3)));
    Screen('FillRect',w,stColor,targetCoords(:,RunOrder(trial,3)));
    tempTest = colorVals(RunOrder(trial,1),RunOrder(trial,2));
    Screen('FillPoly',w,ones(1,3)*tempTest,whole_Coords(:,:,RunOrder(trial,3)));
    Screen('FillRect',w,fixlineColor,[x0-5,0,x0+5,rect(4)]); % fixation
    Screen('FillRect',w,fixColor,[x0-5,y0-5,x0+5,y0+5]); % fixation
    [OnsetTime]=Screen('Flip',w,[],2);
    WaitSecs(.5);
    KeyCode = zeros(1,256);
    pulse = [];
    if useKB == 1
        while isempty(pulse) || (pulse~=leftkey && pulse~=rightkey)
            [pulse,temptime,readerror] = IOPort('read',P4,1,1);
            mondCount=mondCount+1;
            if mondCount > mondNum
                mondCount = 1;
            else
            end
            Screen('DrawTexture',w,mond(mondCount));
            Screen('FillRect',w,fixlineColor,[x0-5,0,x0+5,rect(4)]); % fixation
            Screen('FillRect',w,fixColor,[x0-5,y0-5,x0+5,y0+5]); % fixation
            Screen('Flip',w);
        end
        if (pulse == leftkey && RunOrder(trial,3)==1) || (pulse == rightkey && RunOrder(trial,3)==2) %selected context
            data(trial,:) = [tempTest,RunOrder(trial,2),RunOrder(trial,3),pulse,1,temptime-OnsetTime];
        else %% selected comparison
            data(trial,:) = [tempTest,RunOrder(trial,2),RunOrder(trial,3),pulse,2,temptime-OnsetTime];
        end
    else
        while ~KeyCode(leftkey) && ~KeyCode(rightkey)
            [KeyIsDown,temptime,KeyCode] = KbCheck;
            mondCount=mondCount+1;
            if mondCount > mondNum
                mondCount = 1;
            else
            end
            Screen('DrawTexture',w,mond(mondCount));
            Screen('FillRect',w,fixlineColor,[x0-5,0,x0+5,rect(4)]); % fixation
            Screen('FillRect',w,fixColor,[x0-5,y0-5,x0+5,y0+5]); % fixation
            Screen('Flip',w);
            WaitSecs(.15-(GetSecs-temptime));
        end
        if (KeyCode(leftkey)==1 && RunOrder(trial,3)==1) || (KeyCode(rightkey)==1 && RunOrder(trial,3)==2) %selected context
            data(trial,:) = [tempTest,RunOrder(trial,2),RunOrder(trial,3),KeyCode(rightkey)+1,1,temptime-OnsetTime];
            KeyCode = [];
        else %% selected comparison
            data(trial,:) = [tempTest,RunOrder(trial,2),RunOrder(trial,3),KeyCode(rightkey)+1,2,temptime-OnsetTime];
            KeyCode = [];
        end
    end     
    name = sprintf('raw_data_%s_%s.mat',subName,date);
    save(name, 'data'); %saves the rawdata
end
%% ANALYSE RESULTS

ShadowData = data(data(:,2)==1,:);
LightData = data(data(:,2)==2,:);
for c=1:7
    tempdata = ShadowData(ShadowData(:,1)==colorVals(c,1),:);
    PercentContext(c,1) = (length(tempdata)-numel((find(tempdata(:,5)==1))))/length(tempdata)*100;
    tempdata = LightData(LightData(:,1)==colorVals(c,2),:);
    PercentContext(c,2) = (length(tempdata)-numel((find(tempdata(:,5)==1))))/length(tempdata)*100;
end

superColors(:,1) = 170:.1:240;
superColors(:,2) = 90:.1:160;

data_to_fit = [PercentContext,ones(length(colorVals),1)];
b(:,1) = glmfit(colorVals(:,1),data_to_fit(:,1)/100,'binomial','logit');
b(:,2) = glmfit(colorVals(:,2),data_to_fit(:,2)/100,'binomial','logit');
fit_data(:,1) = 100*exp(b(1,1)+ b(2,1)*superColors(:,1))./(1+exp(b(1,1)+b(2,1)*superColors(:,1)));
fit_data(:,2) = 100*exp(b(1,2)+ b(2,2)*superColors(:,2))./(1+exp(b(1,2)+b(2,2)*superColors(:,2)));
pse(1) = -b(1,1)/b(2,1);
pse(2) = -b(1,2)/b(2,2);

plot(superColors(:,1),fit_data(:,1))
hold on
plot(superColors(:,2),fit_data(:,2),'r')
plot(colorVals(:,1),PercentContext(:,1))
plot(colorVals(:,2),PercentContext(:,2),'r')
hold off

PSE_SHADOW = round(pse(1))
PSE_LIGHT = round(pse(2))

sca;