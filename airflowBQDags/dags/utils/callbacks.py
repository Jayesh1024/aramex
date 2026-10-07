import google.cloud.logging

gcp_logging_client = google.cloud.logging.Client()
gcp_logger = gcp_logging_client.logger("airflow-dag-failures")


def on_task_failure(context: dict): #Airflow generated dictionary object -> context
    task_instance = context.get("task_instance")
    exception = context.get("exception")

    gcp_logger.log_struct(
        {
            "message": f"Task failed: {task_instance.task_id}",
            "dag_id": task_instance.dag_id,
            "task_id": task_instance.task_id,
            "run_id": task_instance.run_id,
            "execution_date": str(context.get("execution_date")),
            "log_url": task_instance.log_url,
            "error": str(exception),
        },
        severity="ERROR"
    )
