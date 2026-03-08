const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const id = event.pathParameters?.id;
  try {
    const data = await docClient.send(new GetCommand({ 
      TableName: process.env.TABLE_NAME, 
      Key: { id } 
    }));
    return {
      statusCode: data.Item ? 200 : 404,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify(data.Item || { error: "Course not found" }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};
