%% GUARDAR DATOS LOCALMENTE (SIMULACIÓN DE MEMORIA EDGE)
% Ejecutar después del Paso 2 (deteccion_umbrales.m)
% Simula el almacenamiento en SPIFFS del ESP32 a bordo del avión
% Guarda archivos con fecha y hora para evitar sobrescritura

fprintf('\n💾 GUARDANDO DATOS EN MEMORIA LOCAL DEL EDGE CONTROLLER...\n');

% Generar marca de tiempo para nombres únicos
fecha_hora = datestr(now, 'yyyy-mm-dd_HH-MM-SS');

% Interpolar temperatura para que coincida con el vector de tiempo
T_total_interp = interp1(t_temp, T_total, t, 'linear')';

% Crear tabla con todos los datos del vuelo
datos_locales = table(t', I_total', V_total', T_total_interp, estado', ...
    'VariableNames', {'Tiempo_min', 'Corriente_A', 'Voltaje_V', 'Temperatura_C', 'Estado'});

% --- GUARDAR COMO CSV (simula archivo en SPIFFS del ESP32) ---
nombre_csv = ['datos_sensores_AV019_', fecha_hora, '.csv'];
writetable(datos_locales, nombre_csv);
fprintf('✅ Datos guardados en: %s\n', nombre_csv);

% --- GUARDAR COMO MAT (respaldo completo para análisis posterior) ---
nombre_mat = ['respaldo_completo_AV019_', fecha_hora, '.mat'];
save(nombre_mat, 't', 't_temp', 'I_total', 'V_total', 'T_total', ...
     'estado', 'I_nom', 'I_alerta', 'I_max', 'I_min', 'T_alerta', 'T_crit', ...
     'idx_alerta_corriente', 'idx_alarma_corriente', 'idx_alerta_temp', 'idx_alarma_temp');
fprintf('✅ Respaldo guardado en: %s\n', nombre_mat);

% --- MOSTRAR ESPACIO OCUPADO ---
info_csv = dir(nombre_csv);
info_mat = dir(nombre_mat);
fprintf('\n📊 Espacio ocupado en memoria local (simulación SPIFFS):\n');
fprintf('   CSV (datos del vuelo):   %.2f KB\n', info_csv.bytes/1024);
fprintf('   MAT (respaldo completo): %.2f KB\n', info_mat.bytes/1024);
fprintf('   Total ocupado:           %.2f KB\n', (info_csv.bytes + info_mat.bytes)/1024);
fprintf('   Espacio disponible (ESP32): ~2000 KB (2 MB)\n');
fprintf('   Ocupación: %.1f%% de la memoria total\n', ...
    (info_csv.bytes + info_mat.bytes)/1024 / 2000 * 100);

fprintf('\n✅ Respaldo local completado.\n');
fprintf('   El archivo CSV contiene %d registros de telemetría.\n', height(datos_locales));