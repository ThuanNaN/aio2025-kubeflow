"""
Async benchmark tool for YOLO backend API.
Supports multiple environments and test profiles from config.yaml.

Usage:
    python benchmark_async.py --env local --profile quick
    python benchmark_async.py --url http://custom-url:8000 --concurrent 20 --requests 500
"""

import asyncio
import aiohttp
import argparse
import time
import io
import statistics
import yaml
from PIL import Image
import numpy as np
from typing import List, Dict
from dataclasses import dataclass
from pathlib import Path


@dataclass
class BenchmarkResult:
    """Results from a single request."""
    endpoint: str
    status_code: int
    response_time: float
    success: bool
    error: str = None


def load_config():
    """Load configuration from config.yaml."""
    config_path = Path(__file__).parent / "config.yaml"
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def create_test_image(width=640, height=480) -> bytes:
    """Create a random test image for upload."""
    img_array = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)
    img = Image.fromarray(img_array)
    
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    return img_bytes.getvalue()


async def test_health(session: aiohttp.ClientSession, base_url: str) -> BenchmarkResult:
    """Test the /health endpoint."""
    start_time = time.time()
    try:
        async with session.get(f"{base_url}/health", timeout=aiohttp.ClientTimeout(total=30)) as response:
            await response.read()
            response_time = time.time() - start_time
            return BenchmarkResult(
                endpoint="/health",
                status_code=response.status,
                response_time=response_time,
                success=response.status == 200
            )
    except Exception as e:
        response_time = time.time() - start_time
        return BenchmarkResult(
            endpoint="/health",
            status_code=0,
            response_time=response_time,
            success=False,
            error=str(e)
        )


async def test_predict(
    session: aiohttp.ClientSession,
    base_url: str,
    return_image: bool = False,
    image_size: tuple = (640, 480)
) -> BenchmarkResult:
    """Test the /predict endpoint."""
    start_time = time.time()
    endpoint = f"/predict?return_image={return_image}"
    
    try:
        img_data = create_test_image(width=image_size[0], height=image_size[1])
        
        data = aiohttp.FormData()
        data.add_field('file',
                      img_data,
                      filename='test.jpg',
                      content_type='image/jpeg')
        
        async with session.post(
            f"{base_url}{endpoint}",
            data=data,
            timeout=aiohttp.ClientTimeout(total=60)
        ) as response:
            await response.read()
            response_time = time.time() - start_time
            return BenchmarkResult(
                endpoint=endpoint,
                status_code=response.status,
                response_time=response_time,
                success=response.status == 200
            )
    except Exception as e:
        response_time = time.time() - start_time
        return BenchmarkResult(
            endpoint=endpoint,
            status_code=0,
            response_time=response_time,
            success=False,
            error=str(e)
        )


async def run_benchmark(
    base_url: str,
    concurrent_users: int,
    total_requests: int,
    test_mix: Dict[str, float] = None,
    image_sizes: Dict = None
) -> List[BenchmarkResult]:
    """Run the benchmark with specified parameters."""
    
    config = load_config()
    
    if test_mix is None:
        test_mix_config = config.get('test_mix', {})
        test_mix = {
            "health": test_mix_config.get('health_check', 0.1),
            "predict_no_image": test_mix_config.get('predict_no_image', 0.6),
            "predict_with_image": test_mix_config.get('predict_with_image', 0.2),
            "predict_large": test_mix_config.get('predict_large_image', 0.1)
        }
    
    if image_sizes is None:
        image_sizes = config.get('image_sizes', {
            'small': [640, 480],
            'large': [1920, 1080]
        })
    
    # Prepare request distribution
    requests_to_make = []
    for test_type, ratio in test_mix.items():
        count = int(total_requests * ratio)
        requests_to_make.extend([test_type] * count)
    
    # Fill up to total_requests if rounding caused shortage
    while len(requests_to_make) < total_requests:
        requests_to_make.append("predict_no_image")
    
    results = []
    semaphore = asyncio.Semaphore(concurrent_users)
    
    async def make_request(test_type: str):
        async with semaphore:
            async with aiohttp.ClientSession() as session:
                if test_type == "health":
                    return await test_health(session, base_url)
                elif test_type == "predict_no_image":
                    return await test_predict(session, base_url, return_image=False,
                                             image_size=tuple(image_sizes['small']))
                elif test_type == "predict_with_image":
                    return await test_predict(session, base_url, return_image=True,
                                             image_size=tuple(image_sizes['small']))
                elif test_type == "predict_large":
                    return await test_predict(session, base_url, return_image=False,
                                             image_size=tuple(image_sizes['large']))
    
    print(f"\n{'='*70}")
    print("YOLO Backend API - Async Benchmark")
    print(f"{'='*70}")
    print(f"Target URL: {base_url}")
    print(f"Concurrent users: {concurrent_users}")
    print(f"Total requests: {total_requests}")
    print(f"Test distribution: {test_mix}")
    print(f"{'-'*70}")
    
    start_time = time.time()
    
    # Create all tasks
    tasks = [make_request(test_type) for test_type in requests_to_make]
    
    # Run tasks and show progress
    for i, task in enumerate(asyncio.as_completed(tasks), 1):
        result = await task
        results.append(result)
        if i % 10 == 0 or i == len(tasks):
            elapsed = time.time() - start_time
            rps = i / elapsed if elapsed > 0 else 0
            print(f"Progress: {i}/{len(tasks)} requests | {rps:.1f} req/s", end='\r')
    
    total_time = time.time() - start_time
    print(f"\nCompleted: {len(tasks)}/{len(tasks)} requests")
    print(f"{'-'*70}")
    
    # Print summary
    print_summary(results, total_time, load_config())
    
    return results


def print_summary(results: List[BenchmarkResult], total_time: float, config: dict):
    """Print benchmark summary statistics."""
    
    successful_requests = [r for r in results if r.success]
    failed_requests = [r for r in results if not r.success]
    
    print(f"\n{'='*70}")
    print("BENCHMARK RESULTS")
    print(f"{'='*70}")
    
    print(f"\nTotal requests: {len(results)}")
    print(f"Successful: {len(successful_requests)}")
    print(f"Failed: {len(failed_requests)}")
    print(f"Success rate: {len(successful_requests) / len(results) * 100:.2f}%")
    print(f"Total time: {total_time:.2f}s")
    print(f"Requests/second: {len(results) / total_time:.2f}")
    
    if successful_requests:
        response_times = [r.response_time for r in successful_requests]
        print(f"\nResponse times (successful requests):")
        print(f"  Min: {min(response_times):.3f}s")
        print(f"  Max: {max(response_times):.3f}s")
        print(f"  Mean: {statistics.mean(response_times):.3f}s")
        print(f"  Median: {statistics.median(response_times):.3f}s")
        if len(response_times) > 1:
            print(f"  Std Dev: {statistics.stdev(response_times):.3f}s")
        
        # Percentiles
        sorted_times = sorted(response_times)
        p50 = sorted_times[int(len(sorted_times) * 0.50)]
        p90 = sorted_times[int(len(sorted_times) * 0.90)]
        p95 = sorted_times[int(len(sorted_times) * 0.95)]
        p99 = sorted_times[int(len(sorted_times) * 0.99)]
        
        print(f"\nPercentiles:")
        print(f"  50th: {p50:.3f}s")
        print(f"  90th: {p90:.3f}s")
        print(f"  95th: {p95:.3f}s")
        print(f"  99th: {p99:.3f}s")
    
    # Breakdown by endpoint
    endpoints = {}
    for result in results:
        if result.endpoint not in endpoints:
            endpoints[result.endpoint] = []
        endpoints[result.endpoint].append(result)
    
    print(f"\nBreakdown by endpoint:")
    for endpoint, endpoint_results in sorted(endpoints.items()):
        successful = sum(1 for r in endpoint_results if r.success)
        total = len(endpoint_results)
        avg_time = statistics.mean([r.response_time for r in endpoint_results if r.success]) if successful > 0 else 0
        print(f"  {endpoint}")
        print(f"    Requests: {total}, Success: {successful}, Avg time: {avg_time:.3f}s")
    
    # Check thresholds
    thresholds = config.get('thresholds', {})
    if thresholds and successful_requests:
        print(f"\nThreshold Checks:")
        
        failure_rate = len(failed_requests) / len(results)
        max_failure_rate = thresholds.get('max_failure_rate', 0.01)
        status = "✓ PASS" if failure_rate <= max_failure_rate else "✗ FAIL"
        print(f"  Failure Rate: {failure_rate:.2%} (max: {max_failure_rate:.2%}) {status}")
        
        max_p95 = thresholds.get('max_p95_response_time', 2.0)
        status = "✓ PASS" if p95 <= max_p95 else "✗ FAIL"
        print(f"  P95 Response Time: {p95:.3f}s (max: {max_p95}s) {status}")
        
        max_p99 = thresholds.get('max_p99_response_time', 5.0)
        status = "✓ PASS" if p99 <= max_p99 else "✗ FAIL"
        print(f"  P99 Response Time: {p99:.3f}s (max: {max_p99}s) {status}")
        
        rps = len(results) / total_time
        min_rps = thresholds.get('min_requests_per_second', 10)
        status = "✓ PASS" if rps >= min_rps else "✗ FAIL"
        print(f"  Requests/Second: {rps:.2f} (min: {min_rps}) {status}")
    
    if failed_requests:
        print(f"\nFailed requests details:")
        error_counts = {}
        for result in failed_requests:
            error = result.error or f"HTTP {result.status_code}"
            error_counts[error] = error_counts.get(error, 0) + 1
        
        for error, count in sorted(error_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"  {error}: {count} occurrences")
    
    print(f"{'='*70}\n")


def main():
    config = load_config()
    
    parser = argparse.ArgumentParser(description='Async stress test for YOLO API')
    parser.add_argument('--env', type=str, choices=list(config['environments'].keys()),
                       help='Environment to test (from config.yaml)')
    parser.add_argument('--profile', type=str, choices=list(config['test_profiles'].keys()),
                       help='Test profile (from config.yaml)')
    parser.add_argument('--url', type=str,
                       help='Custom API URL (overrides --env)')
    parser.add_argument('--concurrent', '-c', type=int,
                       help='Number of concurrent users (overrides --profile)')
    parser.add_argument('--requests', '-n', type=int,
                       help='Total number of requests (overrides --profile)')
    
    args = parser.parse_args()
    
    # Determine URL
    if args.url:
        base_url = args.url
        print(f"Using custom URL: {base_url}")
    elif args.env:
        env_config = config['environments'][args.env]
        base_url = env_config['url']
        print(f"Using environment '{args.env}': {env_config['description']}")
    else:
        base_url = config['environments']['local']['url']
        print(f"Using default environment (local)")
    
    # Determine test parameters
    if args.profile:
        profile = config['test_profiles'][args.profile]
        concurrent = args.concurrent or profile['users']
        total_requests = args.requests or (profile['users'] * 10)  # Estimate
        print(f"Using profile '{args.profile}': {profile['description']}")
    else:
        concurrent = args.concurrent or 10
        total_requests = args.requests or 100
    
    asyncio.run(run_benchmark(base_url, concurrent, total_requests))


if __name__ == "__main__":
    main()
