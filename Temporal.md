Key Concepts of Temporal.io
Temporal is a workflow orchestration platform designed for building scalable, durable, and reliable applications. It enables developers to manage long-running, stateful, and fault-tolerant workflows.

In short, Temporal is a platform that guarantees the durable execution of your application code. It allows you to develop as if failures don't even exist. Your application will run reliably even if it encounters problems, such as network outages or server crashes, which would be catastrophic for a typical application. The Temporal platform handles these types of problems, allowing you to focus on the business logic, instead of writing application code to detect and recover from failures.


1. Temporal’s Core Components

1.1. Workflows (Durable Execution)
A workflow is a durable function that runs application logic. Unlike traditional microservices, workflows automatically persist state and can resume execution after failures.

📌 Key Features:

Deterministic execution (replays from history)
Handles failures automatically
Can run for days, months, or even years
✅ Example: Processing an order, handling a subscription renewal, etc.




1.2. Activities (External Actions)
An activity is a single unit of work performed outside the workflow, such as calling an API, sending an email, or updating a database.

📌 Key Features:

Can fail and be retried automatically
Non-deterministic (unlike workflows)
Runs on separate worker nodes
✅ Example: Sending an email, processing payments, interacting with external APIs




1.3. Workers (Code Execution Units)
A worker is a service that runs workflows and activities. It pulls tasks from Temporal’s task queues and executes them.

📌 Key Features:

Scalable & distributed
Can be written in multiple languages (Go, Java, Python, TypeScript, etc.)
Responsible for executing workflow and activity logic
✅ Example: A worker executing an activity to generate invoices.




1.4. Task Queues (Routing System)
Task queues allow workflows to send tasks to workers. Workflows push activities into task queues, and workers poll these queues to execute the activities.

📌 Key Features:

Decouples workflows from workers
Supports horizontal scaling
Ensures tasks are executed only once
✅ Example: A "payment-processing" queue where workers pick up payment-related activities.




1.5. Signals (External Event Triggers)
A signal is an external event that modifies a running workflow.

📌 Key Features:

Used to send real-time updates
Workflows can wait for signals before proceeding
✅ Example: A user cancels an order, and a signal tells the workflow to stop processing.




1.6. Queries (Retrieve Workflow State)
A query retrieves the current state of a running workflow without modifying it.

📌 Key Features:

Fast, read-only operations
Does not alter workflow execution
✅ Example: Checking the current status of an ongoing data-processing job.







2. Temporal’s Execution Model
How It Works:
A client starts a workflow (e.g., "Process Order").
The workflow schedules activities (e.g., "Charge Payment," "Send Email").
Workers pull activity tasks from task queues and execute them.
If an activity fails, Temporal automatically retries it.
Workflows continue execution even after restarts, crashes, or deployments.
🔁 Temporal ensures workflows always complete, no matter what happens.






3. Why Use Temporal?
✅ Fault Tolerance: Handles failures automatically (retries, state persistence).
✅ Scalability: Distributes tasks across workers.
✅ Durability: Workflows can run for months or years without losing state.
✅ Observability: Tracks workflow state and execution history.
✅ Language Support: Works with Go, Java, Python, and TypeScript.




Several workflow orchestration and stateful execution platforms are similar to Temporal.io. Here are some notable alternatives:

1. Apache Airflow
🔹 Popular for Data Pipelines & ETL Workflows

📌 Key Differences:

Airflow is batch-oriented, while Temporal is designed for long-running, stateful workflows.
Airflow uses DAGs (Directed Acyclic Graphs), while Temporal has event-driven workflows.
Airflow tasks don’t survive process restarts, whereas Temporal persists workflow state indefinitely.
✅ Best for: Data engineering, ETL pipelines, and ML workflows.

2. Netflix Conductor
🔹 A microservices orchestration engine used by Netflix.

📌 Key Differences:

More declarative than Temporal (uses JSON/YAML for workflow definitions).
Better suited for microservices orchestration, whereas Temporal is more general-purpose.
Less developer-friendly SDKs than Temporal.
✅ Best for: Companies with microservices-heavy architectures.




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




Basic Temporal CLI Commands

The following are some of the most commonly used Temporal CLI command sets:
    *temporal activity
    *temporal batch
    *temporal env
    *temporal operator
    *temporal schedule
    *temporal server
    *temporal task-queue
    *temporal workflow

1) Workflow Commands

Cancel
temporal workflow cancel --workflow-id=meaningful-business-id

Count
temporal workflow count #count total workflows
temporal workflow count --namespace default #count the number of workflows within a namespace

Delete
temporal workflow delete --workflow-id sample-workflow

Describe
Describe a workflow
temporal workflow describe --workflow-id greeting-workflow
-->must specify workflow id

Execute
temporal workflow execute --workflow-id=meaningful-business-id --type-MyWorkflow --task-queue-MyTaskQueue --input='{"JSON": "Input"}'

List
temporal workflow list

Query
temporal workflow query --workflow-id=products-workflow --type=get_product_count

Reset
A reset resumes the Workflow from a certain point without losing your parameters or Event History.
temporal workflow reset --workflow-id=products-workflow --type=LastWorkflowTask --reason=trial
typeis one of these values FirstWorkflowTask, LastWorkflowTask, LastContinuedAsNew, BuildId
Required flag --reason

reset-batch
The temporal workflow reset-batch command resets multiple Workflow Executions by resetType
temporal workflow reset-batch --input-file=MyInput --input-separator="\t"

show
The temporal workflow show command provides the Event History for a Workflow Execution.
temporal workflow show --workflow-id=products-workflow

signal
temporal workflow signal --workflow-id products-workflow --name update_products --input 532

stack
The temporal workflow stack command queries a Workflow Execution with --stack-trace as the Query type.
temporal workflow stack --workflow-id=products-workflow
[worker should be running to execute this command]

start
temporal workflow start --task-queue products-tasks --type ProductsLeft --workflow-id products-workflow --input 456

terminate
temporal workflow terminate --workflow-id products-workflow

trace
The temporal workflow trace command tracks the progress of a Workflow Execution and any Child Workflows it generates.
temporal workflow trace --workflow-id products-workflow

update
Available Commands:
  describe    Obtain status info about a specific Update (Experimental)
  execute     Send an Update and wait for it to complete (Experimental)
  result      Wait for a specific Update to complete (Experimental)
  start       Send an Update and wait for it to be accepted or rejected (Experimental)
temporal workflow update start --workflow-id products-workflow --input 60
temporal workflow update start --workflow-id products-workflow --name first-update --wait-for-stage accepted

2) Activty Commands

complete
The temporal activity complete command completes an Activity Execution.
temporal activity complete --workflow-id greeting-workflow --activity-id 1 --result "\"ActivityComplete\""

fail
The temporal activity fail command fails an Activity Execution. 
temporal activity fail --workflow-id greeting-workflow --activity-id 1

3) Task Queue Commands

describe
temporal task-queue describe --task-queue=greeting-activities --task-queue-type="activity"
temporal task-queue describe --task-queue=greeting-activities

list-partitions
temporal task-queue list-partition --task-queue=qreeting-activities

get-build-ids
temporal task-queue get-build-ids --task-queue=qreeting-activities

get-build-id-reachability
temporal task-queue get-build-id-reachability --task-queue=qreeting-activities

4) Server Commands

temporal server start-dev
temporal server start-dev --headless
temporal server start-dev --ui-port 8080
temporal server start-dev --db-filename temporal_data.db

5) Batch Commands
To run batch commands, first create batch jobs
There are three types of Batch Jobs:
    Cancel: cancels the Workflow Executions specified by the List Filter.
    Signal: sends a Signal to the Workflow Executions specified by the List Filter.
    Terminate: terminates the Workflow Executions specified by the List Filter.

To Cancel Workflows:
temporal workflow cancel \
  --query 'ExecutionStatus = "Running" AND WorkflowType="ProductsLeft"' \
  --reason "Testing"

To Signal Workflows:
temporal workflow signal \
  --name update_products \
  --input 54 \
  --query 'ExecutionStatus = "Running" AND WorkflowType="ProductsLeft"' \
  --reason "Testing"

temporal workflow signal \
  --workflow-id products-workflow \
  --name update_products \
  --input 48

To Terminate Workflows:
temporal workflow terminate \
  --query 'ExecutionStatus = "Running" AND WorkflowType="ProductsLeft"' \
  --reason "Testing"

A successfully started Batch job will return a Job ID. Use this Job ID to execute other actions on the Batch job. 

list
temporal batch list --namespace=default

describe
temporal batch describe --job-id=99871585-0efe-40e0-bd73-820332ce0cac

terminate
temporal batch terminate --job-id=99871585-0efe-40e0-bd73-820332ce0cac --reason=JobReason

6) Schedule Commands

Create Schedule
temporal schedule create \
    --schedule-id 'first-schedule' \
    --interval '5m' \
    --calendar '{"dayOfWeek":"Mon","hour":"7","minute":"44"}' \
    --overlap-policy 'BufferAll' \
    --workflow-id 'products-workflow' \
    --task-queue 'products-tasks' \
    --type 'ProductsLeft' \
    --input 16

Delete Schedule
temporal schedule delete --schedule-id 'first-schedule'

Describe Schedule
temporal schedule describe --schedule-id 'first-schedule'

List schedules
temporal schedule list

toggle
The temporal schedule toggle command can pause and unpause a Schedule.
temporal schedule toggle --schedule-id 'first-schedule' --pause --reason "paused because of trial 1" 
temporal schedule toggle --schedule-id 'your-schedule-id' --unpause --reason "unpaused because of trial 1"

trigger
The temporal schedule trigger command triggers an immediate action with a given Schedule.
temporal schedule trigger --schedule-id 'first-schedule'

Update
Updating a Schedule takes the given options and replaces the entire configuration of the Schedule with what's provided
temporal schedule update 			    \
    --schedule-id 'first-schedule' 	\
    --workflow-id 'products-workflow' 	\
    --task-queue 'products-tasks' 		\
    --workflow-type 'ProductsLeft'  \
    --input 20

Updating a Schedule takes the given options and replaces the entire configuration of the Schedule with what's provided

7) Operator Commands

Describe
temporal operator cluster describe

health
The temporal operator cluster health command checks the health of the Frontend Service.
temporal operator cluster health

list
temporal operator cluster list

remove
temporal operator cluster remove --name=SomeCluster

system
The temporal operator cluster system command provides information about the system the Cluster is running on.
temporal operator cluster system

upsert

The temporal operator cluster upsert command allows the user to add or update a remote Cluster. 

create namespace
temporal operator namespace create command creates a new Namespace. The Namespace can be created on the active Cluster, or any named Cluster within the system. temporal operator namespace --cluster=MyCluster
temporal operator namespace create trial
To create namespace with certain retention period,
temporal operator namespace create --namespace="my-namespace" --global+false --history-archival-state="enabled" --retention="4d"

delete namespace
temporal operator namespace delete trial1

describe namespace
temporal operator namespace describe --namespace=my-namespace

list namespace
temporal operator namespace list

update namespace
temporal operator namespace update --namespace="my-namespace" --retention="5d"

8) env commands
temporal env get




Advanced Temporal CLI Usage

Some of the advanced temporal CLI usages are
1) Terminate Workflows
temporal workflow terminate --workflow-id products-workflow
2) Cancel Worflows
temporal workflow cancel --workflow-id products-workflow
3) Signal Workflows
temporal workflow signal --workflow-id products-workflow --name update_products --input 532
4) Query Workflows
temporal workflow query --workflow-id=products-workflow --type=get_product_count
5) Modify namespace configurations
temporal operator namespace update --namespace="my-namespace" --retention="5d"






--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



Temporal Hello world program

Create a file hello_workflow.py and add the following:


from temporalio import workflow

@workflow.defn
class HelloWorldWorkflow:
    @workflow.run
    async def run(self, name: str) -> str:
        return f"Hello, {name}!"




Create another file worker.py and add:

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





Create a file start_workflow.py and add:

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




To run this

Step 1: Start Temporal Server
--> temporal server start-dev


Step 2: Start the Worker
-->python worker.py


Step 3: Execute the Workflow
-->python start_workflow.py








To run this using the temporal commands on CLI


temporal workflow start \
>     --task-queue hello-task-queue \
>     --type HelloWorldWorkflow \
>     --workflow-id hello-workflow-cli \
>     --input '"Temporal"'


Note 
'"Temporal"'  -is used to specify the string in json format. While running the workflow programatically, it is not required to pass the input string in
json format because it converts it by default 

-Check Workflow Status
temporal workflow show --workflow-id hello-workflow-cli



-Get Workflow Result

temporal workflow result --workflow-id hello-workflow-cli

If everything is working correctly, this should return:
Hello, Temporal!




-List All Workflows

If you want to see all workflows (running or completed), use:

temporal workflow list




Stop Workflow (Optional)
If you need to terminate or cancel the workflow, use:

Terminate:

temporal workflow terminate --workflow-id hello-workflow-cli



Cancel:

temporal workflow cancel --workflow-id hello-workflow-cli




Writing a Workflow Definition
There are three steps for turning a Python function into a Workflow Definition:
    1) Import the workflow module from the SDK
    2) Add the @workflow.defn decorator to the class that will define the Workflow Definition
    3) Add the @workflow.run decorator to the function that defines the Workflow Function


Input Parameters and Return Values
    1) Values Must Be Serializable
            Temporal workflows are stateful, and all data passed between them must be serializable because Temporal stores workflow states.
            Temporal mainly uses protobuf or JSON for data serialization.
            You cannot pass complex objects, database connections, or non-serializable types.
    2) Data Confidentiality
            Workflow inputs and outputs are stored in the Temporal database.
            Avoid passing sensitive data (e.g., passwords, personal data) directly.
            If required, encrypt sensitive data before passing it into the workflow.
    3) Avoid Passing Large Amounts of Data
            Workflows store state in the Temporal database, and large amounts of data increase storage and performance overhead.
            Instead of passing large datasets, store them in a database or file storage (e.g., S3) and pass a reference (ID, URL, or key).



Two ways of running
1. Asynchronous 
2. Synchronous



Asynchronous

First, let's look at how async event loops work in Python. The Python async event loop runs in a thread and executes all tasks in its thread. When any task is 
running in the event loop, the loop is blocked and no other tasks can be running at the same time within that event loop. Whenever a task executes an await
expression, the task is suspended, and the event loop begins or resumes execution of another task.

In this example, the Activity supplies the name in the URL and retrieves the greeting from the body of the response.

import aiohttp
import urllib.parse
from temporalio import activity


class TranslateActivities:
    def __init__(self, session: aiohttp.ClientSession):
        self.session = session

    @activity.defn
    async def greet_in_spanish(self, name: str) -> str:
        greeting = await self.call_service("get-spanish-greeting", name)
        return greeting

    # Utility method for making calls to the microservices
    async def call_service(self, stem: str, name: str) -> str:
        base = f"http://localhost:9999/{stem}"
        url = f"{base}?name={urllib.parse.quote(name)}"

        async with self.session.get(url) as response:
            translation = await response.text()

            if response.status >= 400:
                raise ApplicationError(
                    f"HTTP Error {response.status}: {translation}",
                    # We want to have Temporal automatically retry 5xx but not 4xx
                    non_retryable=response.status < 500,
                )

            return translation





Synchronous


The following code is an implementation of the above Activity, but as a synchronous Activity Definition. When making the call to the microservice, you'll 
notice that it uses the requests library. This is safe to do in synchronous Activities.


import urllib.parse
import requests
from temporalio import activity


class TranslateActivities:

    @activity.defn
    def greet_in_spanish(self, name: str) -> str:
        greeting = self.call_service("get-spanish-greeting", name)
        return greeting

    # Utility method for making calls to the microservices
    def call_service(self, stem: str, name: str) -> str:
        base = f"http://localhost:9999/{stem}"
        url = f"{base}?name={urllib.parse.quote(name)}"

        response = requests.get(url)
        return response.text




When Should You Use Async Activities

Asynchronous Activities have many advantages, such as potential speed up of execution. However, as discussed above, making unsafe calls within the async event 
loop can cause sporadic and difficult to diagnose bugs. For this reason, we recommend using asynchronous Activities only when you are certain that your 
Activities are async safe and don't make blocking calls.

If you experience bugs that you think may be a result of an unsafe call being made in an asynchronous Activity, convert it to a synchronous Activity and see 
if the
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



How Temporal Handles Activity Failure
Default Behavior
Temporal's default behavior is to automatically retry an Activity, with a short delay between each attempt, until it either succeeds or is canceled. That means
that intermittent failures require no action on your part. When a subsequent request succeeds, your code will resume as if the failure never occurred. 
However, that behavior may not always be desirable, so Temporal allows you to customize it through a custom Retry Policy.


Changing the Timing and Number of Retry Attempts

Four properties determine the timing and number of retries:

Property	            Description	                                                                    Default Value
initial_interval	    Duration before the first retry	                                                1 second
backoff_coefficient	    Multiplier used for subsequent retries	                                        2.0
maximum_interval	    Maximum duration between retries	                                            100 * initial_interval
maximum_attempts	    Maximum number of retry attempts before giving up	                            0 (unlimited)




The initial_interval property defines how long after the initial failure the first retry will occur. By default, that's one second.

The backoff_coefficient is a multiplier, applied to the initial_interval value, that's used to calculate the delay between each subsequent attempt. Assuming 
that you use the defaults for both properties, that means there will be a retry after 1 second, another after 2 seconds, then 4 seconds, 8 seconds and so on.

The maximum_interval puts a limit on that delay, and by default it's 100 times the initial interval, which means that the delays would keep increasing as 
described, but would never exceed 100 seconds.


Finally, the maximum_attempts specified the maximum count of retries allowed before marking the Activity as failed, in which case the Workflow can handle the 
failure according to its business logic.









