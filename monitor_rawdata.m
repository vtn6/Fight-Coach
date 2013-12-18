
close all hidden;
clearvars;
sampleRate = 0.02;
%
%DefenseMode: For 2 minutes, the program instructs the user to dodge left,
%right or down, meausres his reaction time and gives him a score at the end
%of the 2 minutes
%DamageMode: For 2 minutes, the athlete tries to deal as much damage as
%possible. The score is given at the end and a graph showing the damage
%outpout per second.
%FreeTrainingMode:No time limit, displays a punch counter (how many left
%punches and right punces), what was the hardest punch, and what was the
%fastest consecutive punces.

%state 1 corresponds to DefenseMode, 2 corresponds to DamageMode, 3
%correseponds to FreeTrainingMode
states = [1,2,3];
currentStateIndex = 3; %this index keeps track of which state the programis  in

%length of a round in seconds; 30 for development; 120 for real round
roundLength = 60; 


%in our prototype we are using z thresholds for dodging left and right, y
%threshold for dodging backwards and x threhold for ducking
zDodgeAccelerationThreshold = 2000;% this is equivalent to 1.5Gs
yDodgeAccelerationThreshold = 0;
xDodgeAccelerationThreshold = 2000; %dodge backwards approx 0.5G
dodgeIntervalSeconds = 3; %how often dodge instructions are sounded off
penaltyTime = 3;

%variables needed for damage mode: rate at which the damage bar decreses,
%the rate at which the damage bar builds up, and the power bar level vs
%time
damageBarMax = 1000000;
damageOutputDataSize = roundLength/sampleRate; %number of damageOutputData points to record
xDamageAccelerationThreshold = 4000;%must be greater than 2G's to register
yDamageAccelerationThreshold = 4000;
damageOutputDecayRate = 1500;
damageOutput = 500;%initialize the current damage output rate 
damageLimitBreakerFlag = 0;


%GX values above this threshold will increase the stateAcuumulator, once
%the stateaAccumulator reaches the stateAccumulatorChangeThresold, then the
%programwhillchangestates
yRotationThresholdStateChange = 15000;  
stateAccumulator = 0;
stateAccumulatorChangeThreshold = 40;

% Creating Sounds

[ryuTheme,f] = audioread('RyuTheme.mp3');
ryuTheme = audioplayer(ryuTheme,f);

[selectYourTrainingModeSound,f] = audioread('SelectYourTrainingMode.wav');
selectYourTrainingModeSound = audioplayer(selectYourTrainingModeSound,f);

[boxingBellSound,f] = audioread('BoxingBell.wav');
boxingBellSound = audioplayer(boxingBellSound,f);

[hadokenSound,f] = audioread('hadoken1.wav');
hadokenSound = audioplayer(hadokenSound,f);

[shroyukenSound,f] = audioread('shroyuken.wav');
shroyukenSound = audioplayer(shroyukenSound,f);

[defenseModeSound,f] = audioread('DefenseMode.wav');
defenseModeSound = audioplayer(defenseModeSound,f);

[damageModeSound,f] = audioread('DamageMode.wav');
damageModeSound = audioplayer(damageModeSound,f);

[freeTrainingModeSound,f] = audioread('FreeTrainingMode.wav');
freeTrainingModeSound = audioplayer(freeTrainingModeSound,f);

[threeTwoOneSound,f] = audioread('321.wav');
threeTwoOneSound = audioplayer(threeTwoOneSound,f);

[leftSound,f] = audioread('Left.wav');
leftSound = audioplayer(leftSound,f);


[rightSound,f] = audioread('Right.wav');
rightSound = audioplayer(rightSound,f);

[backSound,f] = audioread('Back.wav');
backSound = audioplayer(backSound,f);

[duckSound,f] = audioread('Duck.wav');
duckSound = audioplayer(duckSound,f);

% testing the sounds

% playblocking(hadokenSound);
% playblocking(shroyukenSound);
% playblocking(defenseModeSound)
% playblocking(damageModeSound)
% playblocking(freeTrainingModeSound)
% playblocking(threeTwoOneSound);
% playblocking(backSound);
% playblocking(rightSound);
% playblocking(leftSound);
% playblocking(duckSound);


% Initialize the game timers and flags needed to maintain the game state
%the flags are zero until set by the prgram: this allows the 321 and
%endRound sounds to be played only after the if statement responsible for
%the state change sets these flags to 1, signifying the beginning of a
%round
beginTimer = tic;
beginTimerFlag = 0;
tempTimer = tic;
tempTimerFlag = 0;


%Defense Mode Variables
dodgeTimer = tic;
dodgeTimerFlag = 0;
dodgeCaptureFlag = 0; %this flag makes sure that the dodge is only captured once when the threshold is exceeded

% 1 corresponds to left; 2 corresponds to right; 3 corresponds to back, 4
% corresponds to duck
dodgeMoveInstruction = 0;
reactionTime = 0;
reactionTimeData = [];


%Damage mode variables
damageModeFlag = 0;
damageOutputData = 0;
% damageOutputData = zeros(1,damageOutputDataSize);
nDamageData = 1:damageOutputDataSize; %index for damageOutputData

%Round Timer variables: needed to time the duration of the training round
roundTimer = tic;
roundTimerFlag = 0;


% set up figures and windows
wndw = 200;
gmax = 5000;

n=1:wndw;

XLeft = zeros(1, wndw);
Y = zeros(1, wndw);
Z = zeros(1, wndw);
GX = zeros(1, wndw);
GY = zeros(1, wndw);
GZ = zeros(1, wndw);

XRight = zeros(1, wndw);
YRight = zeros(1, wndw);
ZRight = zeros(1, wndw);
GYRight = zeros(1, wndw);

figure(1);
set(gcf,'Color','black');

subplot(2,4,1);
h1 = plot(n,XLeft);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')


subplot(2,1,2);
subplot(2,4,2);
h2 = plot(n,Y);
title('Left Data','color','red','FontName','Courier','FontSize',20)
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')


subplot(2,4,3);
h3 = plot(n,Z);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

subplot(2,4,4);
h4 = plot(n,GY);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

subplot(2,4,5);
h5 = plot(n,XRight);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

subplot(2,4,6);
h6 = plot(n,YRight);
title('Right Data','color','red','FontName','Courier','FontSize',20)
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

subplot(2,4,7);
h7 = plot(n,ZRight);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

subplot(2,4,8);
h8 = plot(n,GYRight);
axis([0 wndw -gmax gmax]);
set(gca,'YColor','red','XColor','red')

% data presentation stuff for damage mode
figure(2)
set(gcf,'Color','black');

subplot(1,2,1);
timetimeFoo = clock;
d1 = bar(damageOutput);
title('Damage Bar','color','red','FontName','Courier','FontSize',20)
axis([0 2 -1 damageBarMax]);
set(gca,'YColor','red','XColor','red')

set(gca,'Xticklabel',[])
%
subplot(1,2,2);
d2 = plot(damageOutputData);
% d2 = plot(nDamageData,damageOutputData);
title('Damage Output vs Time','color','red','FontName','Courier','FontSize',20)
axis([0 roundLength/sampleRate 0 damageBarMax]);
set(gca,'YColor','red','XColor','red')
set(gca,'Xticklabel',[]);
%
% data presentation stuff for defense mode
figure(3)   
set(gcf,'Color','black');
defenseHandle = stem([0,0,0,0]);
axis([0 roundLength/dodgeIntervalSeconds 0 4]);
set(gca,'YColor','red','XColor','red')
title('Defense Mode','color','red','FontName','Courier','FontSize',20)
xlabel('Attempts');
ylabel('Reaction Time (secs)','FontName','Courier','FontSize',20)

averageReactionTimeString = 'Average Reaction Time: '
meanTextHandle = text(roundLength/(2*dodgeIntervalSeconds),3.5,averageReactionTimeString,...
    'VerticalAlignment','middle',...
    'FontSize',15 ,...
    'FontName','Courier',...
    'Color','red',...
	'HorizontalAlignment','center');

% set(gca,'Xticklabel',[])

%% port stuff

port = serial('/dev/tty.RNBT-5AF7-RNI-SPP','BaudRate',9600,'InputBufferSize',16384,'Timeout',30);
portRight = serial('/dev/tty.RNBT-5AEA-RNI-SPP','BaudRate',9600,'InputBufferSize',16384,'Timeout',30);  
%% open left fight coach
fopen(port);
%%
flushinput(port);
fopen(portRight);

% get(port,{'InputBufferSize','BytesAvailable'})
% disp(get(port,'Name'));
% prop=(get(port,'BaudRate'));
% disp(['Baud Rate: ',num2str(prop)]);



%%
d = [0 0 0 0];
dRight = [0 0 0 0];
flushinput(port);
flushinput(portRight);
play(selectYourTrainingModeSound);
while true
    
    if port.BytesAvailable > 10
        d = fscanf(port,'%d');
    end

    if portRight.BytesAvailable > 10
        dRight = fscanf(portRight,'%d');
    end

    
    % these guys are always shifting to the left
    XLeft(1)=[];
    Y(1) = [];
    Z(1) = [];            
    GY(1) = [];
    XRight(1) =[];
    YRight(1) = [];
    ZRight(1) = [];
    GYRight(1) = [];

    
    if length(d) == 4
        XLeft(wndw) =  d(1);
        Y(wndw) = d(2);
        Z(wndw) = d(3);
        GY(wndw) = d(4);
    else
        XLeft(wndw) =  0;
        Y(wndw) = 0;
        Z(wndw) = 0;
        GY(wndw) = 0;
    end

    if length(dRight) == 4
        XRight(wndw) =  dRight(1);
        YRight(wndw) = dRight(2);
        ZRight(wndw) = dRight(3);
        GYRight(wndw) = dRight(4);     
    else
        XRight(wndw) =  0;
        YRight(wndw) = 0;
        ZRight(wndw) = 0;
        GYRight(wndw) = 0; 
    end    
    
    if currentStateIndex == 1 %defense mode
        set(h1,'XData',n,'YData',XLeft)
        set(h2,'XData',n,'YData',Y)
        set(h3,'XData',n,'YData',Z)
%         set(h4,'XData',n,'YData',GY);
        set(h5,'XData',n,'YData',XRight)
        set(h6,'XData',n,'YData',YRight)
        set(h7,'XData',n,'YData',ZRight)
%         set(h8,'XData',n,'YData',GYRight);
        drawnow;
    end
    
     if currentStateIndex == 2 %damage mode dont draw
%         set(h1,'XData',n,'YData',XLeft)
%         set(h2,'XData',n,'YData',Y)
%         set(h3,'XData',n,'YData',Z)
%         set(h4,'XData',n,'YData',GY);
%         set(h5,'XData',n,'YData',XRight)
%         set(h6,'XData',n,'YData',YRight)
%         set(h7,'XData',n,'YData',ZRight)
%         set(h8,'XData',n,'YData',GYRight);
%         drawnow;
     end   
    
    if currentStateIndex == 3 %free training mode
        set(h1,'XData',n,'YData',XLeft)
        set(h2,'XData',n,'YData',Y)
        set(h3,'XData',n,'YData',Z)
        set(h4,'XData',n,'YData',GY);
        set(h5,'XData',n,'YData',XRight)
        set(h6,'XData',n,'YData',YRight)
        set(h7,'XData',n,'YData',ZRight)
        set(h8,'XData',n,'YData',GYRight);
        drawnow;
    end
    
    %% This is the state accumulator
    
    %if the left hand Y rotation acceleration is above the threshold        
    if GY(wndw)>yRotationThresholdStateChange
       stateAccumulator =  stateAccumulator +1;
    end
    
    %% stuff needed to change states
    %State change stuff
    if stateAccumulator > stateAccumulatorChangeThreshold
        stateAccumulator = 0;
        currentStateIndex = mod(currentStateIndex,length(states))+1;%this basically allows us to cycle between states
        dodgeTimerFlag = 0;
        roundTimerFlag = 0;
        tempTimerFlag = 0;
        beginTimerFlag = 0;
        damageLimitBreakerFlag = 0;
        
        %Defense Mode
        if currentStateIndex == 1 
            figure(3)
            timetimeFoo = clock;
            title(['Defense Mode Session at:' ' ' num2str(timetimeFoo(3))...
                '/' num2str(timetimeFoo(2)) '/' num2str(timetimeFoo(1))...
                ' ' num2str(timetimeFoo(4)) ':' num2str(timetimeFoo(5))],...
                'FontName','Courier','FontSize',20);
%             axis([0 roundLength/dodgeIntervalSeconds 0 5]);
            reactionTimeData = []; %re-initialize
            set(defenseHandle,'YData',reactionTimeData);
            set(meanTextHandle,'String',averageReactionTimeString);
            
            play(defenseModeSound);
            beginTimer = tic;
            beginTimerFlag = 1;
            dodgeCaptureFlag = 0;
            damageModeFlag = 0;
            
%                     set(gcf,'units','normalized','outerposition',[0 0 1 1])
            
        %Damage Mode
        elseif currentStateIndex == 2
            figure(2)
            timetimeFoo = clock;
            play(damageModeSound);
            damageOutput = 10; % re-initialize
            damageOutputData = 0;
            set(d1,'YData',damageOutput);
            set(d1,'FaceColor','blue');
            ylabel(['Damage Mode Session at:' ' ' num2str(timetimeFoo(3))...
                '/' num2str(timetimeFoo(2)) '/' num2str(timetimeFoo(1))...
                ' ' num2str(timetimeFoo(4)) ':' num2str(timetimeFoo(5))],...
                'FontName','Courier','FontSize',10);

            set(d2,'YData',damageOutputData);
            drawnow;
            beginTimer = tic;
            beginTimerFlag = 1;%keeps time until 321Sound
            dodgeCaptureFlag = 0;
            damageModeFlag = 1;
            
            
        %Free Training Mode
        elseif currentStateIndex == 3
            play(freeTrainingModeSound);
            beginTimer = tic;
            beginTimerFlag = 1; %keeps time until 321Sound
            dodgeCaptureFlag = 0;
            damageModeFlag = 0;
            figure(1);
%                     set(gcf,'units','normalized','outerposition',[0 0 1 1])
        end   
    end % end of if stateAccumulator > stateAccumulatorChangeThreshold

    %% timing stuff needed for the beginning of rounds
    %after 10 seconds begin the round (the the user some time to
    %realize what mode he is in
    if toc(beginTimer) > 10 && beginTimerFlag == 1
        beginTimerFlag =0 ;
        play(threeTwoOneSound);
        tempTimer = tic;
        
        %begin the tempTimer which waits 4 secs (until the 321
        %sound is over and begin timing the round
        tempTimerFlag = 1; 
    end
    
    % we need an intermediate 4 secs before beginning the round
    % timer
    if toc(tempTimer) > 4 && tempTimerFlag == 1
        tempTimerFlag = 0;
        roundTimer = tic; %start the roundTimer
        if currentStateIndex == 1
            dodgeTimer = tic; %start the dodgeTimers
            dodgeTimerFlag = 1;
        elseif currentStateIndex == 2
            
        end
        roundTimerFlag = 1; %begin the round
    end
    
    %% Stuff needed for damageMode
    if damageModeFlag == 1 && roundTimerFlag == 1
        
        if damageOutput > 0 %only do the decay if > 0
            damageOutput = damageOutput - damageOutputDecayRate;
        else
            damageOutput = 0;
        end
        
        %if a punch is detected
        if Y(wndw) < -yDamageAccelerationThreshold
            damageOutput = damageOutput - Y(wndw);
        end
        
        if YRight(wndw) < -yDamageAccelerationThreshold
            damageOutput = damageOutput - YRight(wndw);
        end
        
        if damageOutput > 1/4*damageBarMax && damageLimitBreakerFlag == 0
            damageLimitBreakerFlag = 1;
            set(d1,'FaceColor','red');
            play(ryuTheme);
        end
        
        if damageOutput > damageBarMax
            damageOutput = damageBarMax - 10000;
            play(shroyukenSound);
        end
        
        set(d1,'YData',damageOutput); %now DRAW IT
        
        %this allows us to plot the value of the damage bar with
        %time
        damageOutputData = [damageOutputData damageOutput];
        set(d2,'YData',damageOutputData);
        drawnow;
    end
    
    %% timing stuff needed for defenseMode
    
    if toc(dodgeTimer) > dodgeIntervalSeconds && dodgeTimerFlag == 1 && roundTimerFlag ==1
        dodgeTimer = tic;%restart the dodgeTimer
        dodgeMove = 4*rand(1);
        if dodgeMove<1
            play(leftSound);
            dodgeMoveInstruction = 1;
        elseif dodgeMove<2
            play(rightSound);
            dodgeMoveInstruction = 2;
        elseif dodgeMove<3
            play(backSound);
            dodgeMoveInstruction = 3;
        else %dodgeMove >3 && <4
            play(duckSound);
            dodgeMoveInstruction = 4;
        end
        dodgeCaptureFlag = 1; %allow the dodgeCapture to happen 
    end
    
    
    if dodgeCaptureFlag == 1
        switch(dodgeMoveInstruction)
            case 1 %dodge left
                if ZRight(wndw)>zDodgeAccelerationThreshold
                    reactionTime = toc(dodgeTimer)-0.75;
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Z(wndw)> zDodgeAccelerationThreshold %if dodged right when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif XLeft(wndw)> xDodgeAccelerationThreshold %if dodged back when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Y(wndw)> yDodgeAccelerationThreshold %if ducked when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                end
            case 2 %dodge right
                if Z(wndw)>zDodgeAccelerationThreshold
                    reactionTime = toc(dodgeTimer)-0.75;
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;
                 
                 elseif Z(wndw)< -zDodgeAccelerationThreshold %if dodged left when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                 elseif XLeft(wndw)> xDodgeAccelerationThreshold %if dodged back when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Y(wndw)> yDodgeAccelerationThreshold %if ducked when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;                           
                end                    
            case 3 %dodge backwards
                 if XLeft(wndw)>xDodgeAccelerationThreshold
                    reactionTime = toc(dodgeTimer)-0.75;
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                 elseif Y(wndw)> yDodgeAccelerationThreshold %if ducked when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Z(wndw)< -zDodgeAccelerationThreshold %if dodged left when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Z(wndw)> zDodgeAccelerationThreshold %if dodged right when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;                                          
                end                   
            case 4 %duck
                 if Y(wndw)>yDodgeAccelerationThreshold
                    reactionTime = toc(dodgeTimer)-0.75;
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;

                elseif Z(wndw)< -zDodgeAccelerationThreshold %if dodged left when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0;
                    
                 elseif Z(wndw)> zDodgeAccelerationThreshold %if dodged right when you aren't supposed to
                    reactionTime = penaltyTime; %automatic 4 second penalty
                    reactionTimeData = [reactionTimeData reactionTime];
                    set(defenseHandle,'YData',reactionTimeData);
                    set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
                    dodgeCaptureFlag = 0; 
                end                   
        end %ennd of the switch
        
        if toc(dodgeTimer)> 0.9*dodgeIntervalSeconds %this is for when the user just doesn't do anything by the time the next instruction is called
            dodgeCaptureFlag = 0;
            reactionTime = dodgeIntervalSeconds;   
            reactionTimeData = [reactionTimeData reactionTime];
            set(defenseHandle,'YData',reactionTimeData);
            set(meanTextHandle,'String',[averageReactionTimeString ' ' num2str(mean(reactionTimeData))]);
        end
    end

    %% timing needed for the end of a round
    if toc(roundTimer) > roundLength && roundTimerFlag ==1
        roundTimerFlag = 0;
        dodgeTimerFlag = 0;
        play(boxingBellSound);
        if damageLimitBreakerFlag == 1
            damageLimitBreakerFlag = 0;
            stop(ryuTheme);
        end
        
        if currentStateIndex == 1 %if Defense Mode
            fileName = ['DefenseModeSession' num2str(timetimeFoo(3)) '-' num2str(timetimeFoo(2)) '-' num2str(timetimeFoo(1)) '-'  num2str(timetimeFoo(4)) num2str(timetimeFoo(5)) '.csv'];
            csvwrite(fileName,reactionTimeData);
        end
        
        if currentStateIndex == 2 %if damageMode
            fileName = ['DamageModeSession' num2str(timetimeFoo(3)) '-' num2str(timetimeFoo(2)) '-' num2str(timetimeFoo(1)) '-'  num2str(timetimeFoo(4)) num2str(timetimeFoo(5)) '.csv'];
            csvwrite(fileName,damageOutputData);
        end
        
    end
    
end % end of the while true
%%
fclose(port);
delete(port);
clear port;
fclose(portRight);
delete(portRight);
clear portRight;