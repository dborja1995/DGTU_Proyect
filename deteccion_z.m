%% PASO 3: DETECCIÓN DE ANOMALÍAS CON Z-SCORE
% Comparación: Método de umbrales vs. Método estadístico (Z-score)
% Sistema de Monitoreo IoT + Edge Computing

clear; clc; close all;

%% Parámetros de simulación (mismos que en Paso 2)
t_total = 300;              
dt = 0.1;                   
dt_temp = 1;                
t = 0:dt:t_total;           
t_temp = 0:dt_temp:t_total; 

I_nom = 5.0;    
T_nom = 45.0;   

I_max = 1.5 * I_nom;        % 7.5 A
I_alerta = I_nom * 1.20;    % 6.0 A
T_crit = 85.0;              
T_alerta = 65.0;            

%% Generar datos (igual que en Paso 2)
fase_I = 1:round(30/dt);
I_faseI = I_nom * 1.06 - 0.002 * t(fase_I) + 0.05 * randn(size(fase_I));

fase_II = (fase_I(end)+1):round(230/dt);
I_faseII = I_nom + 0.08 * randn(size(fase_II));

fase_III = (fase_II(end)+1):length(t);
I_faseIII = I_nom + 0.018 * (t(fase_III) - 230) + 0.1 * randn(size(fase_III));

I_total = [I_faseI, I_faseII, I_faseIII];

T_total = T_nom + 1.5 * randn(size(t_temp));
falla_inicio = find(t_temp > 250, 1);
if ~isempty(falla_inicio)
    T_total(falla_inicio:end) = T_total(falla_inicio:end) + 1.2 * (t_temp(falla_inicio:end) - 250);
end

%% === CALCULAR Z-SCORE PARA CORRIENTE ===
% Usar Fase II (operación normal) como referencia
% μ = media de la corriente en Fase II
% σ = desviación estándar de la corriente en Fase II

mu_I = mean(I_faseII);      % Media de referencia
sigma_I = std(I_faseII);    % Desviación estándar de referencia

% Calcular Z-score para toda la señal
Z_I = (I_total - mu_I) / sigma_I;

% Umbral de Z-score: |Z| > 3 indica anomalía
Z_umbral = 3;

%% === DETECCIÓN POR Z-SCORE ===
% Z-score detecta anomalía cuando |Z| > 3

estado_Z = zeros(size(I_total));

for k = 1:length(I_total)
    if abs(Z_I(k)) > Z_umbral
        estado_Z(k) = 1;  % Anomalía detectada por Z-score
    end
end

% Encontrar primer momento de detección por Z-score
idx_Z_detect = find(abs(Z_I) > Z_umbral, 1);

%% === DETECCIÓN POR UMBRALES (para comparar) ===
estado_umbral = zeros(size(I_total));

for k = 1:length(I_total)
    if I_total(k) > I_max || I_total(k) < 0.1*I_nom
        estado_umbral(k) = 2;  % Alarma
    elseif I_total(k) > I_alerta
        estado_umbral(k) = 1;  % Alerta
    end
end

idx_umbral_alerta = find(I_total > I_alerta, 1);
idx_umbral_alarma = find(I_total > I_max, 1);

%% === FIGURA 1: COMPARACIÓN DE MÉTODOS - CORRIENTE ===
figure('Name', 'Comparación: Umbrales vs Z-score', 'NumberTitle', 'off');

% Subplot 1: Corriente con umbrales
subplot(3,1,1);
plot(t, I_total, 'b', 'LineWidth', 1.2); hold on;
yline(I_max, 'r--', 'I_{max} = 7.5 A', 'LineWidth', 1);
yline(I_alerta, 'y--', 'I_{alerta} = 6.0 A', 'LineWidth', 1);
yline(mu_I, 'g--', ['\mu = ', num2str(mu_I, '%.1f'), ' A'], 'LineWidth', 0.8);

% Marcar detección por umbrales
if ~isempty(idx_umbral_alerta)
    xline(t(idx_umbral_alerta), 'y--', ['Alerta: ', num2str(t(idx_umbral_alerta), '%.1f'), ' min'], 'LineWidth', 1);
end
if ~isempty(idx_umbral_alarma)
    xline(t(idx_umbral_alarma), 'r--', ['Alarma: ', num2str(t(idx_umbral_alarma), '%.1f'), ' min'], 'LineWidth', 1);
end

xlabel('Tiempo (minutos)');
ylabel('Corriente (A)');
title('Detección por método de umbrales');
legend('Corriente', 'I_{max}', 'I_{alerta}', '\mu', 'Location', 'best');
grid on;

% Subplot 2: Z-score
subplot(3,1,2);
plot(t, Z_I, 'k', 'LineWidth', 1.2); hold on;
yline(Z_umbral, 'r--', ['Z = +', num2str(Z_umbral)], 'LineWidth', 1.2);
yline(-Z_umbral, 'r--', ['Z = -', num2str(Z_umbral)], 'LineWidth', 1.2);
yline(0, 'g--', 'Z = 0', 'LineWidth', 0.5);

% Marcar zona anómala
zona_anomala = abs(Z_I) > Z_umbral;
if any(zona_anomala)
    plot(t(zona_anomala), Z_I(zona_anomala), 'r.', 'MarkerSize', 2);
end

% Marcar primer punto de detección por Z-score
if ~isempty(idx_Z_detect)
    xline(t(idx_Z_detect), 'm--', ['Z-score: ', num2str(t(idx_Z_detect), '%.1f'), ' min'], 'LineWidth', 1.5);
end

xlabel('Tiempo (minutos)');
ylabel('Z-score');
title('Detección por Z-score (|Z| > 3 = anomalía)');
legend('Z-score', 'Umbral +3', 'Umbral -3', 'Z = 0', 'Anomalía', 'Location', 'best');
grid on;

% Subplot 3: Comparación de estados
subplot(3,1,3);
stairs(t, estado_Z*2, 'm', 'LineWidth', 1.5); hold on;
stairs(t, estado_umbral, 'b', 'LineWidth', 1.5);
xlabel('Tiempo (minutos)');
ylabel('Estado');
title('Comparación de métodos de detección');
ylim([-0.2, 2.5]);
yticks([0, 1, 2]);
yticklabels({'Normal (0)', 'Alerta (1)', 'Alarma (2)'});
legend('Z-score (anomalía)', 'Umbrales', 'Location', 'best');
grid on;

%% === FIGURA 2: Z-SCORE PARA TEMPERATURA ===
figure('Name', 'Z-score de Temperatura', 'NumberTitle', 'off');

% Calcular Z-score para temperatura
mu_T = mean(T_total(1:round(length(T_total)*0.7)));  % Referencia: primeros 70%
sigma_T = std(T_total(1:round(length(T_total)*0.7)));
Z_T = (T_total - mu_T) / sigma_T;

idx_Z_temp = find(abs(Z_T) > Z_umbral, 1);

subplot(2,1,1);
plot(t_temp, T_total, 'Color', [0.85, 0.33, 0.1], 'LineWidth', 1.5); hold on;
yline(T_crit, 'r--', 'T_{crit} = 85°C', 'LineWidth', 1);
yline(T_alerta, 'y--', 'T_{alerta} = 65°C', 'LineWidth', 1);
if ~isempty(idx_Z_temp)
    xline(t_temp(idx_Z_temp), 'm--', ['Z-score: ', num2str(t_temp(idx_Z_temp), '%.1f'), ' min'], 'LineWidth', 1.5);
end
xlabel('Tiempo (min)'); ylabel('Temperatura (°C)');
title('Temperatura con detección Z-score');
legend('T', 'T_{crit}', 'T_{alerta}', 'Z-score', 'Location', 'best');
grid on;

subplot(2,1,2);
plot(t_temp, Z_T, 'k', 'LineWidth', 1.2); hold on;
yline(Z_umbral, 'r--', ['Z = +', num2str(Z_umbral)], 'LineWidth', 1);
yline(-Z_umbral, 'r--', ['Z = -', num2str(Z_umbral)], 'LineWidth', 1);
zona_anomala_T = abs(Z_T) > Z_umbral;
if any(zona_anomala_T)
    plot(t_temp(zona_anomala_T), Z_T(zona_anomala_T), 'r.', 'MarkerSize', 2);
end
xlabel('Tiempo (min)'); ylabel('Z-score');
title('Z-score de temperatura');
legend('Z-score', 'Umbral +3', 'Umbral -3', 'Anomalía', 'Location', 'best');
grid on;

%% === REPORTE COMPARATIVO ===
fprintf('\n');
fprintf('╔══════════════════════════════════════════╗\n');
fprintf('║   COMPARACIÓN: UMBRALES vs Z-SCORE       ║\n');
fprintf('╚══════════════════════════════════════════╝\n');

fprintf('\n📊 PARÁMETROS DE REFERENCIA (Fase II):\n');
fprintf('   Corriente:  μ = %.3f A,  σ = %.3f A\n', mu_I, sigma_I);
fprintf('   Temperatura: μ = %.1f °C,  σ = %.1f °C\n', mu_T, sigma_T);

fprintf('\n🔍 DETECCIÓN DE ANOMALÍAS:\n');
fprintf('   Método de UMBRALES:\n');
if ~isempty(idx_umbral_alerta)
    fprintf('     ⚠️  Alerta:  t = %.1f min\n', t(idx_umbral_alerta));
end
if ~isempty(idx_umbral_alarma)
    fprintf('     🚨 Alarma:  t = %.1f min\n', t(idx_umbral_alarma));
end

fprintf('   Método Z-SCORE:\n');
if ~isempty(idx_Z_detect)
    fprintf('     🔍 Anomalía detectada: t = %.1f min\n', t(idx_Z_detect));
    if ~isempty(idx_umbral_alerta)
        adelanto = t(idx_umbral_alerta) - t(idx_Z_detect);
        fprintf('     ⏱️  Adelanto respecto a alerta por umbral: %.1f min\n', adelanto);
    end
    if ~isempty(idx_umbral_alarma)
        adelanto2 = t(idx_umbral_alarma) - t(idx_Z_detect);
        fprintf('     ⏱️  Adelanto respecto a alarma por umbral: %.1f min\n', adelanto2);
    end
end

if ~isempty(idx_Z_temp)
    fprintf('   Temperatura:\n');
    fprintf('     🔍 Anomalía Z-score: t = %.1f min\n', t_temp(idx_Z_temp));
    fprintf('     ⚠️  Alerta por umbral: t = %.1f min\n', t_temp(find(T_total > T_alerta, 1)));
    fprintf('     🚨 Alarma por umbral: t = %.1f min\n', t_temp(find(T_total > T_crit, 1)));
end

fprintf('\n══════════════════════════════════════════\n');
disp('✅ Comparación completada exitosamente.');