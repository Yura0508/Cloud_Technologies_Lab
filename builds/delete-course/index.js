const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, DeleteCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const id = event.pathParameters?.id;
  try {
    await docClient.send(new DeleteCommand({ 
      TableName: process.env.TABLE_NAME, 
      Key: { id } 
    }));
    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Course deleted successfully", id }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};
