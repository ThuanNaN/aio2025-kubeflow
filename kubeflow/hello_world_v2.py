from kfp import dsl
from kfp import compiler

# Define a simple component using a Python function
@dsl.component
def say_hello(name: str) -> str:
    """A simple component that says hello to a given name."""
    hello_text = f'Hello, {name}!'
    print(hello_text)
    return hello_text

@dsl.component
def say_goodbye(name: str) -> str:
    """A simple component that says goodbye to a given name."""
    goodbye_text = f'Goodbye, {name}!'
    print(goodbye_text)
    return goodbye_text

# Define the pipeline using the @dsl.pipeline decorator
@dsl.pipeline(
    name="hello-world-pipeline",
    description="A basic pipeline that prints a greeting."
)
def hello_pipeline(recipient: str = "World"):
    """This pipeline runs the say_hello component."""
    hello_task = say_hello(name=recipient)
    goodbye_task = say_goodbye(name=recipient)

if __name__ == "__main__":
    # Compile the pipeline into a YAML file
    compiler.Compiler().compile(hello_pipeline, 'hello_world_v2_pipeline.yaml')

