# ============================================================
# STAGE 1 — Compilador / instalador de dependencias
# ============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Instalar dependencias del sistema necesarias para compilar paquetes
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar solo el archivo de dependencias primero (caché eficiente)
COPY requirements.txt .

# Crear entorno virtual e instalar dependencias
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ============================================================
# STAGE 2 — Imagen final de producción
# ============================================================
FROM python:3.11-slim AS production

# Metadatos
LABEL maintainer="Innovatech Chile"
LABEL description="Frontend Web - Flask/Python"
LABEL version="1.0"

# Crear usuario no-root para mínimo privilegio
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# Copiar el entorno virtual desde la etapa builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copiar el código fuente de la aplicación
COPY --chown=appuser:appgroup . .

# Cambiar al usuario no-root
USER appuser

# Puerto que expone el servidor Flask
EXPOSE 5000

# Variables de entorno de producción
ENV FLASK_ENV=production
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Healthcheck — verifica que el servidor Flask responde
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000')" || exit 1

# Comando de inicio
CMD ["python", "app.py"]
