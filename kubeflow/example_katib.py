from kubeflow import katib

# kubectl delete experiment mnist-hpo -n kubeflow-user-example-com
def train_mnist(parameters):
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
    from torchvision import datasets, transforms
    from torch.utils.data import DataLoader
    
    # Get hyperparameters
    lr = float(parameters["learning_rate"])
    batch_size = int(parameters["batch_size"])
    epochs = 3
    
    print(f"Training with lr={lr}, batch_size={batch_size}")
    
    # Model
    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.fc1 = nn.Linear(784, 128)
            self.fc2 = nn.Linear(128, 10)
        
        def forward(self, x):
            x = x.view(-1, 784)
            x = F.relu(self.fc1(x))
            return F.log_softmax(self.fc2(x), dim=1)
    
    model = Net()
    
    # Data
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    
    train_dataset = datasets.MNIST('./data', train=True, download=True, transform=transform)
    train_dataset = torch.utils.data.Subset(train_dataset, range(1000))  # Subset for speed
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    
    # Training
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    
    for epoch in range(epochs):
        model.train()
        correct = 0
        total = 0
        
        for data, target in train_loader:
            optimizer.zero_grad()
            output = model(data)
            loss = F.nll_loss(output, target)
            loss.backward()
            optimizer.step()
            
            pred = output.argmax(dim=1)
            correct += pred.eq(target).sum().item()
            total += target.size(0)
        
        accuracy = 100. * correct / total
        print(f"Epoch {epoch+1}: accuracy={accuracy:.2f}")
    
    # CRITICAL: Print final metric for Katib
    print(f"accuracy={accuracy:.2f}")


# Search space
parameters = {
    "learning_rate": katib.search.double(min=0.001, max=0.1, step=0.001),
    "batch_size": katib.search.int(min=16, max=128, step=16),
}

# Submit experiment
client = katib.KatibClient(namespace="kubeflow-user-example-com")
client.tune(
    name="mnist-hpo",
    objective=train_mnist,
    parameters=parameters,
    objective_metric_name="accuracy",
    objective_type="maximize",  # Maximize accuracy
    max_trial_count=10,
    parallel_trial_count=2,
    resources_per_trial={
        "cpu": "500m",  # Reduced from 1 CPU to 0.5 CPU
        "memory": "1Gi"  # Reduced from 2Gi to 1Gi
    }
)

print("\nWaiting for Experiment to complete...")
try:
    # Wait with timeout
    client.wait_for_experiment_condition(
        name="mnist-hpo",
        namespace="kubeflow-user-example-com",
        timeout=300 
    )
    
    print("\nBest hyperparameters:")
    print(client.get_optimal_hyperparameters("mnist-hpo"))
    
except Exception as e:
    print(f"\nError while waiting for experiment: {e}")
    
    # Get detailed information about experiment
    print("\nChecking experiment status:")
    try:
        exp = client.get_experiment(name="mnist-hpo", namespace="kubeflow-user-example-com")
        print(f"\nStatus: {exp.status}")
        
        # Check trials
        trials = client.list_trials(experiment_name="mnist-hpo", namespace="kubeflow-user-example-com")
        print(f"\nNumber of trials: {len(trials)}")
        
        if len(trials) == 0:
            print("\nNo trials were created!")
            print("Possible reasons:")
            print("  - Missing permissions to create Kubernetes Jobs")
            print("  - Container image does not exist")
            print("  - Insufficient resources in cluster")
            print("\nCheck Katib controller logs:")
            print("  kubectl logs -n kubeflow-user-example-com -l katib.kubeflow.org/experiment=mnist-hpo")
    except Exception as detail_error:
        print(f"Cannot get detailed information: {detail_error}")