# YOLO Backend API - Stress Testing Service

A standalone stress testing service for the YOLO backend API. Supports testing both local and deployed backends with configurable test profiles.

## Features

- 🎯 **Multi-Environment Support**: Test local, Docker, Kubernetes, staging, and production deployments
- 📊 **Multiple Testing Tools**: Locust (web UI + headless) and async Python benchmark
- ⚙️ **Configurable Profiles**: Pre-defined test profiles for different scenarios (smoke, load, spike, endurance, etc.)
- 🐳 **Dockerized**: Run tests in containers for isolation and portability
- 📈 **Detailed Metrics**: Response times, percentiles, failure rates, and threshold checks
- 🎨 **HTML Reports**: Generate beautiful HTML reports with charts and statistics

## Quick Start

### 1. Installation

```bash
cd stress-test
pip install -r requirements.txt
```

### 2. Configure Environments

Edit `config.yaml` to add your target environments:

```yaml
environments:
  local:
    url: "http://localhost:8000"
  
  kubernetes:
    url: "http://localhost:30080"
  
  production:
    url: "https://api.yourdomain.com"
```

### 3. Run a Test

```bash
# Quick async benchmark on local environment
./run_stress_test.sh --env local --profile quick

# Interactive Locust web UI
./run_stress_test.sh --env local --mode web

# Headless load test
./run_stress_test.sh --env kubernetes --profile load --mode headless
```

## Usage Guide

### Command-Line Interface

```bash
./run_stress_test.sh [OPTIONS]

Options:
  -e, --env <env>         Environment: local, docker, kubernetes, staging, production
  -p, --profile <profile> Profile: smoke, quick, standard, load, spike, endurance, stress
  -u, --url <url>         Custom API URL (overrides --env)
  -m, --mode <mode>       Mode: async (default), web, headless
  -l, --list              List available environments and profiles
  -h, --help              Show help message
```

### Test Profiles

| Profile | Users | Duration | Description |
|---------|-------|----------|-------------|
| `smoke` | 5 | 30s | Quick smoke test |
| `quick` | 10 | 1m | Quick benchmark |
| `standard` | 20 | 5m | Standard load test |
| `load` | 50 | 10m | Extended load test |
| `spike` | 100 | 2m | Burst/spike test |
| `endurance` | 20 | 30m | Long-running endurance test |
| `stress` | 100 | 15m | High-load stress test |

### Testing Modes

#### 1. Async Benchmark (Default)

Fast, lightweight Python-based benchmark:

```bash
# Using environment and profile
./run_stress_test.sh --env local --profile standard

# Using custom URL
python benchmark_async.py --url http://localhost:8000 --concurrent 20 --requests 500
```

#### 2. Locust Web UI

Interactive web interface for real-time monitoring:

```bash
./run_stress_test.sh --env local --mode web
# Then open http://localhost:8089
```

#### 3. Locust Headless

Automated tests with HTML reports:

```bash
./run_stress_test.sh --env kubernetes --profile load --mode headless
# Report saved to results/ directory
```

## Docker Usage

### Build Image

```bash
cd stress-test
docker build -t yolo-stress-test .
```

### Run with Docker

```bash
# Locust web UI
docker run -p 8089:8089 yolo-stress-test

# Async benchmark
docker run yolo-stress-test python benchmark_async.py --env docker --profile quick

# Headless with custom URL
docker run yolo-stress-test locust -f stress_test.py \
  --host http://your-backend:8000 \
  --headless -u 20 -r 5 -t 5m
```

### Docker Compose

```bash
# Start service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop service
docker-compose down
```

## Configuration

### Environment Configuration (`config.yaml`)

```yaml
environments:
  local:
    url: "http://localhost:8000"
    description: "Local development"
  
  kubernetes:
    url: "http://localhost:30080"
    description: "Local K8s cluster"
```

### Test Mix

Customize the distribution of test requests:

```yaml
test_mix:
  health_check: 0.1        # 10% health checks
  predict_no_image: 0.6    # 60% predictions without image
  predict_with_image: 0.2  # 20% predictions with image
  predict_large_image: 0.1 # 10% large image predictions
```

### Performance Thresholds

Define success criteria:

```yaml
thresholds:
  max_failure_rate: 0.01           # 1% max failure rate
  max_p95_response_time: 2.0       # 2s max P95 response time
  max_p99_response_time: 5.0       # 5s max P99 response time
  min_requests_per_second: 10      # 10 RPS minimum
```

## Testing Different Deployments

### Local Backend

```bash
# Start backend
cd backend
python main.py

# Test it
cd stress-test
./run_stress_test.sh --env local --profile quick
```

### Docker Backend

```bash
# Start backend container
docker run -p 8000:8000 yolo-backend

# Test it
./run_stress_test.sh --env docker --profile standard
```

### Kubernetes Deployment

```bash
# Assuming backend is exposed on NodePort 30080
./run_stress_test.sh --env kubernetes --profile load --mode headless
```

### Remote/Production

```bash
# Test staging
./run_stress_test.sh --env staging --profile smoke

# Test production (careful!)
./run_stress_test.sh --env production --profile smoke
```

## Understanding Results

### Key Metrics

- **RPS (Requests/Second)**: Total throughput - higher is better
- **P50/P95/P99**: Response time percentiles - lower is better
- **Failure Rate**: Percentage of failed requests - should be near 0%
- **Min/Max/Mean**: Response time distribution

### Example Output

```
========================================================================
BENCHMARK RESULTS
========================================================================

Total requests: 500
Successful: 498
Failed: 2
Success rate: 99.60%
Total time: 18.45s
Requests/second: 27.10

Response times (successful requests):
  Min: 0.142s
  Max: 1.523s
  Mean: 0.456s
  Median: 0.398s

Percentiles:
  50th: 0.398s
  90th: 0.721s
  95th: 0.892s
  99th: 1.234s

Threshold Checks:
  Failure Rate: 0.40% (max: 1.00%) ✓ PASS
  P95 Response Time: 0.892s (max: 2.0s) ✓ PASS
  P99 Response Time: 1.234s (max: 5.0s) ✓ PASS
  Requests/Second: 27.10 (min: 10) ✓ PASS
========================================================================
```

## Testing Strategies

### 1. Smoke Test

Quick validation after deployment:

```bash
./run_stress_test.sh --env production --profile smoke
```

### 2. Load Testing

Verify performance under expected load:

```bash
./run_stress_test.sh --env staging --profile load --mode headless
```

### 3. Spike Testing

Test behavior under sudden traffic bursts:

```bash
./run_stress_test.sh --env staging --profile spike --mode headless
```

### 4. Endurance Testing

Check for memory leaks and degradation:

```bash
./run_stress_test.sh --env staging --profile endurance --mode headless
```

### 5. Stress Testing

Find breaking point:

```bash
./run_stress_test.sh --env staging --profile stress --mode headless
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Performance Test
on: [push, pull_request]

jobs:
  stress-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start Backend
        run: |
          cd backend
          pip install -r requirements.txt
          python main.py &
          sleep 10
      
      - name: Run Stress Test
        run: |
          cd stress-test
          pip install -r requirements.txt
          python benchmark_async.py --env local --profile quick
      
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: stress-test-results
          path: stress-test/results/
```

## Troubleshooting

### API Not Responding

```
Error: API is not responding
```

**Solution**: Ensure backend is running:
```bash
curl http://localhost:8000/health
```

### Connection Refused

```
Error: Connection refused
```

**Solution**: Check firewall and network settings

### Too Many Open Files

```
Error: [Errno 24] Too many open files
```

**Solution**: Increase file descriptor limit:
```bash
ulimit -n 4096
```

### Memory Issues

```
Error: MemoryError
```

**Solution**: Reduce concurrent users or use Docker with resource limits

## Advanced Usage

### Custom Test Script

Create custom scenarios by modifying `stress_test.py`:

```python
@task(5)
def custom_endpoint(self):
    """Test custom endpoint."""
    with self.client.post("/custom", json={"data": "test"}) as response:
        if response.status_code == 200:
            response.success()
```

### Distributed Testing

Run Locust in distributed mode for higher load:

```bash
# Master
locust -f stress_test.py --master --host=http://backend:8000

# Workers (multiple terminals/machines)
locust -f stress_test.py --worker --master-host=<master-ip>
```

## Best Practices

1. **Start Small**: Begin with smoke tests before ramping up
2. **Test Progressively**: Gradually increase load to find limits
3. **Monitor Backend**: Watch CPU, memory, and logs during tests
4. **Use Realistic Data**: Test with production-like images and patterns
5. **Isolate Tests**: Run on dedicated test environments
6. **Automate**: Integrate into CI/CD for continuous validation
7. **Set Baselines**: Establish performance baselines and track changes

## Resources

- [Locust Documentation](https://docs.locust.io/)
- [Performance Testing Guide](https://martinfowler.com/articles/practical-test-pyramid.html#PerformanceTests)
- [aiohttp Documentation](https://docs.aiohttp.org/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review test logs in `results/` directory
3. Verify backend is accessible: `curl http://your-url/health`
