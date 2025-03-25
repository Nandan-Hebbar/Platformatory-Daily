import asyncio
from temporalio import workflow
from temporalio.client import Client
from temporalio.worker import Worker
from hello_workflow import HelloWorldWorkflow

async def main():
    # Connect to the Temporal server
    client = await Client.connect("localhost:7233")

    # Start a worker to run the workflow
    worker = Worker(
        client,
        task_queue="hello-task-queue",
        workflows=[HelloWorldWorkflow],
    )

    print("Worker started.")
    await worker.run()

if __name__ == "__main__":
    asyncio.run(main())