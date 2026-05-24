%% PASO 1: SIMULACIÓN DE SENSORES DE LUZ DE ATERRIZAJE
% Sistema de Monitoreo IoT + Edge Computing
% Luz de aterrizaje - Parámetros nominales

clear; clc; close all;

%% Parámetros de simulación
t_total = 300;              % Tiempo total (minutos)
dt = 0.1;                   % Paso de tiempo para eléctricos (0.1 min = 6 seg)
dt_temp = 1;                % Paso para temperatura (1 min)
t = 0:dt:t_total;           % Vector de tiempo para eléctricos
t_temp = 0:dt_temp:t_total; % Vector de tiempo para temperatura

%% Parámetros nominales del LED de aterrizaje
I_nom = 5.0;    % Corriente nominal (A)
V_nom = 28.0;   % Voltaje nominal (V)
T_nom = 45.0;   % Temperatura normal (°C)

%% Umbrales para detección de fallas
I_max = 1.5 * I_nom;    % Umbral de cortocircuito (7.5 A)
I_min = 0.1 * I_nom;    % Umbral de circuito abierto (0.5 A)
T_crit = 85.0;          % Temperatura crítica (°C)

%% Generar datos simulados - Fase I: Arranque (0-30 min)
fase_I = 1:round(30/dt);
I_faseI = I_nom * 1.06 - 0.002 * t(fase_I) + 0.05 * randn(size(fase_I)); % Corriente alta que baja

%% Generar datos simulados - Fase II: Operación normal (30-230 min)
fase_II = (fase_I(end)+1):round(230/dt);
I_faseII = I_nom + 0.08 * randn(size(fase_II)); % Estable con ruido

%% Generar datos simulados - Fase III: Degradación (230-300 min)
fase_III = (fase_II(end)+1):length(t);
I_faseIII = I_nom + 0.018 * (t(fase_III) - 230) + 0.1 * randn(size(fase_III)); % Aumento gradual

%% Unir las tres fases
I_total = [I_faseI, I_faseII, I_faseIII];
V_total = V_nom + 0.5 * randn(size(I_total)); % Voltaje con ruido

% Temperatura (muestreada a 1 Hz)
T_total = T_nom + 1.5 * randn(size(t_temp));
% Inyectar sobrecalentamiento al final
falla_inicio = find(t_temp > 250, 1);
if ~isempty(falla_inicio)
    T_total(falla_inicio:end) = T_total(falla_inicio:end) + 1.2 * (t_temp(falla_inicio:end) - 250);
end

%% GRAFICAR: Curva de bañera (intensidad de fallos)
figure('Name', 'Curva de Intensidad de Fallos (Bañera)', 'NumberTitle', 'off');
plot(t, I_total, 'b', 'LineWidth', 1.5); hold on;
yline(I_nom, 'g--', 'I_{nom} = 5 A', 'LineWidth', 1);
yline(I_max, 'r--', 'I_{max} = 7.5 A (Alarma)', 'LineWidth', 1.2);
yline(I_min, 'm--', 'I_{min} = 0.5 A (Circuito abierto)', 'LineWidth', 1.2);
xline(30, 'k--', 'Fin Fase I');
xline(230, 'k--', 'Inicio Fase III');
xlabel('Tiempo (minutos)');
ylabel('Corriente (A)');
title('Curva de intensidad de fallos — Simulación de corriente');
legend('Corriente medida', 'I_{nom}', 'Umbral Alarma', 'Umbral Circuito Abierto', ...
       'Fin Fase I', 'Inicio Fase III', 'Location', 'best');
grid on;

%% GRAFICAR: Temperatura con umbral
figure('Name', 'Monitoreo de Temperatura', 'NumberTitle', 'off');
plot(t_temp, T_total, 'r', 'LineWidth', 1.5); hold on;
yline(T_crit, 'r--', 'T_{crit} = 85°C (Alarma)', 'LineWidth', 1.2);
xlabel('Tiempo (minutos)');
ylabel('Temperatura (°C)');
title('Monitoreo de temperatura — LED de aterrizaje');
legend('Temperatura medida', 'Umbral crítico', 'Location', 'best');
grid on;

disp('✅ Simulación completada. Revisa las gráficas generadas.');