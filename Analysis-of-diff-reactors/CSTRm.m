clear all 
clc
%PROYECTO REACTORES

%CSTR CON TRANSFERENCIA DE CALOR 

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
   
%se escoge una temperatura y se varia volumen para graficas xbm y xbc
%VALORES INICIALES

T = 140 + 273.15; %Temperatura de operación [K]
F = 1; %Flujo volumétrico del sistema [m3/min]
T0 = 100 + 273.15; %Temperatura de referencia [K]
TA =  180 + 273.15; %Temperatura de intercambiador de calor [K]
C_A0 = 25000*1.25; %Concentración inicial de Hemicelulosa [g/m3]
C_B0 = 0; %Concentración inicial de Oligo Xilosa [g/m3]
C_C0 = 0; %Concentración inicial de Xilosa [g/m3]
C_D0 = 0; %Concentración inicial de furfurales [g/m3]
C_E0 = C_A0/10; %Concentración inicial de acetiles [g/m3]. Este valor se obtuvo de %w/w de paja de trigo. 
C_F0 = 6.0052*(1e-3); %Concentración inicial de ácido [g/m3]. Este valor equivale a un pH 7 en [g/m3].
a = C_F0; %Concentración inicial de ácido [g/m3]
%F o a son pH, inicia en 1x10-7 mol/L e irá aumentando con rxn 



%SI SE DESEA CAMBIAR VOLUMEN, CAMBIAR RANGOS EN VARIABLE V Y VARIABLE VOL
V = 0:0.0005:.2;

%CREACIÓN DE MATRICES DE CONCENTRACIÓN CON VALORES 0
CA = zeros(size(V))';
CB = CA;
CC = CA;
CD = CA;
CE = CA;
CF = CA;
Q1=CA;
Q2=CA;
Q3=CA;
%CICLO DE ITERACIÓN
i = 1; %contador

%SI SE DESEA CAMBIAR VOLUMEN, CAMBIAR RANGOS EN VARIABLE V Y VARIABLE VOL
for Vol=0:0.0005:.2
    tao=Vol/F;

    %Valores de Cp que varían con T,  [J/Kg*K]
    %PESOS MOLECULARES
    PM_C = 150.13; %Peso molecular Xilosa [g/mol]
    PM_D = 96.08; %Peso molecular Furfural [g/mol]
    PM_E = 44.05; %Peso molecular Acetil [g/mol]
    PM_F = 60.052; %Peso molecular Ac. Acético [g/mol]
    %Filas: Cp_C0, Cp_D0, Cp_E0, Cp_F0.
    Cp_0 = [109548, 319996, -1150.67, 208777, 520.941; 65056.39, 183957, 1421.119, 145585.2, 673.0352; 35973.82, 113451.6, 1183.685, 42700.16, 409.3988; 39924.63, 135839.5, 1208.064, 64252.96, 542.473];
    %Cp's de componentes
    %Valores de Cp con T cte
    Cp_A = 1.1198; %[J/g*K]
    Cp_B = Cp_A; %[J/g*K]
    Cp_C = (Cp_0(1,1) + Cp_0(1,2)*((Cp_0(1,3)/T)/(sinh(Cp_0(1,3)/T)))^2 + Cp_0(1,4)*((Cp_0(1,5)/T)/(cosh(Cp_0(1,5)/T)))^2)/(PM_C*1000);
    Cp_D = (Cp_0(2,1) + Cp_0(2,2)*((Cp_0(2,3)/T)/(sinh(Cp_0(2,3)/T)))^2 + Cp_0(2,4)*((Cp_0(2,5)/T)/(cosh(Cp_0(2,5)/T)))^2)/(PM_D*1000);
    Cp_E = (Cp_0(3,1) + Cp_0(3,2)*((Cp_0(3,3)/T)/(sinh(Cp_0(3,3)/T)))^2 + Cp_0(3,4)*((Cp_0(3,5)/T)/(cosh(Cp_0(3,5)/T)))^2)/(PM_E*1000);
    Cp_F = (Cp_0(4,1) + Cp_0(4,2)*((Cp_0(4,3)/T)/(sinh(Cp_0(4,3)/T)))^2 + Cp_0(4,4)*((Cp_0(4,5)/T)/(cosh(Cp_0(4,5)/T)))^2)/(PM_F*1000);
    %Calor específico de Inertes
    Cp_G = 1.2981; %[J/g*K]
    Cp_L = 1.3881; %[J/g*K]
    %valores de k
    P = [1.93*(1e15), 4.3*(1e21), 4.5*(1e29),1.89*(1e4)]; %Factor Pre-Exponencial [1/min]
    Ea = 1000*[-104,-156.1,-232.5,-58]; %Energía de Activación [J/mol]
    R = 8.3145; %Constante de gases [J/mol*K]
    %delta de reaccion Hrxn
    dH_rxn = [2.4*1000, 2.406*1000, 0.02289*1000, 0.39028*1000];
    
    ka = P(4)*exp((Ea(4)/(R*T)));% Obtención de k4 de Arrhenius [1/min]
    CE(i,1) = C_E0/(1+tao*ka);
    CF(i,1) = C_F0+tao*(ka*CE(i,1)); %[(g/m3)/min)] a es F
   

    k1 = P(1)*CF(i,1)*exp((Ea(1)/(R*T)));% Obtención de k1 de Arrhenius [1/min]
    k2 = P(2)*CF(i,1)*exp((Ea(2)/(R*T)));% Obtención de k2 de Arrhenius [1/min]
    k3 = P(3)*CF(i,1)*exp((Ea(3)/(R*T)));% Obtención de k3 de Arrhenius [1/min]

    %ECUACIONES DE PRODUCTO
    %PRIMER CHESTER
    CA(i,1) = (C_A0/(1+tao*k1));
    CB(i,1) =(C_B0+tao*k1*CA(i,1))/(1+tao*k2);
    CC(i,1) =(C_C0+tao*k2*CB(i,1))/(1+tao*k3);
    CD(i,1) =C_D0+k3*tao*CC(i,1);
    
    dCA = -k1*CA(i,1); %[(g/m3)/min)]
    dCB = (k1*CA(i,1)- k2*CB(i,1)); %[(g/m3)/min)]
    dCC = (k2*CB(i,1) - k3*CC(i,1)); %[(g/m3)/min)]
    dCD = (k3*CC(i,1)); %[(g/m3)/min]
    dCE = -ka*CE(i,1); %[(g/m3)/min]
    
    Q1(i)=(Vol*CA(i,1)*Cp_A+Vol*CB(i,1)*Cp_B+Vol*CC(i,1)*Cp_C+Vol*CD(i,1)*Cp_D+Vol*CE(i,1)*Cp_E+Vol*CF(i,1)*Cp_F)*(T-T0)+Vol*((dCA*dH_rxn(1))+(dCA*dH_rxn(2))+(dCA*dH_rxn(3))+(dCA*dH_rxn(4)));
   
    %SEGUNDO CHESTER
    CE(i,2) = CE(i,1)/(1+tao*ka);
    CF(i,2) = CF(i,1)+tao*(ka*CE(i,2)); %[(g/m3)/min)] a es F
    
    k1 = P(1)*CF(i,2)*exp((Ea(1)/(R*T)));% Obtención de k1 de Arrhenius [1/min]
    k2 = P(2)*CF(i,2)*exp((Ea(2)/(R*T)));% Obtención de k2 de Arrhenius [1/min]
    k3 = P(3)*CF(i,2)*exp((Ea(3)/(R*T)));% Obtención de k3 de Arrhenius [1/min]

    
    CA(i,2) = (CA(i,1)/(1+tao*k1));
    CB(i,2) =(CB(i,1)+tao*k1*CA(i,2))/(1+tao*k2);
    CC(i,2) =(CC(i,1)+tao*k2*CB(i,2))/(1+tao*k3);
    CD(i,2) =CD(i,1)+k3*tao*CC(i,2);
    
    dCA = -k1*CA(i,2); %[(g/m3)/min)]
    dCB = (k1*CA(i,2) - k2*CB(i,2)); %[(g/m3)/min)]
    dCC = (k2*CB(i,2) - k3*CC(i,2)); %[(g/m3)/min)]
    dCD = (k3*CC(i,2)); %[(g/m3)/min]
    dCE = -ka*CE(i,2); %[(g/m3)/min]
    
    Q2(i)=(Vol*CA(i,2)*Cp_A+Vol*CB(i,2)*Cp_B+Vol*CC(i,2)*Cp_C+Vol*CD(i,2)*Cp_D+Vol*CE(i,2)*Cp_E+Vol*CF(i,2)*Cp_F)*(T-T0)+Vol*((dCA*dH_rxn(1))+(dCA*dH_rxn(2))+(dCA*dH_rxn(3))+(dCA*dH_rxn(4)));
    %TERCER CHESTER
    CE(i,3) = CE(i,2)/(1+tao*ka);
    CF(i,3) = CF(i,2)+tao*(ka*CE(i,3)); %[(g/m3)/min)] a es F
    
    k1 = P(1)*CF(i,3)*exp((Ea(1)/(R*T)));% Obtención de k1 de Arrhenius [1/min]
    k2 = P(2)*CF(i,3)*exp((Ea(2)/(R*T)));% Obtención de k2 de Arrhenius [1/min]
    k3 = P(3)*CF(i,3)*exp((Ea(3)/(R*T)));% Obtención de k3 de Arrhenius [1/min]

    
    CA(i,3) = (CA(i,2)/(1+tao*k1));
    CB(i,3) =(CB(i,2)+tao*k1*CA(i,3))/(1+tao*k2);
    CC(i,3) =(CC(i,2)+tao*k2*CB(i,3))/(1+tao*k3);
    CD(i,3) =CD(i,2)+k3*tao*CC(i,3);
    
    dCA = -k1*CA(i,3); %[(g/m3)/min)]
    dCB = (k1*CA(i,3) - k2*CB(i,3)); %[(g/m3)/min)]
    dCC = (k2*CB(i,3) - k3*CC(i,3)); %[(g/m3)/min)]
    dCD = (k3*CC(i,3)); %[(g/m3)/min]
    dCE = -ka*CE(i,3); %[(g/m3)/min]
    
    Q3(i)=(Vol*CA(i,3)*Cp_A+Vol*CB(i,3)*Cp_B+Vol*CC(i,3)*Cp_C+Vol*CD(i,3)*Cp_D+Vol*CE(i,3)*Cp_E+Vol*CF(i,3)*Cp_F)*(T-T0)+Vol*((dCA*dH_rxn(1))+(dCA*dH_rxn(2))+(dCA*dH_rxn(3))+(dCA*dH_rxn(4)));
    
    
    
    i = i + 1;
end
figure('Name','Primer CSTR','NumberTitle','off')
plot(V,CA(:,1),"r",V,CB(:,1),"b",V,CC(:,1),"c",V,CD(:,1),"m",V,CF(:,1),"g")
%title("Cambios en concentración de Xilanos( y Furfural (D) en PRIMER CSTR")
xlabel('Volumen del reactor [m3]');
ylabel('Concentración [g/m3]');
legend("(A)","(B)","(C)","(D)","(F)");

figure('Name','Segundo CSTR','NumberTitle','off')
plot(V,CA(:,2),"r",V,CB(:,2),"b",V,CC(:,2),"c",V,CD(:,2),"m",V,CF(:,2),"g")
%title("Cambios en concentración de Xilanos y Furfural (D) en SEGUNDO CSTR")
xlabel('Volumen del reactor [m3]');
ylabel('Concentración [g/m3]');
legend("(A)","(B)","(C)","(D)","(F)");

figure('Name','Tercer CSTR','NumberTitle','off')
plot(V,CA(:,3),"r",V,CB(:,3),"b",V,CC(:,3),"c",V,CD(:,3),"m",V,CF(:,3),"g")
%title("Cambios en concentración de Xilanos y Furfural (D) en TERCER CSTR")
xlabel('Volumen del reactor [m3]');
ylabel('Concentración [g/m3]');
legend("(A)","(B)","(C)","(D)","(F)");

%CÁLCULO DE RENDIMIENTO
%Deseamos maximizar el rendimiento de C debido a que esto representa la
%mayor solubilidad de la biomasa para ser fermentada posteriormente
%A es el Reactivo Limitante
%CC: concentración de C a la salida del reactor en [g/m3]
%CA: concentración de A a la salida del reactor en [g/m3]
%C_A0: concentración inicial de A en [g/m3]
%V: Volumen de reactor (Matriz hecha anteriormente) en [m3]

Y_global =  CC ./(C_A0 - CA); %División entre los valores de matrices CC y (C_A0 - CA)

figure('Name','Rendimiento Xilosa','NumberTitle','off')
plot(V,Y_global)
%title("Rendimiento de Xilosa en cada CSTR")
xlabel('Volumen del reactor [m3]');
ylabel('Rendimiento [-]');
legend("Primer CSTR","Segundo CSTR","Tercer CSTR");

%CÁLCULO DE SELECTIVIDAD
%Deseamos calcular la selectividad de Xilosa sobre Furfural mientras se
%cambia el volumen de los reactores, debido a que este último funciona como
%agente inhibidor de la fermentación

%S_cd: Selectividad de C contra D

S_cd = CC ./ CD; %CC representa nuestro producto deseado mientras que CD es el no deseado

figure('Name','Selectividad Xilosa','NumberTitle','off')
plot(CA,S_cd)
%title("Selectividad de Xilosa en cada CSTR")
xlabel('Volumen del reactor [m3]');
ylabel('Selectividad [-]');
legend("Primer CSTR","Segundo CSTR","Tercer CSTR");

figure("Name","Q para CSTR 1",'NumberTitle','off')
plot(V, -Q1)
%title("Calor necesario para mantener la temperatura de operación")
xlabel('Volumen del reactor [m3]');
ylabel("Energía [W]");

figure("Name","Q para CSTR 2",'NumberTitle','off')
plot(V, -Q2)
%title("Calor necesario para mantener la temperatura de operación")
xlabel('Volumen del reactor [m3]');
ylabel("Energía [W]");

figure("Name","Q para CSTR 3",'NumberTitle','off')
plot(V, -Q3)
%title("Selectividad de Xilosa en cada CSTR")
xlabel('Volumen del reactor [m3]');
ylabel("Energía [W]");
