# Stress Test Examples

## Setup

```bash
cd stress-test
pip install -r requirements.txt
```

## Example 1: Test Local Backend (Quick)

```bashQuick Test

```bash
./run_stress_test.sh --env local --profile quick
## Example 2: Interactive Testing with Locust Web UI

```bash
# Start Locust web interface
./run_stress_test.sh --env local --mode web

# Open http://localhost:8089 in your browser
# Enter number of users and spawn rate
# Click "Start swarming" to begin test
```

## Example 3: Test Docker Swarm Deployment

```bash
# Test your Docker Swarm cluster
./run_stress_test.sh --env swarm --profile standard
```

## Example 4: Test Kubernetes Deployment

```bash
# Test your Kubernetes cluster (NodePort 30080)
./run_stress_test.sh --env k8s --profile standard
```

## Example 5: Custom URL Testing

```bash
# Test any custom backend URL
./run_stress_test.sh --url http://192.168.1.100:8000 --profile load --mode headless
```

## Example 6: Docker-based Testing

```bash
# Build the stress test container
docker build -t yolo-stress-test .

# Run with Locust web UI
docker run -p 8089:8089 yolo-stress-test

# Run async benchmark
docker run --network host yolo-stress-test \
  python benchmark_async.py --url http://localhost:8000 --concurrent 20 --requests 500
```

## Example 7: Comparing All Environments

```bash
# Always start with a sm

```bash
./run_stress_test.sh --url http://192.168.1.100:8000 --profile standard
```

## Example 6: Direct Python

```bash
# Async benchmark
python benchmark_async.py --env k8s --profile quick

# Locust
locust -f stress_test.py --host http://localhost:30080 --headless -u 20 -r 5 -t 5m
```

**Output:**
```
=== Available Environments ===
  local           - Local Docker Compose deployment (http://localhost:8000)
  swarm           - Docker Swarm cluster (http://localhost:8000)
  k8s             - Kubernetes cluster (NodePort) (http://localhost:30080)

=== Available Test Profiles ===
  smoke           - Quick smoke test
                    Users: 5, Spawn rate: 1, Duration: 30s
  quick           - Quick benchmark
                    Users: 10, Spawn rate: 2, Duration: 1m
  standard        - Standard load test
                    Users: 20, Spawn rate: 5, Duration: 5m
  ...
```

## Example 10: Progressive Load Testing

```bash
# Test with increasing load to find breaking point
for profile in smoke quick standard load; do
  echo "Testing witOptions

```bash
./run_stress_test.sh --liststs/second: 45.2
P95 Response Time: 0.521s
P99 Response Time: 0.892s

Threshold Checks:
  Failure Rate: 0.50% (max: 1.00%) ✓ PASS
  P95 Response Time: 0.521s (max: 2.0s) ✓ PASS
  Requests/Second: 45.20 (min: 10) ✓ PASS
```Monitor Results

```bash
./run_stress_test.sh --env k8s --profile endurance --mode headless
```

## Tips

- Start with `smoke` profile for quick validation
- Use `web` mode for interactive testing
- Use `headless` mode for automated reports
- Check `results/` directory for HTML reports