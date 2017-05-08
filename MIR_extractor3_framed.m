%Sergio Giraldo 2012, MTG
%This script is an variation of the initial MIR_extractor3.m, in which the
%songs are splited in temporal frames. A hope size for widows sliding is
%also defined. This is done to fit te extracted data from the openvive eeg
%signal, in order to mix both extracted features in to a single data base.

%This scripy uses the MIR toolbox library to extract features of songs within a
%folder. The folder structure should be like this:
%
%/main_folder/
%/main_folder/class
%/main_folder/class/songs.wav

% Also a temporal folder must be created in your current work folder as /temp (do it
% automatically!)
%
% for some reason de mp3 read function give some problems. To prevent the
% script to fail, better use wav files format
%
% The features extracted are based on [Pasi Saari, Tuomas Eerola, Olivier
% Lartillot, "Generalizability and simplicity as criteria in feature
% selection: Application to mood classification in music", IEEE 
% Transactions on Audio, Speech, and Language Processing, 19-6, pp. 
% 1802-1812, 2011.]

%%%%%%%Choose database folder from HD
clear all;
Folder=uigetdir('/','Choose your song database main folder');

%Get each subgenre from folder names on a array
class=dir(Folder);
class_len=length(class);%number of clases(-2)

%inizialize text file and output format
TextFile=strcat(Folder,'/','Class_descriptors.txt');%create an name file on root folder
fileID=fopen(TextFile,'w');
fprintf(fileID,'File_Name,tin,tout,Em,Ed,El,LEm,ATm,Asm,ASd,EDm,FPm,FMm,FCm,Tm,Td,PCm,PCd,Pm,Pd,Cm,Cd,Cl,Ch,KCm,KCd,Mm,Md,Hm,ESm,Rm,Im,Id,Bm,Bd,SCm,SCd,Zm,Zd,Sm,Km,SEm,SEd,SFm,Fm,REm,REd,M1m,D1m,M2m,D2m,M3m,D3m,M4m,D4m,M5m,D5m,M6m,D6m,M7m,D7m,RSm,RSd,RRm,RRd,RTm,RTd,RGm,RGd,class\r\n');
formatSpec =   '%s       ,%f ,%f  ,%f,%f,%f,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f,%f,%f ,%f ,%f,%f,%f,%f,%f,%f,%f ,%f ,%f,%f,%f,%f ,%f,%f,%f,%f,%f,%f ,%f ,%f,%f,%f,%f,%f ,%f ,%f ,%f,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%f ,%s\r\n';

%h = waitbar(0,'Calculating descriptors for data set...');

%window size and hop size

W=2;%secs
H=0;%secs
%audio_length=18;%segs maximun length to analyse given the shortest excerpt (14seg)


%%%%Descriptors calculation
for i=1:class_len, %for each class folder (do not count . and .. 
    if ~(strcmp(class(i,1).name,'.'))&& ~(strcmp(class(i,1).name,'..'))&& ~(strcmp(class(i,1).name,'.DS_Store')) 
%An if function to avoid trying to open . and .. DOS comands listed by dir as files        
        SubFolder=strcat(Folder,'/',class(i,1).name);%create subfolde path
        songs=dir(SubFolder);%get subfolder song names
        l_songs=length(songs);%get sample size (-2)
        for j=1:l_songs,%for each song in folder
            if ~(strcmp(songs(j,1).name,'.'))&& ~(strcmp(songs(j,1).name,'..'))&&~(strcmp(songs(j,1).name,'Class_descriptors.txt'))&& ~(strcmp(songs(j,1).name,'.DS_Store')) 
%An if function to avoid trying to open . and .. DOS comands listed by dir as files 
%and also to avoiAd trying to open the csv text file as a sound file
                File=strcat(SubFolder,'/',songs(j,1).name);%create path to file
%%%%%%Extract part of the audio
                audio_length=mirgetdata(mirlength(miraudio(File)));
                if H==0
                    ln=floor(audio_length/W);
                else
                    ln=floor(((audio_length-W)/H)+1);
                end
                tin=0;%starting time of window
                tout=W;%ending time of window

                for k=1:ln,
%%%%%Calculate descriptors
                    
                    a=miraudio(File,'Extract',tin,tout);
                    mirsave(a,'temp/new.au');
                    clear a;
                
                    %m=mean
                    %d=standar deviation
                    %l=slope
                    %h=entropy

                    %%%Dynamics descriptors%%%
                    %RMS energy
                    Em=mirgetdata(mirrms('temp/new.au'));%Mean RMS
                    Eframe=mirgetdata(mirrms('temp/new.au','Frame'));%RMS frame based 50ms ovelap 50%
                    Ed=std(Eframe);%RMS standar deviation
                    El=rms_sig(diff(Eframe));%RMS slope (is this...? ASK!)
                    %Low-energy ratio
                    LEm=mirgetdata(mirlowenergy('temp/new.au'));
                    %Attack time
                    ATm=mean(mirgetdata(mirattacktime('temp/new.au')));
                    %Attack slope
                    Asm=mean(mirgetdata(mirattackslope('temp/new.au')));
                    Asd=std(mirgetdata(mirattackslope('temp/new.au')));
                
                    %%%Rhythm descriptors%%%
                    %Event density
                    EDm=mirgetdata(mireventdensity('temp/new.au'));
                    %Fluctuation peak (pos, mag)
                    Fl=mirfluctuation('temp/new.au','summary');%caculate fluctuation
                    peak=mirpeaks(Fl,'Total',1);%get peak
                    FP=get(peak,'PeakPos');%calculate peak position
                    FM=get(peak,'PeakVal');%calculate peak value
                    FPm=FP{1,1}{1,1}{1,1};%extract value from structure (normalized by length of sample...?)
                    FMm=FM{1,1}{1,1}{1,1};
                    %Fluctuation centroid
                    FCm=mirgetdata(mircentroid(Fl));
                    %Tempo
                    T=mirgetdata(mirtempo('temp/new.au','Frame'));%w=3sec, h=1sec
                    Tm=mean(T);%Mean
                    Td=std(T);%Std
                    %Pulse Clearity
                    PC=mirgetdata(mirpulseclarity('temp/new.au','Frame'));%w=5sec, h=10%
                    PCm=mean(PC);
                    PCd=std(PC);
                
                    %%%Pitch descriptors%%%
                    %Pitch
                    P=mirgetdata(mirpitch('temp/new.au','Frame','Total',1));%W=46.4ms h=10ms
                    P(isnan(P))=[];
                    Pm=mean(P);
                    Pd=std(P);
                    %chromagram
                    Ch=mirgetdata(mirchromagram('temp/new.au','Wrap',0,'Center'));%W=46.4ms h=10ms
                    Cm=mean(Ch);
                    Cd=std(Ch);
                    Cl=rms_sig(diff(Ch));
                    Chh =entropy(Ch);
                    %%%Harmonic descriptors%%%
                    %Key clarity
                    KC=mirgetdata(mirkeystrength('temp/new.au','Frame'));%(ordinate(s))See manual pg125
                    KCm=mean(max(KC(:,:,1,1)));
                    KCd=std(max(KC(:,:,1,1)));
                    %Key mode (Mayorness)
                    M=mirgetdata(mirmode('temp/new.au','Frame'));%(ordinate(s))See manual pg125
                    Mm=mean(M);
                    Md=std(M);
                    %HCDF
                    Hm=mean(mirgetdata(mirhcdf('temp/new.au')));
                    %Entropy
                    ESm=(mirgetdata(mirentropy('temp/new.au')));
                    %Rougness
                    Rm=mean(mirgetdata(mirroughness('temp/new.au','Frame')));
                    %Inharmonicity
                    f=mirframe('temp/new.au','Length',2,'s','Hop',50,'%');
                    I=mirgetdata(mirinharmonicity(f));
                    Im=mean(I);
                    Id=std(I);
                    %%%Timbre descriptors%%%
                    %Brightness
                    B=mirgetdata(mirbrightness('temp/new.au','Frame','CutOff',110));
                    Bm=mean(B);
                    Bd=std(B);
                    %Centroid
                    SC=mirgetdata(mircentroid('temp/new.au','Frame'));
                    SCm=mean(SC);
                    SCd=std(SC);
                    %zerocross rate
                    Z=mirgetdata(mirzerocross('temp/new.au','Frame'));
                    Zm=mean(Z);
                    Zd=std(Z);
                    %spread
                    Sm=mirgetdata(mirspread('temp/new.au'));
                    %Skewness
                    Km=mirgetdata(mirskewness('temp/new.au'));
                    %Spectral entropy
                    SE=mirgetdata(mirentropy('temp/new.au','Frame'));
                    SEm=mean(SE);
                    SEd=std(SE);
                    %spectral flux
                    Sfm=mean(mirgetdata(mirflux('temp/new.au')));
                    %Flatness
                    Fm=mirgetdata(mirflatness('temp/new.au'));
                    %Regularity
                    Re=mirgetdata(mirregularity('temp/new.au','Frame'));
                    REm=mean(Re);
                    REd=std(Re);
                    %MFCC
                    M=mirgetdata(mirmfcc('temp/new.au','Frame'));
                    D=mirgetdata(mirmfcc('temp/new.au','Frame','Delta'));
                    M1m=mean(M(1,:));
                    M2m=mean(M(2,:));
                    M3m=mean(M(3,:));
                    M4m=mean(M(4,:));
                    M5m=mean(M(5,:));
                    M6m=mean(M(6,:));
                    M7m=mean(M(7,:));
                    D1m=mean(D(1,:));
                    D2m=mean(D(2,:));
                    D3m=mean(D(3,:));
                    D4m=mean(D(4,:));
                    D5m=mean(D(5,:));
                    D6m=mean(D(6,:));
                    D7m=mean(D(7,:));
                    %%%Structure Descriptors
                    %Repetition spectrum
                    RS=mirgetdata(mirnovelty(mirspectrum('temp/new.au','Frame',.1,.5,'Max',5000),'Normal',0));
                    RS(isnan(RS))=0;
                    RSm=mean(RS);
                    RSd=std(RS);
                    %Repetition rhythm
                    RR=mirgetdata(mirnovelty(mirautocor('temp/new.au','Frame',.2,.5),'Normal',0));
                    RR(isnan(RR))=0;
                    RRm=mean(RR);
                    RRd=std(RR);
                    %Repetition tonality...?
                    RT=mirgetdata(mirnovelty(mirchromagram('temp/new.au','Frame',.2,.25),'Normal',0));
                    RT(isnan(RT))=0;
                    RTm=mean(RT);
                    RTd=std(RT);
                    %Repetition register....?
                    RG = mirgetdata(mirnovelty(mirchromagram('temp/new.au','Frame',.2,.25,'Wrap',0),'Normal',0)); 
                    RG(isnan(RG))=0;
                    RGm=mean(RG);
                    RGd=std(RG);
                
                    %%%%print into a file a line: File name, descriptors, class)
                    fprintf(fileID,formatSpec,songs(j,1).name,tin,tout,Em,Ed,El,LEm,ATm,Asm,Asd,EDm,FPm,FMm,FCm,Tm,Td,PCm,PCd,Pm,Pd,Cm,Cd,Cl,Ch,KCm,KCd,Mm,Md,Hm,ESm,Rm,Im,Id,Bm,Bd,SCm,SCd,Zm,Zd,Sm,Km,SEm,SEd,Sfm,Fm,REm,REd,M1m,D1m,M2m,D2m,M3m,D3m,M4m,D4m,M5m,D5m,M6m,D6m,M7m,D7m,RSm,RSd,RRm,RRd,RTm,RTd,RGm,RGd,class(i,1).name);
        
                    %Advance tin and tout
                    tin=tin+W-H;
                    tout=tin+W;
                end
            end
            %%%clear memory
            clear d*
        end
    end
 %perc=round(i*100/class_len);
 %waitbar((i/class_len),h,sprintf('Calculating descriptors for data set...%d%% ',perc))    
    
end
%%%%close file
fclose(fileID);