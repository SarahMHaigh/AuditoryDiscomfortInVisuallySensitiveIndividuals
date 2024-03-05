%% Auditory NIRS using modulated tones
% Hit space bar whenever fixation cross changes colour


clear all; 
Screen('Preference', 'SkipSyncTests', 0);
 
%% Set up triggering for NIRx
clear device

device_found = 0;
ports = serialportlist("available");

for p = 1:length(ports)
    device = serialport(ports(p),115200,"Timeout",1);
    device.flush()
    write(device,"_c1","char")
    query_return = read(device,5,"char");
    if length(query_return) > 0 && query_return == "_xid0"
        device_found = 1;
        break
    end
end

if device_found == 0
    disp("No XID device found. Exiting.")
    return
end

disp("Raising all output lines for 1 second.")

setPulseDuration(device, 1000)
write(device,sprintf("mh%c%c", 255, 0), "char")
pause(2)

%% Start experiment
ID='test1'; % change
if isfile([ID 'aud_behNIRS.txt'])
    ID = [ID '_2'];
end
HideCursor;	% Hide the mouse cursor

% start the log file for reporting
logFID = fopen([ID '_logAud.txt'],'at+');      % open a file as log file for everything (APPEND DATA)

[windowPr,rect] = Screen('OpenWindow',0,0,[]);%0 0 1920/2,1080/2]);
width=rect(RectRight)-rect(RectLeft);
height=rect(RectBottom)-rect(RectTop);

blocks = 2;
trials = repmat([1 2],1,4);
att = repmat([1 0 0 0],1,4);

RT = [];

% fixation cross coords
H=width/2; 
H1=width/2-(width/2/60);
H2=width/2+(width/2/60);
V=height/2;
V1=height/2-(width/2/60);
V2=height/2+(width/2/60);
penWidth=2;
textsize=40;

white = WhiteIndex(windowPr);
black = BlackIndex(windowPr);
gray = (white+black)/2;
[xCenter, yCenter] = RectCenter(rect);
Font='Arial'; Screen('TextSize',windowPr,textsize); Screen('TextFont',windowPr,Font); Screen('TextColor',windowPr,black);

a = gray*.75;
b = gray*.75; %.01 

Screen('FillRect',windowPr,127.5,rect);
DrawFormattedText(windowPr, 'Experimenter:', 'center', (rect(4)/8)*3);
DrawFormattedText(windowPr, 'Make sure volume is set to 40', 'center', (rect(4)/8)*4);
DrawFormattedText(windowPr, 'Press any key to continue', 'center', (rect(4)/8)*5);
Screen('Flip', windowPr); 
WaitSecs(.1);
KbWait;

Screen('FillRect',windowPr,127.5,rect);
DrawFormattedText(windowPr, 'Hit button when you see the central cross flash', 'center', (rect(4)/8)*3);
DrawFormattedText(windowPr, 'Remember to focus on center cross', 'center', (rect(4)/8)*4);
DrawFormattedText(windowPr, 'Press any key to continue', 'center', (rect(4)/8)*5);
Screen('Flip', windowPr); 
WaitSecs(.1);
KbWait;  

%% Modulated tones

% Specs for the tone
Fs = 44100;      %# Samples per second
dt = 1/Fs;
nSeconds = 2;   %# Duration of the sound
t_beep = [dt:dt:nSeconds];
Tattack = 0.1; 
bump1=2; % how many bumps in the tone
bump2=16;
% cosine ramp
A=(0:dt:Tattack)/Tattack;
Tfade=(pi/(length(A)-.5));
RaisedCosine=cos(pi:Tfade:3*pi)+1;
RaisedCosineNormSquare=(RaisedCosine/max(RaisedCosine)).^2;
A=RaisedCosineNormSquare(1:(length(RaisedCosineNormSquare)/2));
rampUp = A;
rampDown = fliplr(rampUp);

pad = zeros(1,50);

% Frequency 1
toneFreq = 1000;  %# Tone frequency, in  Hertz
yT = [sin(2*pi*toneFreq*t_beep)];% zeros(size(t_beep))];
maxVol = ones(1,length(yT));
Vol1 = yT.*(maxVol*0.5);
% main body of tone
modul = (1+0.5.*[sin(2*pi*10*t_beep)]).*Vol1;
mid = ones(1,length(modul) - length(rampUp) - length(rampDown));
envelope1 = [rampUp mid rampDown];
clearvars mid maxVol yT toneFreq modul

% Frequency 2
toneFreq = 3000;  %# Tone frequency, in  Hertz
yT = [sin(2*pi*toneFreq*t_beep)];% zeros(size(t_beep))];
maxVol = ones(1,length(yT));
Vol2 = yT.*(maxVol*0.5);
% main body of tone
modul = (1+0.5.*[sin(2*pi*10*t_beep)]).*Vol2;
mid = ones(1,length(modul) - length(rampUp) - length(rampDown));
envelope2 = [rampUp mid rampDown];
clearvars mid maxVol yT toneFreq modul

Screen('Flip', windowPr);
WaitSecs(0.5); 

KbQueueCreate;

Start = GetSecs;

%% Start trials
for j = 1:blocks

    Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
    Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
    Screen('Flip', windowPr);
    WaitSecs(1+(rand/2));

    trialrand = trials(randperm(length(trials)));
    attrand = att(randperm(length(att)));
    
    clearvars pressed firstPress secs0
    clear KbWait
    KbQueueStart;
    
for i = 1:length(trials)    

    if trialrand(i)==1
        
        for rep = 1:6

            % To write a trigger (1)
           write(device,sprintf("mh%c%c", 1, 0), "char")
           pause(.01)
            
            Screen('FillRect',windowPr, gray);
            Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
            Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
            Screen('Flip', windowPr);
            modul = (1+0.9.*[sin(2*pi*bump1*t_beep)]).*Vol1;
            a = sqrt(mean(modul.^2));
            shapedVol = modul.*envelope1;
            presentVol = [pad shapedVol pad];
            sound(presentVol, Fs);

            WaitSecs(2);        
            
            Screen('FillRect',windowPr, gray);
            Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
            Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
            Screen('Flip', windowPr);
            WaitSecs(0.5);

            [pressed, firstPress]=KbQueueCheck;
            naming = sort(KbName(firstPress))
            if strmatch('ces',naming)
                Screen('CloseAll');
                fclose(logFID);
            end
        end
        
    elseif trialrand(i)==2

        for rep = 1:6
                        
           write(device,sprintf("mh%c%c", 2, 0), "char")
           pause(.01)

            Screen('FillRect',windowPr, gray);
            Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
            Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
            Screen('Flip', windowPr);
            modul = (1+0.9.*[sin(2*pi*bump2*t_beep)]).*Vol1;
            b = sqrt(mean(modul.^2));
            shapedVol = modul.*envelope1;
            presentVol = [pad shapedVol pad]; 
            sound(presentVol, Fs);        
            
            WaitSecs(2);
                        
            Screen('FillRect',windowPr, gray);
            Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
            Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
            Screen('Flip', windowPr);
            WaitSecs(0.5);

            [pressed, firstPress]=KbQueueCheck;
            naming = sort(KbName(firstPress))
            if strmatch('ces',naming)
                Screen('CloseAll');
                fclose(logFID);
            end      
        end
    end
    
    % Attention catch trials
    if attrand(i) == 1        
        Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
        Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
        Screen('Flip', windowPr);
        WaitSecs(9);
        secs0 = GetSecs;        
        Screen('DrawLine', windowPr ,[255 255 255], H1, V, H2, V, penWidth); 
        Screen('DrawLine', windowPr ,[255 255 255], H, V1, H, V2, penWidth);
        Screen('Flip', windowPr);
        WaitSecs(.1);
        
        write(device,sprintf("mh%c%c", 5, 0), "char")
        pause(.01) 
        
        Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth); 
        Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
        Screen('Flip', windowPr);
        WaitSecs(2);
        [pressed, firstPress]=KbQueueCheck;
        naming = sort(KbName(firstPress))
        if strmatch('ces',naming)
        Screen('CloseAll');
        fclose(logFID);
        end

        if pressed==0
            Screen('DrawLine', windowPr ,[255 0 0], H1, V, H2, V, penWidth);
            Screen('DrawLine', windowPr ,[255 0 0], H, V1, H, V2, penWidth);
            Screen('Flip', windowPr);
            WaitSecs(.1);
        end
        Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
        Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
        Screen('Flip', windowPr);
        WaitSecs(15);
    else
        Screen('DrawLine', windowPr ,[0 0 0], H1, V, H2, V, penWidth);
        Screen('DrawLine', windowPr ,[0 0 0], H, V1, H, V2, penWidth);
        Screen('Flip', windowPr);
        WaitSecs(24+(rand*5));
    end

    % Collect keyboard response and record trial details
    sz = size(RT);
    RT(1,sz(2)+1) = trialrand(i);
        if attrand(i) == 1 
            if pressed == 1   
                RT(2,sz(2)+1) = 1;
                x = 1;
                RT(3,sz(2)+1) = max(firstPress)-secs0;
                y = max(firstPress)-secs0;
            else RT(2,sz(2)+1) = 2;
                x = 2;
                RT(3,sz(2)+1) = 100;
                y=100;
            end
        else 
            RT(2,sz(2)+1) = 0;
            x = 0;
            RT(3,sz(2)+1) = 0;
            y = 0;
        end
                
        % print to logfile:
        fprintf(logFID,['%d\t%d\t%d\t%d\t\n']', trialrand(i), attrand(i), x, y);

        clearvars pressed firstPress secs0
end   
        
if j<blocks
    DrawFormattedText(windowPr, 'Please take a break', 'center', (rect(4)/8)*3);
    DrawFormattedText(windowPr, 'Press any key to continue', 'center', (rect(4)/8)*4);
    Screen('Flip', windowPr);
    WaitSecs(.1);
    KbWait;
    clearvars pressed firstPress secs0
    clear KbWait
    KbQueueFlush;
else
    DrawFormattedText(windowPr, 'You have finished', 'center', (rect(4)/8)*3);
    DrawFormattedText(windowPr, 'Please find the experimenter', 'center', (rect(4)/8)*4);
    Screen('Flip', windowPr);
    WaitSecs(2);  
end
end
    
%% Finish, save and close

Screen('CloseAll');
fclose(logFID);

Finish = GetSecs-Start;

dlmwrite([ID 'aud_behNIRS.txt'],RT);
xlswrite([ID 'aud_behNIRS.xlsx'],RT);

function byte = getByte(val, index)
    byte = bitand(bitshift(val,-8*(index-1)), 255);
end

function setPulseDuration(device, duration)
%mp sets the pulse duration on the XID device. The duration is a four byte
%little-endian integer.
    write(device, sprintf("mp%c%c%c%c", getByte(duration,1),...
        getByte(duration,2), getByte(duration,3),...
        getByte(duration,4)), "char")
end

