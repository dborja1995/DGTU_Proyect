%% PASO 2 (VERSIÓN FINAL CORREGIDA): DETECCIÓN DE FALLAS POR MÉTODO DE UMBRALES
% Sistema de Monitoreo IoT + Edge Computing
% Algoritmo: Rule-Based Detection (Пороговый метод)
% Estado: 0 = Normal, 1 = Alerta (degradación de corriente), 2 = Alarma (crítico)

clear; clc; close all;

%% Parámetros de simulación
t_total = 300;              
dt = 0.1;                   
dt_temp = 1;                
t = 0:dt:t_total;           
t_temp = 0:dt_temp:t_total; 

I_nom = 5.0;    
V_nom = 28.0;   
T_nom = 45.0;   

I_max = 1.5 * I_nom;    
I_min = 0.1 * I_nom;    
T_crit = 85.0;          

% Umbral de alerta para corriente: 20% por encima del valor nominal
I_alerta = I_nom * 1.20;  % 6.0 A

% Umbrales de temperatura
T_alerta = 65.0;           % Umbral de alerta térmica
T_crit = 85.0;             % Umbral de alarma térmica (crítico)

%% Generar datos de corriente (tres fases de la curva de bañera)
fase_I = 1:round(30/dt);
I_faseI = I_nom * 1.06 - 0.002 * t(fase_I) + 0.05 * randn(size(fase_I));

fase_II = (fase_I(end)+1):round(230/dt);
I_faseII = I_nom + 0.08 * randn(size(fase_II));

fase_III = (fase_II(end)+1):length(t);
I_faseIII = I_nom + 0.018 * (t(fase_III) - 230) + 0.1 * randn(size(fase_III));

I_total = [I_faseI, I_faseII, I_faseIII];
V_total = V_nom + 0.5 * randn(size(I_total));

%% Generar datos de temperatura (con falla térmica progresiva)
T_total = T_nom + 1.5 * randn(size(t_temp));
falla_inicio = find(t_temp > 250, 1);
if ~isempty(falla_inicio)
    T_total(falla_inicio:end) = T_total(falla_inicio:end) + 1.2 * (t_temp(falla_inicio:end) - 250);
end

%% === ALGORITMO DE DETECCIÓN POR UMBRALES ===
% Estado: 0 = Normal, 1 = Alerta (degradación temprana de corriente), 2 = Alarma (crítico)

estado = zeros(size(I_total));

for k = 1:length(I_total)
    % Buscar temperatura correspondiente
    [~, idx_temp] = min(abs(t_temp - t(k)));
    temp_actual = T_total(min(idx_temp, length(T_total)));
    
    % === VERIFICAR ALARMA PRIMERO (máxima prioridad) ===
    if I_total(k) > I_max || I_total(k) < I_min || temp_actual > T_crit
        estado(k) = 2;  % Alarma: falla crítica (eléctrica o térmica)
    
    % === VERIFICAR ALERTA (degradación temprana de corriente) ===
    elseif I_total(k) > I_alerta
        estado(k) = 1;  % Alerta: corriente elevada pero sin alcanzar umbral crítico
    
    % === NORMAL ===
    else
        estado(k) = 0;
    end
end

%% Encontrar momentos de detección
idx_alerta_corriente = find(I_total > I_alerta, 1);    % Primera alerta por corriente
idx_alarma_corriente = find(I_total > I_max, 1);       % Primera alarma por corriente
idx_alarma_temp = find(T_total > T_crit, 1);           % Primera alarma por temperatura
idx_alerta_temp = find(T_total > T_alerta, 1);         % Primera alerta por temperatura

%% === FIGURA 1: CORRIENTE + ESTADO ===
figure('Name', 'Detección de Fallas Eléctricas', 'NumberTitle', 'off');

% Subplot 1: Corriente con umbrales
subplot(2,1,1);
plot(t, I_total, 'b', 'LineWidth', 1.2); hold on;
yline(I_max, 'r--', 'I_{max} = 7.5 A (ALARMA)', 'LineWidth', 1.2);
yline(I_alerta, 'y--', 'I_{alerta} = 6.0 A (ALERTA)', 'LineWidth', 1.2);
yline(I_nom, 'g--', 'I_{nom} = 5 A', 'LineWidth', 0.8);

% Marcar puntos de ALERTA (estado 1)
puntos_alerta = estado == 1;
if any(puntos_alerta)
    plot(t(puntos_alerta), I_total(puntos_alerta), 'yo', 'MarkerSize', 4, 'MarkerFaceColor', 'y');
end

% Marcar puntos de ALARMA (estado 2)
puntos_alarma = estado == 2;
if any(puntos_alarma)
    plot(t(puntos_alarma), I_total(puntos_alarma), 'ro', 'MarkerSize', 6, 'LineWidth', 1.5);
end

xlabel('Tiempo (minutos)');
ylabel('Corriente (A)');
title('Detección de fallas eléctricas — Método de umbrales');
legend('Corriente', 'I_{max} (ALARMA)', 'I_{alerta} (ALERTA)', 'I_{nom}', ...
       'ALERTA', 'ALARMA', 'Location', 'best');
grid on;

% Subplot 2: Estado del sistema
subplot(2,1,2);
stairs(t, estado, 'LineWidth', 1.5);
xlabel('Tiempo (minutos)');
ylabel('Estado');
title('Estado del sistema — Monitoreo de corriente');
ylim([-0.2, 2.5]);
yticks([0, 1, 2]);
yticklabels({'Normal (0)', 'Alerta (1)', 'Alarma (2)'});
grid on;

%% === FIGURA 2: TEMPERATURA + ESTADO ===
figure('Name', 'Detección de Sobrecalentamiento', 'NumberTitle', 'off');

% Subplot 1: Temperatura con umbral
subplot(2,1,1);
plot(t_temp, T_total, 'Color', [0.85, 0.33, 0.1], 'LineWidth', 1.5); hold on;
yline(T_crit, 'r--', 'T_{crit} = 85°C (ALARMA)', 'LineWidth', 1.2);
yline(T_alerta, 'y--', 'T_{alerta} = 65°C (ALERTA)', 'LineWidth', 1.2);
yline(T_nom, 'g--', 'T_{nom} = 45°C', 'LineWidth', 0.8);

% Marcar ALERTA térmica
puntos_alerta_temp = T_total > T_alerta & T_total <= T_crit;
if any(puntos_alerta_temp)
    plot(t_temp(puntos_alerta_temp), T_total(puntos_alerta_temp), 'yo', ...
        'MarkerSize', 3, 'MarkerFaceColor', 'y');
end

% Marcar puntos de ALARMA por temperatura
puntos_temp = T_total > T_crit;
if any(puntos_temp)
    plot(t_temp(puntos_temp), T_total(puntos_temp), 'ro', 'MarkerSize', 5, 'LineWidth', 1.2);
end

% Marcar el primer punto de alarma con una X grande
if ~isempty(idx_alarma_temp)
    plot(t_temp(idx_alarma_temp), T_total(idx_alarma_temp), 'rx', ...
        'MarkerSize', 12, 'LineWidth', 2.5);
end

xlabel('Tiempo (minutos)');
ylabel('Temperatura (°C)');
title('Monitoreo de temperatura — Método de umbrales');
legend('Temperatura', 'T_{crit} (ALARMA)', 'T_{alerta} (ALERTA)', 'T_{nom}', ...
       'ALERTA', 'ALARMA', 'Location', 'best');
grid on;

subplot(2,1,2);
estado_temp_grafica = zeros(size(t_temp));
estado_temp_grafica(T_total > T_alerta & T_total <= T_crit) = 1;
estado_temp_grafica(T_total > T_crit) = 2;

stairs(t_temp, estado_temp_grafica, 'LineWidth', 1.5, 'Color', [0.85, 0.33, 0.1]);
xlabel('Tiempo (minutos)');
ylabel('Estado');
title('Estado del sistema — Temperatura');
ylim([-0.2, 2.5]);
yticks([0, 1, 2]);
yticklabels({'Normal (0)', 'Alerta (1)', 'Alarma (2)'});
grid on;

%% === FIGURA 3: PANEL COMPLETO DEL SISTEMA ===
figure('Name', 'Panel Completo del Sistema de Monitoreo', 'NumberTitle', 'off');

% Subplot 1: Corriente + umbrales
subplot(3,1,1);
plot(t, I_total, 'b', 'LineWidth', 1.2); hold on;
yline(I_max, 'r--', 'I_{max}', 'LineWidth', 1);
yline(I_alerta, 'y--', 'I_{alerta}', 'LineWidth', 1);
yline(I_nom, 'g--', 'I_{nom}', 'LineWidth', 0.8);

puntos_alarma = estado == 2;
puntos_alerta_corr = estado == 1;
if any(puntos_alarma)
    plot(t(puntos_alarma), I_total(puntos_alarma), 'ro', 'MarkerSize', 5);
end
if any(puntos_alerta_corr)
    plot(t(puntos_alerta_corr), I_total(puntos_alerta_corr), 'yo', 'MarkerSize', 4, 'MarkerFaceColor', 'y');
end

xlabel('Tiempo (min)'); ylabel('Corriente (A)');
title('Monitoreo de Corriente');
legend('I', 'I_{max}', 'I_{alerta}', 'I_{nom}', 'ALARMA', 'ALERTA', 'Location', 'best');
grid on;

% Subplot 2: Temperatura + umbral
subplot(3,1,2);
plot(t_temp, T_total, 'Color', [0.85, 0.33, 0.1], 'LineWidth', 1.2); hold on;
yline(T_crit, 'r--', 'T_{crit}', 'LineWidth', 1);
yline(T_alerta, 'y--', 'T_{alerta}', 'LineWidth', 1);
puntos_alarma_t = T_total > T_crit;
puntos_alerta_t = T_total > T_alerta & T_total <= T_crit;
if any(puntos_alarma_t)
    plot(t_temp(puntos_alarma_t), T_total(puntos_alarma_t), 'ro', 'MarkerSize', 4);
end
if any(puntos_alerta_t)
    plot(t_temp(puntos_alerta_t), T_total(puntos_alerta_t), 'yo', 'MarkerSize', 3, 'MarkerFaceColor', 'y');
end
xlabel('Tiempo (min)'); ylabel('Temperatura (°C)');
title('Temperatura');
legend('T', 'T_{crit}', 'T_{alerta}', 'ALARMA', 'ALERTA', 'Location', 'best');
grid on;

% Subplot 3: Estado combinado del sistema
subplot(3,1,3);
stairs(t, estado, 'LineWidth', 1.5);
xlabel('Tiempo (min)'); ylabel('Estado');
title('Estado del Sistema de Monitoreo');
ylim([-0.2, 2.5]);
yticks([0, 1, 2]);
yticklabels({'Normal (0)', 'Alerta (1)', 'Alarma (2)'});
grid on;

%% === REPORTE DE RESULTADOS ===
fprintf('\n========== REPORTE DE DETECCIÓN ==========\n');
fprintf('Tiempo total de simulación: %d minutos\n', t_total);
fprintf('\nUmbrales configurados:\n');
fprintf('  - I_nom    = %.1f A (Corriente nominal)\n', I_nom);
fprintf('  - I_alerta = %.1f A (Umbral de alerta, +20%%) → ALERTA\n', I_alerta);
fprintf('  - I_max    = %.1f A (Umbral de cortocircuito) → ALARMA\n', I_max);
fprintf('  - I_min    = %.1f A (Umbral de circuito abierto) → ALARMA\n', I_min);
fprintf('  - T_crit   = %.1f °C (Umbral de sobrecalentamiento) → ALARMA\n', T_crit);

if ~isempty(idx_alerta_corriente)
    fprintf('\n⚠️  ALERTA por corriente elevada: t = %.1f min (I = %.2f A)\n', ...
        t(idx_alerta_corriente), I_total(idx_alerta_corriente));
end

if ~isempty(idx_alarma_corriente)
    fprintf('🚨 ALARMA por cortocircuito: t = %.1f min (I = %.2f A)\n', ...
        t(idx_alarma_corriente), I_total(idx_alarma_corriente));
    if ~isempty(idx_alerta_corriente)
        ventana = t(idx_alarma_corriente) - t(idx_alerta_corriente);
        fprintf('   → Ventana de advertencia: %.1f min entre ALERTA y ALARMA\n', ventana);
    end
end

if ~isempty(idx_alarma_temp)
    fprintf('🚨 ALARMA por sobrecalentamiento: t = %.1f min (T = %.1f °C)\n', ...
        t_temp(idx_alarma_temp), T_total(idx_alarma_temp));
end

fprintf('\nDistribución de estados:\n');
fprintf('  NORMAL: %d puntos (%.1f%%)\n', sum(estado==0), 100*sum(estado==0)/length(estado));
fprintf('  ALERTA: %d puntos (%.1f%%)\n', sum(estado==1), 100*sum(estado==1)/length(estado));
fprintf('  ALARMA: %d puntos (%.1f%%)\n', sum(estado==2), 100*sum(estado==2)/length(estado));
fprintf('============================================\n');

disp('✅ Simulación completada exitosamente.');