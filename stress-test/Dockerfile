FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy stress test files
COPY stress_test.py .
COPY benchmark_async.py .
COPY config.yaml .
COPY run_stress_test.sh .

# Make script executable
RUN chmod +x run_stress_test.sh

# Create results directory
RUN mkdir -p results

# Default command - run Locust web UI
CMD ["locust", "-f", "stress_test.py", "--web-host", "0.0.0.0", "--web-port", "8089"]

# Alternative usage:
# Run async benchmark: docker run stress-test python benchmark_async.py --env kubernetes --profile standard
# Run locust headless: docker run stress-test locust -f stress_test.py --host http://backend:8000 --headless -u 20 -r 5 -t 5m
