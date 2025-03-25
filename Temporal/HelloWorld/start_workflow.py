import asyncio
from temporalio.client import Client
from hello_workflow import HelloWorldWorkflow

async def main():
    client = await Client.connect("localhost:7233")

    result = await client.execute_workflow(
        HelloWorldWorkflow.run,
        "Temporal",
        id="hello-workflow-1",
        task_queue="hello-task-queue",
    )

    print(f"Workflow result: {result}")

if __name__ == "__main__":
    asyncio.run(main())