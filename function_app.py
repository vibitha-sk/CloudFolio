import os
import azure.functions as func
import logging
import json
from azure.cosmos import CosmosClient, exceptions

# Initialize Cosmos client using environment variables
cosmos_url = os.getenv("CosmosDB_URL")
cosmos_key = os.getenv("CosmosDB_Key")
database_name = os.getenv("CosmosDB_Database")
container_name = os.getenv("CosmosDB_Container")
visitor_count_container_name = os.getenv("VisitorCount_Container")

cosmos_client = CosmosClient(cosmos_url, credential=cosmos_key)
database = cosmos_client.get_database_client(database_name)
container = database.get_container_client(container_name)
visitor_count_container = database.get_container_client(visitor_count_container_name)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="resumeapi")
def resumeapi(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        item_id = req.params.get('id')
        if not item_id:
            return func.HttpResponse("Please pass an id in the query string", status_code=400)

        # Read the resume item from the main container
        item_response = container.read_item(item=item_id, partition_key=item_id)
        basics_section = item_response.get('basics', {})

        # Update visitor count
        visitor_count_item_id = 'visitor_count'
        try:
            visitor_count_item = visitor_count_container.read_item(item=visitor_count_item_id, partition_key=visitor_count_item_id)
            current_count = visitor_count_item.get('count', 0)
        except exceptions.CosmosResourceNotFoundError:
            # If the visitor count item doesn't exist, start the count at 0
            current_count = 0

        new_count = current_count + 1
        visitor_count_item = {'id': visitor_count_item_id, 'count': new_count}
        visitor_count_container.upsert_item(visitor_count_item)

        # Include the updated visitor count in the response
        basics_section['visitor_count'] = new_count

        return func.HttpResponse(json.dumps(basics_section, indent=2), status_code=200)
    except exceptions.CosmosHttpResponseError as e:
        logging.error(f"Error reading item from Cosmos DB: {e.message}")
        return func.HttpResponse("Error reading item from Cosmos DB", status_code=500)