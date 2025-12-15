# Quick Start Examples for Stress Testing

## Prerequisites

```bash
cd stress-test
pip install -r requirements.txt
```

## Example 1: Test Local Backend (Quick)

```bash
# Start your backend first
cd ../backend
python main.py

# In another terminal, run a quick test
cd ../stress-test
./run_stress_test.sh --env local --profile quick
```

**Expected Output:**
```
[INFO] Checking if API is available at http://localhost:8000...
[INFO] ✓ API is responding
[INFO] Running async benchmark...

======================================================================
YOLO Backend API - Async Benchmark
======================================================================
Target URL: http://localhost:8000
Concurrent users: 10
Total requests: 100
...
Success rate: 99.00%
Requests/second: 25.4
======================================================================
```

## Example 2: Interactive Testing with Locust Web UI

```bash
# Start Locust web interface
./run_stress_test.sh --env local --mode web

# Open http://localhost:8089 in your browser
# Enter number of users and spawn rate
# Click "Start swarming" to begin test
```

## Example 3: Test Kubernetes Deployment

```bash
# Assuming your backend is deployed on Kubernetes and exposed on port 30080
./run_stress_test.sh --env kubernetes --profile standard
```

## Example 4: Custom URL Testing

```bash
# Test any custom backend URL
./run_stress_test.sh --url http://192.168.1.100:8000 --profile load --mode headless
```

## Example 5: Docker-based Testing

```bash
# Build the stress test container
docker build -t yolo-stress-test .

# Run with Locust web UI
docker run -p 8089:8089 yolo-stress-test

# Run async benchmark
docker run --network host yolo-stress-test \
  python benchmark_async.py --url http://localhost:8000 --concurrent 20 --requests 500
```

## Example 6: Production Smoke Test

```bash
# Always start with a smoke test on production!
./run_stress_test.sh --env production --profile smoke
```

## Example 7: Load Test with Report Generation

```bash
# Generate detailed HTML report
./run_stress_test.sh --env staging --profile load --mode headless

# Report will be saved in results/ directory
# Example: results/load_report_20231216_143022.html
```

## Example 8: List All Options

```bash
# See all available environments and profiles
./run_stress_test.sh --list
```

**Output:**
```
=== Available Environments ===
  local           - Local development backend (http://localhost:8000)
  docker          - Dockerized local backend (http://localhost:8000)
  kubernetes      - Local Kubernetes cluster (http://localhost:30080)
  staging         - Staging environment (https://staging-api.example.com)
  production      - Production environment (https://api.example.com)

=== Available Test Profiles ===
  smoke           - Quick smoke test
                    Users: 5, Spawn rate: 1, Duration: 30s
  quick           - Quick benchmark
                    Users: 10, Spawn rate: 2, Duration: 1m
  standard        - Standard load test
                    Users: 20, Spawn rate: 5, Duration: 5m
  ...
```

## Example 9: Progressive Load Testing

```bash
# Test with increasing load to find breaking point
for profile in smoke quick standard load; do
  echo "Testing with profile: $profile"
  ./run_stress_test.sh --env staging --profile $profile --mode headless
  sleep 30  # Cool down between tests
done
```

## Example 10: Continuous Monitoring

```bash
# Run endurance test for 30 minutes
./run_stress_test.sh --env staging --profile endurance --mode headless

# Monitor results in real-time in another terminal
tail -f results/endurance_*.csv
```

## Understanding Results

### Good Performance Example
```
Success rate: 99.50%
Requests/second: 45.2
P95 Response Time: 0.521s
P99 Response Time: 0.892s

Threshold Checks:
  Failure Rate: 0.50% (max: 1.00%) ✓ PASS
  P95 Response Time: 0.521s (max: 2.0s) ✓ PASS
  Requests/Second: 45.20 (min: 10) ✓ PASS
```

### Poor Performance Example (needs optimization)
```
Success rate: 85.20%
Requests/second: 8.3
P95 Response Time: 3.214s
P99 Response Time: 8.521s

Threshold Checks:
  Failure Rate: 14.80% (max: 1.00%) ✗ FAIL
  P95 Response Time: 3.214s (max: 2.0s) ✗ FAIL
  Requests/Second: 8.30 (min: 10) ✗ FAIL
```

## Troubleshooting

### Backend Not Running
```bash
# Check if backend is accessible
curl http://localhost:8000/health

# If not, start it
cd ../backend
python main.py
```

### Dependencies Missing
```bash
# Install all dependencies
pip install -r requirements.txt
```

### Port Already in Use (Locust Web UI)
```bash
# Use a different port
locust -f stress_test.py --host http://localhost:8000 --web-port 8090
```

## Next Steps

1. **Customize config.yaml** - Add your environments and adjust test profiles
2. **Set thresholds** - Define acceptable performance criteria
3. **Automate** - Integrate into CI/CD pipeline
4. **Monitor** - Track performance trends over time
5. **Optimize** - Use results to improve backend performance
