clear all 
clc
%PROYECTO REACTORES

%PFR CON TRANSFERENCIA DE CALOR 

%Reacciones:
% A -k1-> B -k2-> C -k3-> D 
% E -ka-> F

%A: HEMICELULOSA
%B: OLIGO XILOSAS
%C: XILOSA (MONÓMERO)
%D: FURFURAL
%E: ACETIL
%F: AC. ACÉTICO
%G: CELULOSA (INERTE NO.1)
%L: LIGNINA (INERTE NO.2)
%I: INERTES 
%W: AGUA

%ORDEN DE REACCIÓN: 1 (PSEUDO-PRIMER ORDEN RESPECTO AL AGUA)


%Resolución de ED con método ODE23s

%VALORES INICIALES
T0 = 100 + 273.15; %Temperatura de referencia [K]
TA =  140 + 273.15; %Temperatura de intercambiador de calor [K]
C_A0 = 25000*1.25; %Concentración inicial de Hemicelulosa [g/m3]
C_B0 = 0; %Concentración inicial de Oligo Xilosa [g/m3]
C_C0 = 0; %Concentración inicial de Xilosa [g/m3]
C_D0 = 0; %Concentración inicial de furfurales [g/m3]
C_E0 = C_A0/10; %Concentración inicial de acetiles [g/m3]. Este valor se obtuvo de %w/w de paja de trigo. 
C_F0 = 6.0052*(1e-3); %Concentración inicial de ácido [g/m3]. Este valor equivale a un pH 7 en [g/m3].
a = C_F0; %Concentración inicial de ácido [g/m3]
%F o a son pH, inicia en 1x10-7 mol/L e irá aumentando con rxn 


y0 = [C_A0, C_B0, C_C0, C_D0, C_E0,C_F0, T0, TA]; %Condiciones iniciales de conversión y de Temperatura 

V = 0:0.0005:2;
%Rango de volumen para evaluar concentración

%SOLUCIÓN DE ECUACIONES DIFERENCIALES
[Vol,Val]=ode23s(@PFR,V,y0);


%GRAFICAS DEL SISTEMA
%GRÁFICA 1: CAMBIOS EN LA CONCENTRACIÓN DE XILOSA Y FURFURAL MODIFICANDO
%VOLUMEN DE REACTOR
figure()
plot(Vol,Val(:,1),"r",Vol,Val(:,2),"b",Vol,Val(:,3),"g",Vol,Val(:,4),"c",Vol,Val(:,5),"y",Vol,Val(:,6)); 
%title("Cambios en concentración de Xilosa (C) y Furfural (D) variando el volumen del reactor")
xlabel('Volumen del reactor [m3]');
ylabel('Concentración [g/m3]');
legend("(A)","(B)","(C)","(D)","(E)","(F)");
 
figure()
plot(Vol,Val(:,7),"r",Vol,Val(:,8),"b")
xlabel('Volumen del reactor [m3]');
ylabel('Temperatura [K]');
legend("Temperatura de sistema","Temperatura de I.C.")

function dy=PFR(V,y)

CA = y(1);
CB = y(2);
CC = y(3);
CD = y(4);
CE = y(5);
CF = y(6);
T = y(7);
TA = y(8);
%Valores iniciales de Temperatura y Concentración de Xilosa


%a_inf = 600.52; % [g/m3]. pH 2, valor de a infinito. 


%PESOS MOLECULARES
PM_C = 150.13; %Peso molecular Xilosa [g/mol]
PM_D = 96.08; %Peso molecular Furfural [g/mol]
PM_E = 44.05; %Peso molecular Acetil [g/mol]
PM_F = 60.052; %Peso molecular Ac. Acético [g/mol]

%Valores energéticos
P = [1.93*(1e15), 4.3*(1e21), 4.5*(1e29),1.89*(1e4)]; %Factor Pre-Exponencial [1/min]
Ea = 1000*[-104,-156.1,-232.5,-58]; %Energía de Activación [J/mol]
R = 8.3145; %Constante de gases [J/mol*K]

%Cp's de componentes
%Valores de Cp con T cte
Cp_A = 1.1198; %[J/g*K]
Cp_B = Cp_A; %[J/g*K]

%Valores de Cp que varían con T,  [J/Kg*K]
%Filas: Cp_C0, Cp_D0, Cp_E0, Cp_F0.
Cp_0 = [109548, 319996, -1150.67, 208777, 520.941; 65056.39, 183957, 1421.119, 145585.2, 673.0352; 35973.82, 113451.6, 1183.685, 42700.16, 409.3988; 39924.63, 135839.5, 1208.064, 64252.96, 542.473];

Cp_C = (Cp_0(1,1) + Cp_0(1,2)*((Cp_0(1,3)/T)/(sinh(Cp_0(1,3)/T)))^2 + Cp_0(1,4)*((Cp_0(1,5)/T)/(cosh(Cp_0(1,5)/T)))^2)/(PM_C*1000);
Cp_D = (Cp_0(2,1) + Cp_0(2,2)*((Cp_0(2,3)/T)/(sinh(Cp_0(2,3)/T)))^2 + Cp_0(2,4)*((Cp_0(2,5)/T)/(cosh(Cp_0(2,5)/T)))^2)/(PM_D*1000);
Cp_E = (Cp_0(3,1) + Cp_0(3,2)*((Cp_0(3,3)/T)/(sinh(Cp_0(3,3)/T)))^2 + Cp_0(3,4)*((Cp_0(3,5)/T)/(cosh(Cp_0(3,5)/T)))^2)/(PM_E*1000);
Cp_F = (Cp_0(4,1) + Cp_0(4,2)*((Cp_0(4,3)/T)/(sinh(Cp_0(4,3)/T)))^2 + Cp_0(4,4)*((Cp_0(4,5)/T)/(cosh(Cp_0(4,5)/T)))^2)/(PM_F*1000);

%Calor específico de Inertes
Cp_G = 1.2981; %[J/g*K]
Cp_L = 1.3881; %[J/g*K]

%Calor específico de Fluído de intercambio (Agua)
Cp_W = 4.300; %[J/g*K]

%Delta de Entalpía de reacción [J/g]
%Columnas: dH_rxn 1,dH_rxn 2, dH_rxn 3, dH_rxn 4.
dH_rxn = [2.4*1000, 2.406*1000, 0.02289*1000, 0.39028*1000]; % [J/g] SAM CONVIRTIÓ DE J/mol a J/g para tener dimensiones correspondientes


%CONCENTRACIONES
C_A0 = 25000; %Concentración inicial de Hemicelulosa [g/m3]


%DENSIDADES
D_A = 1.52*100^3; % Densidad Xilosa [g/m3]
D_W = 998*1000; %Densidad Agua [g/m3]

%FLUJOS
F = 0.01*0.75; %Flujo volumétrico del sistema [m3/min]
F_A0 = F*C_A0; %Flujo inicial de Hemicelulosa [g/min]
F_G = 1.4*F_A0; %Flujo de Celulosa [g/min] 
F_L = 1.6*F_A0; %Flujo de de Lignina [g/min]
F_W = (F-(F_A0/D_A))*D_W; %Flujo másico de Agua [g/min]

M_fi = 1000*1000; %Flujo másico del fluído de intercambio [g/min]

%Valores PFR
D = 4*0.0254; %Diámetro de PFR [m]
A = 4/D; %área específica para tubería [1/m]
U = 60000; %[J/min*m2*K]


%Ecuaciones Diferenciales 

ka = P(4)*exp((Ea(4)/(R*T)));% Obtención de k4 de Arrhenius [1/min]
da = (ka*CE); %[(g/m3)/min)]


k1 = P(1)*da*exp((Ea(1)/(R*T)));% Obtención de k1 de Arrhenius [1/min]
k2 = P(2)*da*exp((Ea(2)/(R*T)));% Obtención de k2 de Arrhenius [1/min]
k3 = P(3)*da*exp((Ea(3)/(R*T)));% Obtención de k3 de Arrhenius [1/min]

%Balance de materia
%dCa/dt = Ra ; Ra = velocidad de reaccion

dCA = -k1*CA; %[(g/m3)/min)]
dCB = (k1*CA - k2*CB); %[(g/m3)/min)]
dCC = (k2*CB - k3*CC); %[(g/m3)/min)]
dCD = (k3*CC); %[(g/m3)/min]
dCE = -ka*CE; %[(g/m3)/min]


%Balance de energía
%dT/dV = (U*a*(To-T) + Q_rxn)/(Cp_sis)
Q_rxn = -k1*CA*dH_rxn(1) + (k1*CA - k2*CB)*dH_rxn(2) + (k2*CB - k3*CC)*dH_rxn(3) -ka*CE*dH_rxn(4);%[J/min*m3]
Cp_sis = dCA*F*Cp_A + dCB*F*Cp_B + dCC*F*Cp_C + dCD*F*Cp_D + dCE*F*Cp_E + da*F*Cp_F + F_G*Cp_G + F_L*Cp_L + F_W*Cp_W; %[J/K*min^2] 

dT = (U*A*(TA-T) + Q_rxn)/(Cp_sis); % K/m3
dTa = U*A*(T-TA)/(M_fi*Cp_W); % K/m3

dy = [dCA;dCB;dCC;dCD;dCE;da;dT;dTa];
end