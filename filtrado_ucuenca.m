function procesador_frecuencia_ucuenca()
% =========================================================================
%  PROCESADOR DE SEÑALES EN EL DOMINIO DE LA FRECUENCIA
%  Universidad de Cuenca — Señales y Sistemas
%  x(t) --> H(f) --> y(t)
%  Filtros: Pasa-bajas, Pasa-altas, Pasa-banda, Rechaza-banda
%  Procesamiento via FFT / multiplicacion en frecuencia (conv. en tiempo)
% =========================================================================

    disp('=== Procesador de Señales - Dominio Frecuencia UCuenca ===');

    % ------------------------------------------------------------------ %
    %  1. CARGA DE SEÑAL DE ENTRADA x(t)
    % ------------------------------------------------------------------ %
    [arch, ruta] = uigetfile('*.wav', 'Selecciona señal de entrada x(t)');
    if isequal(arch, 0), return; end

    [x_orig, Fs] = audioread(fullfile(ruta, arch));
    x_orig = mean(x_orig, 2);                        % mono
    x_orig = x_orig / max(abs(x_orig) + eps);        % normalizar

    N    = length(x_orig);
    dt   = 1 / Fs;
    t    = (0:N-1).' * dt;                           % vector tiempo
    Nfft = 2^nextpow2(N);                            % potencia de 2 para FFT rapida
    f    = (0:Nfft-1).' * (Fs / Nfft);              % eje de frecuencia positivo completo

    fprintf('Archivo   : %s\n', arch);
    fprintf('Fs        : %d Hz  |  Duracion: %.2f s  |  Muestras: %d\n', ...
            Fs, N/Fs, N);

    % ------------------------------------------------------------------ %
    %  2. FFT DE LA SEÑAL DE ENTRADA  X(f)
    % ------------------------------------------------------------------ %
    X = fft(x_orig, Nfft);    % DFT via FFT (zero-padding a Nfft)

    % ------------------------------------------------------------------ %
    %  3. INTERFAZ GRAFICA
    % ------------------------------------------------------------------ %
    fig = uifigure('Name', 'UCuenca – Procesador Frecuencia', ...
                   'Position', [80 60 1000 720]);

    % --- Panel de control (izquierda) ---
    pnl = uipanel(fig, 'Title', 'Parámetros del filtro H(f)', ...
                  'Position', [10 10 240 700], 'FontWeight', 'bold');

    uilabel(pnl, 'Position', [10 640 220 20], 'Text', 'Tipo de filtro:', ...
            'FontWeight', 'bold');
    dd_tipo = uidropdown(pnl, 'Position', [10 610 210 28], ...
        'Items', {'Pasa-bajas','Pasa-altas','Pasa-banda','Rechaza-banda'}, ...
        'Value', 'Pasa-bajas', 'ValueChangedFcn', @(s,e) actualizar_panel());

    % -- Frecuencias de corte --
    uilabel(pnl, 'Position', [10 572 220 20], 'Text', 'fc1 – Frec. corte baja (Hz):', ...
            'FontWeight', 'bold');
    sld_fc1 = uislider(pnl, 'Position', [10 548 200 3], ...
        'Limits', [20 Fs/2], 'Value', min(2000, Fs/2), ...
        'MajorTicks', [], 'ValueChangedFcn', @(s,e) actualizar_todo());
    lbl_fc1 = uilabel(pnl, 'Position', [10 530 220 18], ...
        'Text', sprintf('%.0f Hz', sld_fc1.Value));

    uilabel(pnl, 'Position', [10 505 220 20], 'Text', 'fc2 – Frec. corte alta (Hz):', ...
            'FontWeight', 'bold');
    sld_fc2 = uislider(pnl, 'Position', [10 480 200 3], ...
        'Limits', [20 Fs/2], 'Value', min(4000, Fs/2), ...
        'MajorTicks', [], 'ValueChangedFcn', @(s,e) actualizar_todo());
    lbl_fc2 = uilabel(pnl, 'Position', [10 462 220 18], ...
        'Text', sprintf('%.0f Hz', sld_fc2.Value));

    uilabel(pnl, 'Position', [10 438 220 20], 'Text', 'Orden del filtro:', ...
            'FontWeight', 'bold');
    dd_orden = uidropdown(pnl, 'Position', [10 410 100 28], ...
        'Items', {'1','2','4','6','8'}, 'Value', '2', ...
        'ValueChangedFcn', @(s,e) actualizar_todo());

    % -- Botones --
    % Colores definidos
    color_x   = [0.13 0.47 0.71];       % azul  — x(t)
    color_y   = [0.85 0.33 0.10];       % tomate — y(t)
    color_det = [0.75 0.15 0.15];       % rojo detener

    % Handle compartido al reproductor activo
    ap_handle  = [];
    playing_x  = false;   % flag: se esta reproduciendo x(t)?
    playing_y  = false;   % flag: se esta reproduciendo y(t)?

    btn_play_x = uibutton(fig, 'push', 'Text', '▶  x(t)', ...
        'Position', [260 20 190 36], 'BackgroundColor', color_x, ...
        'FontColor', 'w', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) toggle_play_x());

    btn_play_y = uibutton(fig, 'push', 'Text', '▶  y(t)', ...
        'Position', [460 20 190 36], 'BackgroundColor', color_y, ...
        'FontColor', 'w', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) toggle_play_y());

    btn_guardar = uibutton(fig, 'push', 'Text', '💾  Guardar  y(t).wav', ...
        'Position', [660 20 210 36], 'BackgroundColor', [0.5 0.18 0.56], ...
        'FontColor', 'w', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) guardar_audio());

    lbl_estado = uilabel(fig, 'Position', [260 60 630 20], ...
        'Text', 'Listo.', 'FontAngle', 'italic');

    % --- Ejes de graficas ---
    ax_Hf  = uiaxes(fig, 'Position', [260 540 730 160]);
    title(ax_Hf,  '|H(f)| — Respuesta en frecuencia del filtro');
    xlabel(ax_Hf, 'Frecuencia (Hz)'); ylabel(ax_Hf, 'Ganancia'); grid(ax_Hf,'on');

    ax_esp = uiaxes(fig, 'Position', [260 360 730 160]);
    title(ax_esp, '|X(f)| vs |Y(f)| — Espectros de amplitud (dB)');
    xlabel(ax_esp, 'Frecuencia (Hz)'); ylabel(ax_esp, 'dB'); grid(ax_esp,'on');

    ax_xt  = uiaxes(fig, 'Position', [260 190 350 150]);
    title(ax_xt,  'Señal de entrada  x(t)');
    xlabel(ax_xt, 'Tiempo (s)'); ylabel(ax_xt, 'Amplitud'); grid(ax_xt,'on');

    ax_yt  = uiaxes(fig, 'Position', [640 190 350 150]);
    title(ax_yt,  'Señal de salida  y(t)');
    xlabel(ax_yt, 'Tiempo (s)'); ylabel(ax_yt, 'Amplitud'); grid(ax_yt,'on');

    % Estado interno
    y_cache = [];

    % Dibujar x(t) una sola vez
    dec = max(1, floor(N/4000));
    plot(ax_xt, t(1:dec:end), x_orig(1:dec:end), 'Color', color_x, 'LineWidth', 1);
    ylim(ax_xt, [-1.1 1.1]);

    % Primer procesado
    actualizar_panel();
    actualizar_todo();

    % ================================================================== %
    %  FUNCIONES INTERNAS
    % ================================================================== %

    function actualizar_panel()
        tipo   = dd_tipo.Value;
        es_bp  = ismember(tipo, {'Pasa-banda','Rechaza-banda'});
        sld_fc2.Enable = es_bp;
        actualizar_todo();
    end

    function actualizar_todo()
        % Actualizar etiquetas de sliders
        lbl_fc1.Text = sprintf('%.0f Hz', sld_fc1.Value);
        lbl_fc2.Text = sprintf('%.0f Hz', sld_fc2.Value);

        lbl_estado.Text = 'Procesando...';
        drawnow;

        % ---- Construir H(f) en frecuencia positiva ----
        fc1   = sld_fc1.Value;
        fc2   = sld_fc2.Value;
        orden = str2double(dd_orden.Value);
        tipo  = dd_tipo.Value;
        nyq   = Fs / 2;

        H_pos = calcular_H(f(1:Nfft/2+1), fc1, fc2, orden, tipo, nyq);

        % Simetria hermitiana: H completo para IFFT real
        H_full = [H_pos; flipud(H_pos(2:end-1))];
        if length(H_full) < Nfft
            H_full(end+1) = H_pos(end);
        end

        % ---- Procesamiento en frecuencia: Y(f) = X(f) * H(f) ----
        Y = X .* H_full;

        % ---- IFFT -> y(t) ----
        y_full = real(ifft(Y));
        y_proc = y_full(1:N);
        y_proc = y_proc / max(abs(y_proc) + eps);   % normalizar
        y_cache = y_proc;

        % ---- Graficas ----
        f_plot = f(1:Nfft/2+1);      % solo parte positiva

        % H(f)
        cla(ax_Hf);
        plot(ax_Hf, f_plot, H_pos, 'Color', [0.13 0.55 0.13], 'LineWidth', 2);
        xlim(ax_Hf, [0 nyq]); ylim(ax_Hf, [-0.05 1.15]);
        grid(ax_Hf, 'on');

        % Espectros |X(f)| vs |Y(f)| en dB
        Xmag = 20*log10(abs(X(1:Nfft/2+1)) / max(abs(X)+eps) + eps);
        Ymag = 20*log10(abs(Y(1:Nfft/2+1)) / max(abs(X)+eps) + eps);
        cla(ax_esp);
        plot(ax_esp, f_plot, Xmag, 'Color',[0.49 0.18 0.56], 'LineWidth',1.2); hold(ax_esp,'on');
        plot(ax_esp, f_plot, Ymag, '--','Color', color_y,'LineWidth',1.5); hold(ax_esp,'off');
        legend(ax_esp, '|X(f)|', '|Y(f)|', 'Location','northeast');
        xlim(ax_esp, [0 nyq]); ylim(ax_esp, [-80 5]);
        grid(ax_esp, 'on');

        % y(t)
        cla(ax_yt);
        dec = max(1, floor(N/4000));
        plot(ax_yt, t(1:dec:end), y_proc(1:dec:end), 'Color', color_y,'LineWidth',1);
        ylim(ax_yt, [-1.1 1.1]);
        grid(ax_yt, 'on');

        lbl_estado.Text = sprintf('Listo. Filtro: %s | fc1=%.0f Hz | fc2=%.0f Hz | Orden=%d', ...
            tipo, fc1, fc2, orden);
    end

    function y = y_actual()
        if isempty(y_cache)
            y = x_orig;
        else
            y = y_cache;
        end
    end

    % ---- Reproduccion con pausa/reanudacion ----

    function toggle_play_x()
        % Si y(t) esta reproduciendose, detenerlo primero
        if playing_y && ~isempty(ap_handle) && isvalid(ap_handle)
            stop(ap_handle);
            playing_y = false;
            btn_play_y.Text = '▶  y(t)';
            btn_play_y.BackgroundColor = color_y;
        end

        if playing_x && ~isempty(ap_handle) && isvalid(ap_handle)
            % Pausar si esta sonando
            if strcmp(ap_handle.Running, 'on')
                pause(ap_handle);
                btn_play_x.Text = '▶  x(t)';
                btn_play_x.BackgroundColor = color_x;
                lbl_estado.Text = 'x(t) pausado.';
            else
                % Reanudar si esta pausado
                resume(ap_handle);
                btn_play_x.Text = '⏸  x(t)';
                btn_play_x.BackgroundColor = color_det;
                lbl_estado.Text = 'Reproduciendo x(t)...';
            end
        else
            % Iniciar nueva reproduccion
            try
                ap = audioplayer(x_orig, Fs);
                ap_handle = ap;
                playing_x = true;
                playing_y = false;
                ap.StopFcn = @(~,~) reset_after_play_x();
                btn_play_x.Text = '⏸  x(t)';
                btn_play_x.BackgroundColor = color_det;
                play(ap);
                lbl_estado.Text = 'Reproduciendo x(t)...';
            catch e
                lbl_estado.Text = ['Error audio: ' e.message];
            end
        end
    end

    function toggle_play_y()
        % Si x(t) esta reproduciendose, detenerlo primero
        if playing_x && ~isempty(ap_handle) && isvalid(ap_handle)
            stop(ap_handle);
            playing_x = false;
            btn_play_x.Text = '▶  x(t)';
            btn_play_x.BackgroundColor = color_x;
        end

        if playing_y && ~isempty(ap_handle) && isvalid(ap_handle)
            % Pausar si esta sonando
            if strcmp(ap_handle.Running, 'on')
                pause(ap_handle);
                btn_play_y.Text = '▶  y(t)';
                btn_play_y.BackgroundColor = color_y;
                lbl_estado.Text = 'y(t) pausado.';
            else
                % Reanudar si esta pausado
                resume(ap_handle);
                btn_play_y.Text = '⏸  y(t)';
                btn_play_y.BackgroundColor = color_det;
                lbl_estado.Text = 'Reproduciendo y(t)...';
            end
        else
            % Iniciar nueva reproduccion de la señal procesada
            try
                y_rep = y_actual();
                ap = audioplayer(y_rep, Fs);
                ap_handle = ap;
                playing_y = true;
                playing_x = false;
                ap.StopFcn = @(~,~) reset_after_play_y();
                btn_play_y.Text = '⏸  y(t)';
                btn_play_y.BackgroundColor = color_det;
                play(ap);
                lbl_estado.Text = 'Reproduciendo y(t) — señal filtrada...';
            catch e
                lbl_estado.Text = ['Error audio: ' e.message];
            end
        end
    end

    function reset_after_play_x()
        % Llamado al terminar reproduccion de x(t); restaurar via timer (hilo UI)
        if ~isvalid(fig), return; end
        playing_x = false;
        tr = timer('ExecutionMode','singleShot','StartDelay',0.05, ...
            'TimerFcn', @(~,~) restaurar_btn_x());
        start(tr);
    end

    function reset_after_play_y()
        % Llamado al terminar reproduccion de y(t); restaurar via timer (hilo UI)
        if ~isvalid(fig), return; end
        playing_y = false;
        tr = timer('ExecutionMode','singleShot','StartDelay',0.05, ...
            'TimerFcn', @(~,~) restaurar_btn_y());
        start(tr);
    end

    function restaurar_btn_x()
        if isvalid(btn_play_x)
            btn_play_x.Text = '▶  x(t)';
            btn_play_x.BackgroundColor = color_x;
        end
        if isvalid(lbl_estado)
            lbl_estado.Text = 'Reproduccion de x(t) finalizada.';
        end
    end

    function restaurar_btn_y()
        if isvalid(btn_play_y)
            btn_play_y.Text = '▶  y(t)';
            btn_play_y.BackgroundColor = color_y;
        end
        if isvalid(lbl_estado)
            lbl_estado.Text = 'Reproduccion de y(t) finalizada.';
        end
    end

    function guardar_audio()
        [nombre, ruta_out] = uiputfile('*.wav', 'Guardar y(t) como...', 'y_t_filtrada.wav');
        if isequal(nombre,0), return; end
        audiowrite(fullfile(ruta_out, nombre), y_actual(), Fs);
        lbl_estado.Text = ['Guardado: ' nombre];
        disp(['Audio guardado: ' fullfile(ruta_out, nombre)]);
    end

end % fin procesador_frecuencia_ucuenca


% ========================================================================
%  FUNCION: calcular_H — respuesta en frecuencia de cada tipo de filtro
%  Implementa aproximacion en frecuencia continua
%  (procesamiento CT discretizado a traves de DFT)
% ========================================================================
function H = calcular_H(f_vec, fc1, fc2, N, tipo, nyq)
%  f_vec : vector de frecuencias [0 .. nyq]
%  Devuelve ganancia real H >= 0 del mismo tamaño que f_vec

    fn = f_vec / nyq;    % frecuencia normalizada [0,1]

    switch tipo

        case 'Pasa-bajas'
            % Butterworth LP: |H(jw)|^2 = 1 / (1 + (f/fc)^(2N))
            fc_n  = fc1 / nyq;
            ratio = fn / max(fc_n, 1e-9);
            H = 1 ./ sqrt(1 + ratio.^(2*N));

        case 'Pasa-altas'
            fc_n  = fc1 / nyq;
            ratio = max(fc_n, 1e-9) ./ max(fn, 1e-9);
            H = 1 ./ sqrt(1 + ratio.^(2*N));

        case 'Pasa-banda'
            f1n = min(fc1,fc2) / nyq;
            f2n = max(fc1,fc2) / nyq;
            f0n = sqrt(f1n * f2n);        % frecuencia central geometrica
            bw  = max(f2n - f1n, 1e-9);
            % Transformacion de Butterworth BP
            ratio = (fn.^2 - f0n^2) ./ (max(fn,1e-9) .* bw);
            H = 1 ./ sqrt(1 + ratio.^(2*N));

        case 'Rechaza-banda'
            f1n = min(fc1,fc2) / nyq;
            f2n = max(fc1,fc2) / nyq;
            f0n = sqrt(f1n * f2n);
            bw  = max(f2n - f1n, 1e-9);
            ratio = (max(fn,1e-9) .* bw) ./ abs(fn.^2 - f0n^2 + 1e-12);
            H = 1 ./ sqrt(1 + ratio.^(2*N));

        otherwise
            H = ones(size(f_vec));   % sin filtrado por defecto
    end

    H = max(H, 0);    % garantizar no-negativo
end