FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy entrypoint and make executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Copy source
COPY . .

ENTRYPOINT ["./entrypoint.sh"]
