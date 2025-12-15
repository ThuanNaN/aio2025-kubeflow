# Stress Test Service Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Stress Test Service                          │
│                     (standalone)                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Tests
                              ▼
        ┌─────────────────────────────────────────┐
        │         Target Environments             │
        └─────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   ┌─────────┐          ┌──────────┐         ┌──────────┐
   │  Local  │          │Kubernetes│         │Production│
   │ Backend │          │ Cluster  │         │ Backend  │
   │:8000    │          │:30080    │         │ (Remote) │
   └─────────┘          └──────────┘         └──────────┘
```

## Components

### 1. Test Tools

```
stress-test/
├── stress_test.py          # Locust-based load testing
├── benchmark_async.py      # Async Python benchmark
└── run_stress_test.sh      # CLI wrapper script
```

**Locust** (stress_test.py)
- Web UI for interactive testing
- Headless mode for automation
- Real-time metrics and charts
- Distributed testing support

**Async Benchmark** (benchmark_async.py)
- Lightweight Python script
- Detailed percentile statistics
- No web UI dependency
- Fast execution

### 2. Configuration

```
config.yaml
├── environments            # Target URLs (local, k8s, prod)
├── test_profiles          # Pre-defined test scenarios
├── test_mix               # Endpoint distribution weights
├── image_sizes            # Test image dimensions
└── thresholds             # Performance success criteria
```

### 3. Test Profiles

```
┌──────────────┬───────┬──────────┬─────────────────┐
│   Profile    │ Users │ Duration │   Description   │
├──────────────┼───────┼──────────┼─────────────────┤
│ smoke        │   5   │   30s    │ Quick validation│
│ quick        │  10   │   1m     │ Fast benchmark  │
│ standard     │  20   │   5m     │ Normal load     │
│ load         │  50   │  10m     │ Extended load   │
│ spike        │ 100   │   2m     │ Burst testing   │
│ endurance    │  20   │  30m     │ Long-running    │
│ stress       │ 100   │  15m     │ High load       │
└──────────────┴───────┴──────────┴─────────────────┘
```

## Testing Flow

```
┌────────────┐     ┌──────────────┐     ┌─────────────┐
│   Start    │────▶│ Check API    │────▶│ Load Config │
│ Test Run   │     │ Availability │     │  & Profile  │
└────────────┘     └──────────────┘     └─────────────┘
                          │                     │
                          │ API Down            │
                          ▼                     ▼
                    ┌──────────┐         ┌─────────────┐
                    │  Warn &  │         │  Generate   │
                    │ Continue │         │  Requests   │
                    └──────────┘         └─────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────┐
                    │      Execute Test Requests      │
                    │  • Health checks (10%)          │
                    │  • Predict no image (60%)       │
                    │  • Predict with image (20%)     │
                    │  • Predict large image (10%)    │
                    └─────────────────────────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────┐
                    │      Collect Metrics            │
                    │  • Response times               │
                    │  • Success/failure rates        │
                    │  • Throughput (RPS)             │
                    │  • Percentiles (P50/P95/P99)    │
                    └─────────────────────────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────┐
                    │      Check Thresholds           │
                    │  • Max failure rate: 1%         │
                    │  • Max P95 time: 2.0s           │
                    │  • Max P99 time: 5.0s           │
                    │  • Min RPS: 10                  │
                    └─────────────────────────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────┐
                    │      Generate Report            │
                    │  • Console output               │
                    │  • HTML report (optional)       │
                    │  • CSV data (optional)          │
                    └─────────────────────────────────┘
```

## Request Types

### 1. Health Check (10% of traffic)
```
GET /health
Response: {"status": "ok"}
```

### 2. Predict - No Image Return (60% of traffic)
```
POST /predict?return_image=false
Body: multipart/form-data (640x480 image)
Response: {"predictions": [...]}
```

### 3. Predict - With Image Return (20% of traffic)
```
POST /predict?return_image=true
Body: multipart/form-data (640x480 image)
Response: {
  "predictions": [...],
  "image": "base64_encoded_annotated_image"
}
```

### 4. Predict - Large Image (10% of traffic)
```
POST /predict?return_image=false
Body: multipart/form-data (1920x1080 image)
Response: {"predictions": [...]}
```

## Deployment Options

### Option 1: Local Execution
```bash
cd stress-test
pip install -r requirements.txt
./run_stress_test.sh --env local --profile quick
```

### Option 2: Docker Container
```bash
docker build -t yolo-stress-test .
docker run -p 8089:8089 yolo-stress-test
```

### Option 3: Docker Compose
```bash
docker-compose up -d
```

### Option 4: Kubernetes (future)
```bash
kubectl apply -f k8s/stress-test-job.yaml
```

## Metrics & Reporting

### Console Output
```
==============================
BENCHMARK RESULTS
==============================
Total requests: 500
Successful: 498
Failed: 2
Success rate: 99.60%
Requests/second: 27.10

Response times:
  P50: 0.398s
  P95: 0.892s
  P99: 1.234s

Threshold Checks:
  ✓ PASS - All thresholds met
==============================
```

### HTML Report (Locust)
- Interactive charts
- Request statistics table
- Response time distribution
- Failure breakdown
- Download/export options

### CSV Export (Locust)
- `*_stats.csv` - Request statistics
- `*_stats_history.csv` - Time series data
- `*_failures.csv` - Error details

## Integration Points

```
┌─────────────────┐
│   CI/CD Pipeline│
│  (GitHub Actions)│
└────────┬────────┘
         │
         ▼
  ┌─────────────────┐        ┌──────────────┐
  │  Deploy Backend │───────▶│ Run Smoke    │
  │  to Staging     │        │ Test         │
  └─────────────────┘        └──────┬───────┘
                                    │
                             PASS?  │  FAIL?
                                    │
         ┌──────────────────────────┼────────┐
         │                                   │
         ▼                                   ▼
  ┌─────────────┐                    ┌─────────────┐
  │  Run Load   │                    │  Fail Build │
  │  Test       │                    │  & Rollback │
  └──────┬──────┘                    └─────────────┘
         │
         ▼
  ┌─────────────┐
  │  Generate   │
  │  Report     │
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Archive    │
  │  Results    │
  └─────────────┘
```

## Best Practices

1. **Progressive Testing**
   ```
   smoke → quick → standard → load → stress
   ```

2. **Environment Isolation**
   - Never test production directly
   - Use dedicated test environments
   - Mirror production config

3. **Monitoring During Tests**
   - Backend CPU/Memory usage
   - Network bandwidth
   - Error logs
   - Database connections

4. **Cool-down Periods**
   - Wait between tests
   - Allow system to stabilize
   - Clear caches if needed

5. **Baseline Establishment**
   - Run tests regularly
   - Track trends over time
   - Set realistic thresholds
   - Alert on degradation
