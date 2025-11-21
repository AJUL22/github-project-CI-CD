# Use an official Python runtime as a parent image
FROM python:3.11-slim AS builder

WORKDIR /app
# install build deps (if any) and pip
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install into /opt/venv for a slim final image
COPY requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy app source
COPY . .

# Final image: lightweight
FROM python:3.11-slim AS runtime
WORKDIR /app

# Create non-root user
RUN useradd -m appuser && mkdir -p /app
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy app files (avoid copying VCS files etc.)
COPY --from=builder /app /app

# Use non-root
USER appuser
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2", "--threads", "2"]
