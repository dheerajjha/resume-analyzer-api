#!/bin/bash

# Exit on error
set -e

echo "Starting Resume PDF Converter API setup in Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    # Update package list
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up the stable repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "Docker installed successfully. You may need to log out and back in for group changes to take effect."
else
    echo "Docker is already installed"
fi

# Create Dockerfile
echo "Creating Dockerfile..."
cat > Dockerfile << 'EOF'
# Use Python 3.11 slim image as base
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Second stage: Runtime
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install runtime dependencies for Playwright
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Install Playwright browsers
RUN playwright install chromium --with-deps

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Copy application code
COPY --chown=appuser:appuser . .

# Create logs directory with correct permissions
RUN mkdir -p /app/logs && chown -R appuser:appuser /app/logs

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Run the application
CMD ["python", "main.py"]
EOF

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  resume-pdf-api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    environment:
      - TZ=UTC
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
EOF

# Create logs directory with proper permissions
mkdir -p logs
sudo chown -R $USER:$USER logs

# Build and start the container
echo "Building and starting Docker container..."
docker-compose up --build -d

# Wait for the service to start
echo "Waiting for service to start..."
sleep 10

# Check if the service is running
if curl -s http://localhost:8000 > /dev/null; then
    echo "Setup completed successfully!"
    echo "The API is now running at http://localhost:8000"
    echo ""
    echo "Useful commands:"
    echo "- View logs: docker-compose logs -f"
    echo "- Stop service: docker-compose down"
    echo "- Start service: docker-compose up -d"
    echo "- Rebuild and restart: docker-compose up --build -d"
    echo "- Check container health: docker inspect --format='{{json .State.Health}}' $(docker-compose ps -q resume-pdf-api)"
    echo ""
    echo "API Documentation available at: http://localhost:8000/docs"
else
    echo "Error: Service failed to start. Check logs with: docker-compose logs"
    exit 1
fi 