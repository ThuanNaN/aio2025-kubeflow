# YOLO Backend API - Stress Testing

Simple Python-based stress testing tools for the YOLO backend API. Test your Docker Compose, Docker Swarm, and Kubernetes deployments.

## Features

- 🎯 **3 Environments**: Test local (Docker Compose), Swarm, and K8s deployments
- 📊 **Two Tools**: Locust (interactive web UI) and async benchmark (fast CLI)
- ⚙️ **7 Profiles**: Pre-configured test scenarios (smoke, quick, standard, load, spike, endurance, stress)
- 📈 **Detailed Metrics**: Response times, percentiles, failure rates, and threshold checks
- 🖼️ **Real Images**: Uses COCO val2014 dataset (40,504 images) for realistic testing
- 🎨 **HTML Reports**: Generate beautiful reports with Locust

## Quick Start

```bash
cd stress-test

# Install dependencies
pip install -r requirements.txt

# Test your Docker Compose deployment
./run_stress_test.sh --env local --profile quick

# Test Docker Swarm
./run_stress_test.sh --env swarm --profile standard

# Test Kubernetes
./run_stress_test.sh --env k8s --profile load
```

**Note**: Automatically uses real images from `../val2014/` (40,504 COCO images). Falls back to synthetic images if not available.

## Configuration

The service is pre-configured for 3 deployment environments:

```yaml
environments:
  local:
    url: "http://localhost:8000"
    description: "Local Docker Compose deployment"
  
  swarm:
    url: "http://localhost:8000"
bash
# Quick async benchmark on local environment
./run_stress_test.sh --env local --profile quick

# Interactive Locust web UI
./run_stress_test.sh --env local --mode web

# Headless load test on Kubernetes
./run_stress_test.sh --env k8s --profile load --mode headless
```

## Usage Guide

### Comm

### Option 1: Shell Script (Recommended)

```bash
./run_stress_test.sh [OPTIONS]

Options:
  -e, --env <env>         Environment: local, swarm, k8s
  -p, --profile <profile> Profile: smoke, quick, standard, load, spike, endurance, stress
  -m, --mode <mode>       Mode: async (default), web, headless
  -u, --url <url>         Custom URL (overrides --env)
  -l, --list              List options
  -h, --help              Help

Examples:
  ./run_stress_test.sh --env local --profile quick
  ./run_stress_test.sh --env k8s --profile load --mode headless
  ./run_stress_test.sh --list
```

### Option 2: Direct Python

```bash
# Async benchmark
python benchmark_async.py --env local --profile quick

# Locust web UI
locust -f stress_test.py --host http://localhost:8000

# Locust headless
locust -f stress_test.py --host http://localhost:8000 --headless -u 20 -r 5 -t 5m
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

### Real Image Testing

The stress test automatically uses real images from the COCO val2014 dataset for more realistic testing:

- **Location**: `../val2014/` (relative to stress-test directory)
- **Dataset**: COCO 2014 Validation Set (~40,000+ images)
- **Behavior**: 
  - ✅ If `val2014/` exists: Randomly selects actual images for each request
  - ⚠️ If not found: Falls back to generating synthetic random images
  
When starting the tests, you'll see:
```
Loaded 40504 images from /path/to/val2014
```

This ensures the YOLO model processes real-world images during stress testing, providing accurate performance metrics.

### Testing Modes

#### 1. Async Benchmark (Default)

Fast, lightweight Python-based benchmark:

```bash
# Test Docker Compose deployment
./run_stress_test.sh --env local --profile standard

# Test Docker Swarm cluster
./run_stress_test.sh --env swarm --profile standard

# Test Kubernetes cluster
./run_stress_test.sh --env k8s --profile standard

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

AutTest Profiles
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
Edit `config.yaml` to customize test mix, image sizes, and performance thresholds.un_stress_test.sh --env swarm --profile load --mode headless
```

### Kubernetes Deployment

```bash
# Test Kubernetes cluster (NodePort 30080)
./run_stress_test.sh --env k8s --profile load --mode headless
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
======= Your Deployments

```bash
# Docker Compose (local)
./run_stress_test.sh --env local --profile quick

# Docker Swarm
./run_stress_test.sh --env swarm --profile standard

# Kubernetes
./run_stress_test.sh --env k8s --profile load

# Compare all
for env in local swarm k8s; do
  ./run_stress_test.sh --env $env --profile quick
done
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
Results

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
Files

- `benchmark_async.py` - Fast async Python benchmark tool
- `stress_test.py` - Locust load testing (web UI + headless)
- `run_stress_test.sh` - Convenient wrapper script
- `config.yaml` - Environment and profile configuration
- `test_image_loading.py` - Verify val2014 image loading
- `results/` - Generated reports and logs

## Troubleshooting

**API not responding:**
```bash
curl http://localhost:8000/health
```

**Too many open files:**
```bash
ulimit -n 4096
```

**Dependencies missing:**
```bash
pip install -r requirements.txt
``