%% PASO 4 - ENVÍO DE DATOS A THINGSPEAK

% DATOS DEL THINGSPEAK
CHANNEL_ID = 3392897;          
WRITE_API_KEY = '6YNJSVUKZLH0SCJR';

fprintf('Iniciando sincronización con la nube ThingSpeak...\n');

% Puntos a enviar:
% 1. Muestra de la Fase I (arranque)
% 2. Muestra de la Fase II (normal)
% 3. TODOS los puntos donde el estado NO es 0 (alertas y alarmas)
% 4. Puntos cercanos a los cambios de estado

indices_a_enviar = [];

% Incluir algunas muestras de cada fase
indices_a_enviar = [indices_a_enviar, 1:500:length(I_total)];

% Incluir TODOS los puntos con estado 1 o 2
indices_criticos = find(estado >= 1);
indices_a_enviar = [indices_a_enviar, indices_criticos];

% Ordenar y eliminar duplicados
indices_a_enviar = unique(sort(indices_a_enviar));

fprintf('Se enviarán %d puntos a ThingSpeak...\n', length(indices_a_enviar));
fprintf('De los cuales %d son ALERTAS y %d son ALARMAS\n', ...
    sum(estado(indices_a_enviar) == 1), sum(estado(indices_a_enviar) == 2));

puntos_enviados = 0;

for i = 1:length(indices_a_enviar)
    k = indices_a_enviar(i);
    
    % Leer datos del "vuelo"
    voltaje_actual = V_total(k);
    corriente_actual = I_total(k);
    tiempo_actual = t(k);
    
    % Temperatura correspondiente
    [~, idx_temp] = min(abs(t_temp - tiempo_actual));
    temp_actual = T_total(min(idx_temp, length(T_total)));
    
    % Usar el estado ya calculado
    estado_actual = estado(k);
    
    % Mostrar en consola los estados importantes
    if estado_actual >= 1
        fprintf('   📡 t=%.1f min | Estado=%d | I=%.2f A | T=%.1f°C\n', ...
            tiempo_actual, estado_actual, corriente_actual, temp_actual);
    end
    
    % Transmitir a la nube
    try
        thingSpeakWrite(CHANNEL_ID, ...
            [voltaje_actual, corriente_actual, temp_actual, estado_actual], ...
            'WriteKey', WRITE_API_KEY);
        puntos_enviados = puntos_enviados + 1;
    catch ME
        warning('Error al enviar dato en t=%.1f min: %s', tiempo_actual, ME.message);
    end
    
    pause(0.15);
end

fprintf('\n========================================\n');
fprintf('✅ Sincronización completada.\n');
fprintf('   Total enviado: %d puntos\n', puntos_enviados);
fprintf('   De los cuales:\n');
fprintf('     - Normal (0): %d\n', sum(estado(indices_a_enviar) == 0));
fprintf('     - Alerta (1): %d\n', sum(estado(indices_a_enviar) == 1));
fprintf('     - Alarma (2): %d\n', sum(estado(indices_a_enviar) == 2));
fprintf('📊 Visualiza: https://thingspeak.com/channels/%d\n', CHANNEL_ID);
fprintf('========================================\n');