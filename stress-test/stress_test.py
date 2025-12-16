"""
Stress test for the YOLO backend API using Locust.
Supports multiple environments and test profiles.

Usage:
    # Interactive mode with web UI
    locust -f stress_test.py --host=http://localhost:8000
    
    # Headless mode
    locust -f stress_test.py --host=http://localhost:8000 --headless -u 10 -r 2 -t 60s
    
    # Using the helper script
    ./run_stress_test.sh --env local --profile standard
"""

from locust import HttpUser, task, between, events
import io
import os
import yaml
import random
import glob
from PIL import Image
import numpy as np
from pathlib import Path


# Load configuration
config_path = Path(__file__).parent / "config.yaml"
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# Load available images from val2014 directory
VAL2014_DIR = Path(__file__).parent.parent / "val2014"
if VAL2014_DIR.exists():
    IMAGE_POOL = glob.glob(str(VAL2014_DIR / "*.jpg"))
    print(f"Loaded {len(IMAGE_POOL)} images from {VAL2014_DIR}")
else:
    IMAGE_POOL = []
    print(f"Warning: {VAL2014_DIR} not found, will generate synthetic images")


def create_test_image(width=640, height=480):
    """Load a random image from val2014 or create a synthetic one."""
    if IMAGE_POOL:
        # Use a random real image from val2014
        img_path = random.choice(IMAGE_POOL)
        img = Image.open(img_path)
        
        # Resize if dimensions are specified and different
        if width and height and (img.size[0] != width or img.size[1] != height):
            img = img.resize((width, height), Image.LANCZOS)
        
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG', quality=95)
        img_bytes.seek(0)
        return img_bytes
    else:
        # Fallback to synthetic image generation
        img_array = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)
        img = Image.fromarray(img_array)
        
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        return img_bytes


class YOLOAPIUser(HttpUser):
    """Simulates a user interacting with the YOLO API."""
    
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a simulated user starts."""
        # Optional: perform any initialization
        self.image_sizes = config.get('image_sizes', {
            'small': [640, 480],
            'medium': [1280, 720],
            'large': [1920, 1080]
        })
    
    @task(10)  # Weight: 10
    def health_check(self):
        """Test the health endpoint."""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed with status {response.status_code}")
    
    @task(60)  # Weight: 60
    def predict_without_image(self):
        """Test the predict endpoint without returning annotated image."""
        width, height = self.image_sizes['small']
        img_bytes = create_test_image(width, height)
        
        with self.client.post(
            "/predict",
            files={"file": ("test_image.jpg", img_bytes, "image/jpeg")},
            params={"return_image": False},
            catch_response=True,
            name="/predict?return_image=False"
        ) as response:
            if response.status_code == 200:
                try:
                    json_response = response.json()
                    if "predictions" in json_response:
                        response.success()
                    else:
                        response.failure("Response missing 'predictions' field")
                except Exception as e:
                    response.failure(f"Failed to parse JSON: {str(e)}")
            else:
                response.failure(f"Predict failed with status {response.status_code}")
    
    @task(20)  # Weight: 20
    def predict_with_image(self):
        """Test the predict endpoint with annotated image return."""
        width, height = self.image_sizes['small']
        img_bytes = create_test_image(width, height)
        
        with self.client.post(
            "/predict",
            files={"file": ("test_image.jpg", img_bytes, "image/jpeg")},
            params={"return_image": True},
            catch_response=True,
            name="/predict?return_image=True"
        ) as response:
            if response.status_code == 200:
                try:
                    json_response = response.json()
                    if "predictions" in json_response:
                        response.success()
                    else:
                        response.failure("Response missing 'predictions' field")
                except Exception as e:
                    response.failure(f"Failed to parse JSON: {str(e)}")
            else:
                response.failure(f"Predict failed with status {response.status_code}")
    
    @task(10)  # Weight: 10
    def predict_large_image(self):
        """Test the predict endpoint with larger images."""
        width, height = self.image_sizes['large']
        img_bytes = create_test_image(width, height)
        
        with self.client.post(
            "/predict",
            files={"file": ("test_large_image.jpg", img_bytes, "image/jpeg")},
            params={"return_image": False},
            catch_response=True,
            name="/predict (large image)"
        ) as response:
            if response.status_code == 200:
                try:
                    json_response = response.json()
                    if "predictions" in json_response:
                        response.success()
                    else:
                        response.failure("Response missing 'predictions' field")
                except Exception as e:
                    response.failure(f"Failed to parse JSON: {str(e)}")
            else:
                response.failure(f"Predict failed with status {response.status_code}")


@events.init_command_line_parser.add_listener
def _(parser):
    """Add custom command line arguments."""
    parser.add_argument("--env", type=str, default="local",
                       help="Environment to test (local, docker, kubernetes, staging, production)")
    parser.add_argument("--profile", type=str,
                       help="Test profile (smoke, quick, standard, load, spike, endurance, stress)")


@events.test_start.add_listener
def _(environment, **kwargs):
    """Event handler for test start."""
    env_name = environment.parsed_options.env if hasattr(environment, 'parsed_options') else 'unknown'
    env_config = config['environments'].get(env_name, {})
    
    print("=" * 70)
    print("YOLO Backend API - Stress Test")
    print("=" * 70)
    print(f"Environment: {env_name}")
    if env_config:
        print(f"Description: {env_config.get('description', 'N/A')}")
        print(f"Target URL: {env_config.get('url', environment.host)}")
    else:
        print(f"Target URL: {environment.host}")
    print(f"Users: {environment.runner.target_user_count if hasattr(environment.runner, 'target_user_count') else 'N/A'}")
    print("=" * 70)


@events.test_stop.add_listener
def _(environment, **kwargs):
    """Event handler for test stop."""
    print("\n" + "=" * 70)
    print("Stress Test Completed")
    print("=" * 70)
    
    # Check thresholds if configured
    stats = environment.stats
    thresholds = config.get('thresholds', {})
    
    if thresholds and stats.total.num_requests > 0:
        print("\nThreshold Checks:")
        
        failure_rate = stats.total.num_failures / stats.total.num_requests
        max_failure_rate = thresholds.get('max_failure_rate', 0.01)
        status = "✓ PASS" if failure_rate <= max_failure_rate else "✗ FAIL"
        print(f"  Failure Rate: {failure_rate:.2%} (max: {max_failure_rate:.2%}) {status}")
        
        if hasattr(stats.total, 'get_response_time_percentile'):
            p95 = stats.total.get_response_time_percentile(0.95) / 1000
            max_p95 = thresholds.get('max_p95_response_time', 2.0)
            status = "✓ PASS" if p95 <= max_p95 else "✗ FAIL"
            print(f"  P95 Response Time: {p95:.3f}s (max: {max_p95}s) {status}")
            
            p99 = stats.total.get_response_time_percentile(0.99) / 1000
            max_p99 = thresholds.get('max_p99_response_time', 5.0)
            status = "✓ PASS" if p99 <= max_p99 else "✗ FAIL"
            print(f"  P99 Response Time: {p99:.3f}s (max: {max_p99}s) {status}")
        
        if hasattr(stats.total, 'total_rps'):
            rps = stats.total.total_rps
            min_rps = thresholds.get('min_requests_per_second', 10)
            status = "✓ PASS" if rps >= min_rps else "✗ FAIL"
            print(f"  Requests/Second: {rps:.2f} (min: {min_rps}) {status}")
    
    print("=" * 70)
